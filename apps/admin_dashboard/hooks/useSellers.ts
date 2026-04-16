import { useEffect, useState } from "react";

import { setSellerEnabled, setSellerKycStatus, subscribeSellers } from "../services/sellerService";
import { SellerRecord } from "../services/types";

export function useSellers() {
  const [sellers, setSellers] = useState<SellerRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setLoading(true);
    const unsubscribe = subscribeSellers(
      (nextSellers) => {
        setSellers(nextSellers);
        setLoading(false);
      },
      (nextError) => {
        setError(nextError.message);
        setLoading(false);
      },
    );

    return () => unsubscribe();
  }, []);

  const toggleSellerEnabled = async (seller: SellerRecord) => {
    await setSellerEnabled(seller.id, !seller.enabled);
  };

  const approveSellerKyc = async (seller: SellerRecord) => {
    await setSellerKycStatus(seller.id, "approved");
  };

  const rejectSellerKyc = async (seller: SellerRecord) => {
    await setSellerKycStatus(seller.id, "rejected");
  };

  return { sellers, loading, error, toggleSellerEnabled, approveSellerKyc, rejectSellerKyc };
}
