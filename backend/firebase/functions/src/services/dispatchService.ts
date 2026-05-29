import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { logger } from "firebase-functions";
import { collections } from "../constants/collections";
import { OrderRecord, SystemSettings } from "../models/domain";
import { db } from "./firebase";
import { NotificationService } from "./notificationService";
import { SellerDiscoveryService } from "./sellerDiscoveryService";

const DEFAULT_SETTINGS: SystemSettings = {
  bookingsEnabled: true,
  maintenanceMode: false,
  dispatchRadiusKm: 10,
  offerTimeoutSeconds: 30,
  maxDispatchAttempts: 5,
};

function normalizeLocation(location: Record<string, unknown>): {
  lat: number;
  lng: number;
} {
  const lat = Number(location.latitude ?? location.lat);
  const lng = Number(location.longitude ?? location.lng);
  return { lat, lng };
}

export class DispatchService {
  constructor(
    private readonly sellerDiscovery = new SellerDiscoveryService(),
    private readonly notifications = new NotificationService()
  ) {}

  async getSettings(): Promise<SystemSettings> {
    const snapshot = await db.collection(collections.systemSettings).doc("app").get();
    const data = snapshot.data() ?? {};
    return {
      bookingsEnabled:
        typeof data.bookingsEnabled === "boolean"
          ? data.bookingsEnabled
          : DEFAULT_SETTINGS.bookingsEnabled,
      maintenanceMode:
        typeof data.maintenanceMode === "boolean"
          ? data.maintenanceMode
          : DEFAULT_SETTINGS.maintenanceMode,
      dispatchRadiusKm:
        Number(data.dispatchRadiusKm) || DEFAULT_SETTINGS.dispatchRadiusKm,
      offerTimeoutSeconds:
        Number(data.offerTimeoutSeconds) || DEFAULT_SETTINGS.offerTimeoutSeconds,
      maxDispatchAttempts:
        Number(data.maxDispatchAttempts) || DEFAULT_SETTINGS.maxDispatchAttempts,
    };
  }

  async startDispatch(orderId: string): Promise<void> {
    const orderRef = db.collection(collections.orders).doc(orderId);
    const orderSnapshot = await orderRef.get();
    if (!orderSnapshot.exists) return;
    const order = { id: orderSnapshot.id, ...orderSnapshot.data() } as OrderRecord;
    if (order.status !== "SEARCHING") return;
    await this.offerNextSeller(order);
  }

  async offerNextSeller(order: OrderRecord): Promise<void> {
    const settings = await this.getSettings();
    if (!settings.bookingsEnabled || settings.maintenanceMode) {
      await this.failOrder(order.id, "Bookings disabled or maintenance mode enabled.");
      return;
    }

    const location = normalizeLocation(order.location as unknown as Record<string, unknown>);
    if (!Number.isFinite(location.lat) || !Number.isFinite(location.lng)) {
      await this.failOrder(order.id, "Order location is invalid.");
      return;
    }

    const rejectedSellerIds = order.rejectedSellerIds ?? [];
    const candidates = await this.sellerDiscovery.findNearbyEligibleSellers({
      tankSize: Number(order.tankSize),
      lat: location.lat,
      lng: location.lng,
      radiusKm: settings.dispatchRadiusKm,
      excludedSellerIds: rejectedSellerIds,
      limit: settings.maxDispatchAttempts,
    });

    const candidate = candidates[0];
    if (!candidate) {
      await db.collection(collections.orders).doc(order.id).set(
        {
          status: "NO_PARTNER_FOUND",
          currentOfferId: null,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      await this.log(order.id, "NO_PARTNER_FOUND", {
        radiusKm: settings.dispatchRadiusKm,
      });
      await this.notifications.send({
        userIds: [order.customerId],
        title: "No tanker found",
        body: "No available tanker accepted this request. Please retry.",
        data: { orderId: order.id, status: "NO_PARTNER_FOUND" },
      });
      return;
    }

    const attemptNumber = (order.dispatchAttempt ?? 0) + 1;
    const offerRef = db.collection(collections.orderOffers).doc();
    const expiresAt = Timestamp.fromMillis(
      Date.now() + settings.offerTimeoutSeconds * 1000
    );

    await db.runTransaction(async (transaction) => {
      const freshOrder = await transaction.get(db.collection(collections.orders).doc(order.id));
      if (!freshOrder.exists || freshOrder.data()?.status !== "SEARCHING") return;

      transaction.set(offerRef, {
        id: offerRef.id,
        orderId: order.id,
        sellerId: candidate.sellerId,
        driverId: null,
        status: "pending",
        attemptNumber,
        distanceKm: candidate.distanceKm,
        expiresAt,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
      transaction.set(
        db.collection(collections.orders).doc(order.id),
        {
          status: "OFFER_SENT",
          currentOfferId: offerRef.id,
          candidateSellerIds: candidates.map((item) => item.sellerId),
          dispatchAttempt: attemptNumber,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    });

    await this.log(order.id, "OFFER_SENT", {
      offerId: offerRef.id,
      sellerId: candidate.sellerId,
      distanceKm: candidate.distanceKm,
      attemptNumber,
      expiresAt: expiresAt.toDate().toISOString(),
    });
    await this.notifications.send({
      userIds: [candidate.sellerId],
      title: "New water delivery request",
      body: `Nearest request ${candidate.distanceKm.toFixed(1)} km away. Accept within ${settings.offerTimeoutSeconds}s.`,
      data: {
        orderId: order.id,
        offerId: offerRef.id,
        type: "ORDER_OFFER",
      },
    });
  }

  async acceptOffer(params: {
    offerId: string;
    sellerId: string;
    driverId?: string | null;
  }): Promise<{ orderId: string; status: string }> {
    const offerRef = db.collection(collections.orderOffers).doc(params.offerId);

    const result = await db.runTransaction(async (transaction) => {
      const offerSnapshot = await transaction.get(offerRef);
      if (!offerSnapshot.exists) throw new Error("Offer not found.");
      const offer = offerSnapshot.data()!;
      if (offer.sellerId !== params.sellerId) {
        throw new Error("This offer is not assigned to this seller.");
      }
      if (offer.status !== "pending" && offer.status !== "accepted") {
        throw new Error("This offer is no longer pending.");
      }

      const orderRef = db.collection(collections.orders).doc(offer.orderId);
      const orderSnapshot = await transaction.get(orderRef);
      if (!orderSnapshot.exists) throw new Error("Order not found.");
      const order = orderSnapshot.data()!;
      if (order.status !== "OFFER_SENT" || order.currentOfferId !== params.offerId) {
        throw new Error("Order is no longer available.");
      }

      transaction.update(offerRef, {
        status: "accepted",
        driverId: params.driverId ?? params.sellerId,
        updatedAt: FieldValue.serverTimestamp(),
      });
      transaction.set(
        orderRef,
        {
          status: params.driverId ? "DRIVER_ASSIGNED" : "ACCEPTED",
          sellerId: params.sellerId,
          driverId: params.driverId ?? params.sellerId,
          assignedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      transaction.set(
        db.collection(collections.sellers).doc(params.sellerId),
        {
          isAvailable: false,
          activeOrderId: offer.orderId,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      return {
        orderId: offer.orderId as string,
        customerId: order.customerId as string,
        status: params.driverId ? "DRIVER_ASSIGNED" : "ACCEPTED",
      };
    });

    await this.log(result.orderId, "OFFER_ACCEPTED", {
      offerId: params.offerId,
      sellerId: params.sellerId,
      driverId: params.driverId ?? params.sellerId,
    });
    await this.notifications.send({
      userIds: [result.customerId],
      title: "Tanker assigned",
      body: "A nearby tanker accepted your water delivery request.",
      data: { orderId: result.orderId, status: result.status },
    });
    return { orderId: result.orderId, status: result.status };
  }

  async rejectOffer(params: { offerId: string; sellerId: string }): Promise<void> {
    const offerRef = db.collection(collections.orderOffers).doc(params.offerId);
    const offerSnapshot = await offerRef.get();
    if (!offerSnapshot.exists) return;
    const offer = offerSnapshot.data()!;
    if (
      offer.sellerId !== params.sellerId ||
      (offer.status !== "pending" && offer.status !== "rejected")
    ) {
      return;
    }

    await offerRef.set(
      {
        status: "rejected",
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
    await this.retryAfterOfferEnd(offer.orderId, params.sellerId, "OFFER_REJECTED");
  }

  async expireStaleOffers(): Promise<number> {
    const snapshot = await db
      .collection(collections.orderOffers)
      .where("status", "==", "pending")
      .where("expiresAt", "<=", Timestamp.now())
      .limit(50)
      .get();

    await Promise.all(
      snapshot.docs.map(async (doc) => {
        const offer = doc.data();
        await doc.ref.set(
          {
            status: "expired",
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
        await this.retryAfterOfferEnd(offer.orderId, offer.sellerId, "OFFER_EXPIRED");
      })
    );
    return snapshot.size;
  }

  private async retryAfterOfferEnd(
    orderId: string,
    sellerId: string,
    event: string
  ): Promise<void> {
    const orderRef = db.collection(collections.orders).doc(orderId);
    const snapshot = await orderRef.get();
    if (!snapshot.exists) return;
    const order = { id: snapshot.id, ...snapshot.data() } as OrderRecord;
    if (order.status !== "OFFER_SENT") return;

    await orderRef.set(
      {
        status: "SEARCHING",
        currentOfferId: null,
        rejectedSellerIds: FieldValue.arrayUnion(sellerId),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
    await this.log(orderId, event, { sellerId });
    const fresh = await orderRef.get();
    await this.offerNextSeller({ id: fresh.id, ...fresh.data() } as OrderRecord);
  }

  private async failOrder(orderId: string, reason: string): Promise<void> {
    await db.collection(collections.orders).doc(orderId).set(
      {
        status: "FAILED",
        failureReason: reason,
        currentOfferId: null,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
    await this.log(orderId, "FAILED", { reason });
  }

  private async log(
    orderId: string,
    event: string,
    data: Record<string, unknown>
  ): Promise<void> {
    logger.info("Dispatch event", { orderId, event, ...data });
    await db.collection(collections.dispatchLogs).add({
      orderId,
      event,
      data,
      createdAt: FieldValue.serverTimestamp(),
    });
  }
}
