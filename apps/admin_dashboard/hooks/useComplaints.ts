import { useEffect, useState } from "react";

import { setComplaintStatus, subscribeComplaints } from "../services/complaintService";
import { ComplaintRecord } from "../services/types";

export function useComplaints() {
  const [complaints, setComplaints] = useState<ComplaintRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setLoading(true);
    const unsubscribe = subscribeComplaints(
      (nextComplaints) => {
        setComplaints(nextComplaints);
        setLoading(false);
      },
      (nextError) => {
        setError(nextError.message);
        setLoading(false);
      },
    );

    return () => unsubscribe();
  }, []);

  const updateComplaintStatus = async (complaint: ComplaintRecord) => {
    const current = complaint.status.toLowerCase();
    const nextStatus =
      current === "open" ? "in_progress" : current === "in progress" ? "resolved" : "resolved";
    await setComplaintStatus(complaint.id, nextStatus);
  };

  return { complaints, loading, error, updateComplaintStatus };
}
