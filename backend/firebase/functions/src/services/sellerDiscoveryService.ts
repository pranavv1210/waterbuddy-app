import { SellerProfile } from "../models/domain";

export class SellerDiscoveryService {
  async findNearbyEligibleSellerIds(params: {
    tankSize: number;
    lat: number;
    lng: number;
    limit: number;
  }): Promise<string[]> {
    const { limit } = params;
    return Array.from({ length: limit }, (_, index) => `candidate-${index + 1}`);
  }

  filterApprovedOnlineSellers(sellers: SellerProfile[]): SellerProfile[] {
    return sellers.filter((seller) => seller.kycStatus == "approved" && seller.isOnline);
  }
}
