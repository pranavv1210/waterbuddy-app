const testing = require("@firebase/rules-unit-testing");
const fs = require("fs");
const path = require("path");

const PROJECT_ID = "waterbuddy-app-test";

describe("Firestore Security Rules", () => {
  let testEnv;

  before(async () => {
    testEnv = await testing.initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: {
        rules: fs.readFileSync(path.resolve(__dirname, "../firestore_rules/firestore.rules"), "utf8"),
        host: "127.0.0.1",
        port: 8080,
      },
    });
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
  });

  after(async () => {
    await testEnv.cleanup();
  });

  // Helper to get Firestore context
  function getContext(auth) {
    if (auth) {
      return testEnv.authenticatedContext(auth.uid, auth.token);
    }
    return testEnv.unauthenticatedContext();
  }

  describe("Scenario 1: Customer tries reading another customer's orders", () => {
    it("should reject reading another customer's order", async () => {
      // Seed an order for Customer B
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await db.collection("orders").doc("order_b").set({
          customerId: "customer_b",
          status: "SEARCHING",
          amount: 500,
        });
      });

      // Try reading as Customer A
      const customerAContext = getContext({
        uid: "customer_a",
        token: { role: "customer" },
      });
      const orderRef = customerAContext.firestore().collection("orders").doc("order_b");

      await testing.assertFails(orderRef.get());
    });

    it("should allow reading own order", async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await db.collection("orders").doc("order_a").set({
          customerId: "customer_a",
          status: "SEARCHING",
          amount: 500,
        });
      });

      const customerAContext = getContext({
        uid: "customer_a",
        token: { role: "customer" },
      });
      const orderRef = customerAContext.firestore().collection("orders").doc("order_a");

      await testing.assertSucceeds(orderRef.get());
    });
  });

  describe("Scenario 2: Customer modifies another customer's order", () => {
    it("should reject updates to another customer's order", async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await db.collection("orders").doc("order_b").set({
          customerId: "customer_b",
          status: "SEARCHING",
          amount: 500,
        });
      });

      const customerAContext = getContext({
        uid: "customer_a",
        token: { role: "customer" },
      });
      const orderRef = customerAContext.firestore().collection("orders").doc("order_b");

      await testing.assertFails(orderRef.update({ status: "CANCELLED" }));
    });
  });

  describe("Scenario 3: Driver modifies payment documents", () => {
    it("should reject driver writing to payment_events", async () => {
      const driverContext = getContext({
        uid: "driver_a",
        token: { role: "driver" },
      });
      const paymentRef = driverContext.firestore().collection("payment_events").doc("payment_1");

      await testing.assertFails(
        paymentRef.set({
          customerId: "customer_a",
          status: "SUCCESS",
        })
      );
    });

    it("should reject driver writing to wallets", async () => {
      const driverContext = getContext({
        uid: "driver_a",
        token: { role: "driver" },
      });
      const walletRef = driverContext.firestore().collection("wallets").doc("driver_wallet");

      await testing.assertFails(
        walletRef.set({
          balance: 100000,
        })
      );
    });

    it("should reject driver writing to wallet_transactions", async () => {
      const driverContext = getContext({
        uid: "driver_a",
        token: { role: "driver" },
      });
      const txRef = driverContext.firestore().collection("wallet_transactions").doc("tx_1");

      await testing.assertFails(
        txRef.set({
          amount: 5000,
          userId: "driver_a",
        })
      );
    });
  });

  describe("Scenario 4: Seller escalates privileges", () => {
    it("should reject seller updating their own verificationStatus", async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await db.collection("sellers").doc("seller_a").set({
          uid: "seller_a",
          verificationStatus: "pending",
          isOnline: false,
        });
      });

      const sellerContext = getContext({
        uid: "seller_a",
        token: { role: "seller" },
      });
      const sellerRef = sellerContext.firestore().collection("sellers").doc("seller_a");

      await testing.assertFails(
        sellerRef.update({
          verificationStatus: "approved",
        })
      );
    });

    it("should allow seller updating online status without changing verificationStatus", async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await db.collection("sellers").doc("seller_a").set({
          uid: "seller_a",
          verificationStatus: "pending",
          isOnline: false,
        });
      });

      const sellerContext = getContext({
        uid: "seller_a",
        token: { role: "seller" },
      });
      const sellerRef = sellerContext.firestore().collection("sellers").doc("seller_a");

      await testing.assertSucceeds(
        sellerRef.update({
          isOnline: true,
        })
      );
    });
  });

  describe("Scenario 5: Anonymous writes", () => {
    it("should reject unauthenticated writes to orders", async () => {
      const anonContext = getContext(null);
      const orderRef = anonContext.firestore().collection("orders").doc("order_1");

      await testing.assertFails(
        orderRef.set({
          customerId: "anon",
          status: "SEARCHING",
        })
      );
    });

    it("should reject unauthenticated reads to system settings", async () => {
      const anonContext = getContext(null);
      const settingsRef = anonContext.firestore().collection("system_settings").doc("app");

      await testing.assertFails(settingsRef.get());
    });
  });

  describe("Scenario 6: Admin spoof attempts", () => {
    it("should reject driver writing to admins collection", async () => {
      const driverContext = getContext({
        uid: "driver_a",
        token: { role: "driver" },
      });
      const adminRef = driverContext.firestore().collection("admins").doc("driver_a");

      await testing.assertFails(
        adminRef.set({
          role: "admin",
        })
      );
    });

    it("should reject customer reading dispatch logs", async () => {
      const customerContext = getContext({
        uid: "customer_a",
        token: { role: "customer" },
      });
      const logsRef = customerContext.firestore().collection("dispatch_logs").doc("log_1");

      await testing.assertFails(logsRef.get());
    });

    it("should reject seller reading system metrics", async () => {
      const sellerContext = getContext({
        uid: "seller_a",
        token: { role: "seller" },
      });
      const metricsRef = sellerContext.firestore().collection("system_metrics").doc("today");

      await testing.assertFails(metricsRef.get());
    });

    it("should allow admin reading everything", async () => {
      const adminContext = getContext({
        uid: "admin_1",
        token: { role: "admin" },
      });
      const logsRef = adminContext.firestore().collection("dispatch_logs").doc("log_1");

      // Succeeds even if the document does not exist, because the security rules check passes
      await testing.assertSucceeds(logsRef.get());
    });
  });
});
