import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';

export interface RateLimitConfig {
  windowMs: number;
  maxRequests: number;
}

export class RateLimiterService {
  private static db = admin.firestore();

  /**
   * Checks if an action by a user exceeds the rate limits.
   * Throws an HTTPS error if rate limit is exceeded.
   */
  static async checkLimit(
    userId: string,
    action: 'refund' | 'otp' | 'booking' | 'wallet_topup' | 'review' | 'notification',
    config: RateLimitConfig
  ): Promise<void> {
    const docRef = this.db.collection('rate_limits').doc(`${userId}_${action}`);
    const now = Date.now();

    await this.db.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(docRef);
      
      if (!snapshot.exists) {
        // Initialize limit record
        transaction.set(docRef, {
          timestamps: [now],
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return;
      }

      const data = snapshot.data() as { timestamps: number[] };
      const previousTimestamps = data.timestamps || [];

      // Filter timestamps within the current sliding window
      const cutoff = now - config.windowMs;
      const activeTimestamps = previousTimestamps.filter((ts) => ts > cutoff);

      if (activeTimestamps.length >= config.maxRequests) {
        throw new HttpsError(
          'resource-exhausted',
          `Rate limit exceeded for action: ${action}. Please try again later.`
        );
      }

      activeTimestamps.push(now);

      transaction.update(docRef, {
        timestamps: activeTimestamps,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });
  }
}
