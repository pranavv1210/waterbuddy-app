import { logger } from "firebase-functions";

interface NotificationPayload {
  userIds: string[];
  title: string;
  body: string;
  data?: Record<string, string>;
}

export class NotificationService {
  async send(payload: NotificationPayload): Promise<void> {
    logger.info("Mock notification dispatch", payload);
  }
}
