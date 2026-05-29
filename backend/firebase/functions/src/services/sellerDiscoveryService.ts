import { collections } from "../constants/collections";
import { db } from "./firebase";

interface SellerCandidate {
  sellerId: string;
  distanceKm: number;
}

function toRadians(value: number): number {
  return (value * Math.PI) / 180;
}

function distanceKm(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number
): number {
  const earthRadiusKm = 6371;
  const dLat = toRadians(lat2 - lat1);
  const dLng = toRadians(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRadians(lat1)) *
      Math.cos(toRadians(lat2)) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);
  return 2 * earthRadiusKm * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

export class SellerDiscoveryService {
  async findNearbyEligibleSellers(params: {
    tankSize: number;
    lat: number;
    lng: number;
    radiusKm: number;
    excludedSellerIds: string[];
    limit: number;
  }): Promise<SellerCandidate[]> {
    const sellerSnapshot = await db
      .collection(collections.sellers)
      .where("isOnline", "==", true)
      .where("isAvailable", "==", true)
      .where("verificationStatus", "in", ["approved", "active"])
      .get();

    const excluded = new Set(params.excludedSellerIds);
    const candidates = sellerSnapshot.docs
      .map((doc) => {
        if (excluded.has(doc.id)) return null;
        const data = doc.data();
        const location = data.currentLocation ?? {};
        const lat = Number(location.latitude);
        const lng = Number(location.longitude);
        if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;

        const capacities = Array.isArray(data.tankSizes)
          ? data.tankSizes.map(Number)
          : Array.isArray(data.tankerVehicles)
            ? data.tankerVehicles.map((vehicle) => Number(vehicle.capacity))
            : [];
        const hasCapacity =
          capacities.length === 0 ||
          capacities.some((capacity) => capacity >= params.tankSize);
        if (!hasCapacity) return null;

        const km = distanceKm(params.lat, params.lng, lat, lng);
        if (km > params.radiusKm) return null;
        return { sellerId: doc.id, distanceKm: Number(km.toFixed(3)) };
      })
      .filter((candidate): candidate is SellerCandidate => candidate !== null)
      .sort((a, b) => a.distanceKm - b.distanceKm)
      .slice(0, params.limit);

    return candidates;
  }
}
