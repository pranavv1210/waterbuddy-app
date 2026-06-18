import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { collections } from "../constants/collections";
import { db } from "./firebase";
import { AnalyticsService } from "./analyticsService";

function toRadians(value: number): number {
  return (value * Math.PI) / 180;
}

export function distanceKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const earthRadiusKm = 6371;
  const dLat = toRadians(lat2 - lat1);
  const dLng = toRadians(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRadians(lat1)) * Math.cos(toRadians(lat2)) * Math.sin(dLng / 2) ** 2;
  return 2 * earthRadiusKm * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

export class RouteIntelligenceService {
  constructor(private readonly analytics = new AnalyticsService()) {}

  estimateEtaMinutes(distanceKmValue: number, averageSpeedKmph = 28, trafficFactor = 1.2): number {
    if (!Number.isFinite(distanceKmValue) || distanceKmValue <= 0) return 0;
    const speed = Math.max(5, averageSpeedKmph);
    return Math.ceil((distanceKmValue / speed) * 60 * trafficFactor);
  }

  async updateTracking(params: {
    orderId: string;
    lat: number;
    lng: number;
  }): Promise<void> {
    const trackingRef = db.collection(collections.tracking).doc(params.orderId);
    const orderRef = db.collection(collections.orders).doc(params.orderId);

    await db.runTransaction(async (tx) => {
      const [trackingSnap, orderSnap] = await Promise.all([
        tx.get(trackingRef),
        tx.get(orderRef),
      ]);
      const previous = trackingSnap.data() ?? {};
      const lastLat = Number(previous.lat);
      const lastLng = Number(previous.lng);
      const previousDistance = Number(previous.distanceTravelledKm ?? 0);
      const travelledIncrement =
        Number.isFinite(lastLat) && Number.isFinite(lastLng)
          ? distanceKm(lastLat, lastLng, params.lat, params.lng)
          : 0;
      const order = orderSnap.data() ?? {};
      const destination = order.location ?? {};
      const destinationLat = Number(destination.latitude ?? destination.lat);
      const destinationLng = Number(destination.longitude ?? destination.lng);
      const remainingKm =
        Number.isFinite(destinationLat) && Number.isFinite(destinationLng)
          ? distanceKm(params.lat, params.lng, destinationLat, destinationLng)
          : 0;
      const etaMinutes = this.estimateEtaMinutes(remainingKm);
      const now = Timestamp.now();
      const estimatedArrival = Timestamp.fromMillis(now.toMillis() + etaMinutes * 60000);

      tx.set(
        trackingRef,
        {
          orderId: params.orderId,
          lat: params.lat,
          lng: params.lng,
          distanceTravelledKm: previousDistance + travelledIncrement,
          remainingDistanceKm: remainingKm,
          estimatedArrival,
          estimatedCompletion: estimatedArrival,
          timestamp: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      tx.set(
        orderRef,
        {
          estimatedArrival,
          estimatedCompletion: estimatedArrival,
          routeAnalytics: {
            distanceTravelledKm: previousDistance + travelledIncrement,
            remainingDistanceKm: remainingKm,
            etaMinutes,
            updatedAt: FieldValue.serverTimestamp(),
          },
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    });

    const orderSnap = await db.collection(collections.orders).doc(params.orderId).get();
    const eta = Number(orderSnap.data()?.routeAnalytics?.etaMinutes ?? 0);
    if (eta > 0) await this.analytics.recordEta(eta);
  }

  async finalizeRoute(orderId: string): Promise<void> {
    const orderSnap = await db.collection(collections.orders).doc(orderId).get();
    if (!orderSnap.exists) return;
    const order = orderSnap.data()!;
    const createdAt = order.createdAt?.toDate?.() as Date | undefined;
    const assignedAt = order.assignedAt?.toDate?.() as Date | undefined;
    const startedAt = order.startedAt?.toDate?.() as Date | undefined;
    const deliveredAt = order.deliveredAt?.toDate?.() as Date | undefined;
    const end = deliveredAt ?? new Date();
    const tracking = (await db.collection(collections.tracking).doc(orderId).get()).data() ?? {};

    await db.collection("route_analytics").doc(orderId).set(
      {
        orderId,
        sellerId: order.sellerId ?? null,
        driverId: order.driverId ?? null,
        distanceTravelledKm: Number(tracking.distanceTravelledKm ?? 0),
        routeDurationMinutes: startedAt ? minutesBetween(startedAt, end) : 0,
        idleTimeMinutes: assignedAt && startedAt ? minutesBetween(assignedAt, startedAt) : 0,
        waitingTimeMinutes: createdAt && assignedAt ? minutesBetween(createdAt, assignedAt) : 0,
        deliveryDurationMinutes: createdAt ? minutesBetween(createdAt, end) : 0,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  }
}

function minutesBetween(a: Date, b: Date): number {
  return Math.max(0, Math.round((b.getTime() - a.getTime()) / 60000));
}
