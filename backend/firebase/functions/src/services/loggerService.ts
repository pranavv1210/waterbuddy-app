import { logger } from "firebase-functions";

export type LogTag =
  | "AUTH"
  | "ORDER"
  | "PAYMENT"
  | "WALLET"
  | "PAYOUT"
  | "REFUND"
  | "SELLER"
  | "DRIVER"
  | "LOCATION"
  | "FCM"
  | "ANALYTICS"
  | "FUNCTION";

export class LoggerService {
  private static format(tag: LogTag, message: string, ids?: Record<string, string | number | null>): string {
    const idsPart = ids
      ? " | " + Object.entries(ids)
          .filter(([_, v]) => v !== null && v !== undefined)
          .map(([k, v]) => `${k}=${v}`)
          .join(" ")
      : "";
    return `[${tag}] ${message}${idsPart}`;
  }

  static info(tag: LogTag, message: string, ids?: Record<string, string | number | null>, metadata?: Record<string, unknown>): void {
    logger.info(this.format(tag, message, ids), metadata);
  }

  static warn(tag: LogTag, message: string, ids?: Record<string, string | number | null>, metadata?: Record<string, unknown>): void {
    logger.warn(this.format(tag, message, ids), metadata);
  }

  static error(tag: LogTag, message: string, ids?: Record<string, string | number | null>, error?: unknown, metadata?: Record<string, unknown>): void {
    logger.error(this.format(tag, message, ids), { error, ...metadata });
  }
}
