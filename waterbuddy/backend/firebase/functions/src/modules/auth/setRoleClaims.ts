import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { adminAuth } from "../../services/firebase";
import { collections } from "../../constants/collections";
import { WaterBuddyUser } from "../../models/domain";

export const setRoleClaims = onDocumentCreated(
  `${collections.users}/{userId}`,
  async (event) => {
    const user = event.data?.data() as WaterBuddyUser | undefined;

    if (!user) {
      return;
    }

    await adminAuth.setCustomUserClaims(event.params.userId, { role: user.role });
  }
);
