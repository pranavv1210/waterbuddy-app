import { useEffect, useState } from "react";

import { UserRecord } from "../services/types";
import { setUserBlocked, subscribeUsers } from "../services/userService";

export function useUsers() {
  const [users, setUsers] = useState<UserRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setLoading(true);
    const unsubscribe = subscribeUsers(
      (nextUsers) => {
        setUsers(nextUsers);
        setLoading(false);
      },
      (nextError) => {
        setError(nextError.message);
        setLoading(false);
      },
    );

    return () => unsubscribe();
  }, []);

  const toggleUserBlocked = async (user: UserRecord) => {
    await setUserBlocked(user.id, !user.blocked);
  };

  return { users, loading, error, toggleUserBlocked };
}
