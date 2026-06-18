// Load and stress test simulation for WaterBuddy Firebase Emulators
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";

const admin = require("firebase-admin");
// Initialize admin with testing project ID
admin.initializeApp({
  projectId: "waterbuddy-app-test",
});

const db = admin.firestore();

// Collections mapping
const collections = {
  users: "users",
  sellers: "sellers",
  drivers: "drivers",
  orders: "orders",
  orderOffers: "order_offers",
  systemSettings: "system_settings",
  wallets: "wallets",
  walletTransactions: "wallet_transactions",
  driverPayouts: "driver_payouts",
  sellerPayouts: "seller_payouts",
  refunds: "refunds",
  routeAnalytics: "route_analytics",
};

// Seed Config
async function seedConfig() {
  await db.collection(collections.systemSettings).doc("config").set({
    bookingsEnabled: true,
    maintenanceMode: false,
    dispatchRadiusKm: 10,
    offerTimeoutSeconds: 30,
    maxDispatchAttempts: 5,
    cancellationCharge: 75.0,
  });
}

// Seed Actors
async function seedActors(numCustomers, numSellers, numDrivers) {
  console.log(`[SEED] Seeding ${numCustomers} customers, ${numSellers} sellers, ${numDrivers} drivers...`);
  
  const batch = db.batch();
  
  // Seed customers
  for (let i = 0; i < numCustomers; i++) {
    const ref = db.collection(collections.users).doc(`customer_${i}`);
    batch.set(ref, {
      uid: `customer_${i}`,
      fullName: `Customer ${i}`,
      role: "customer",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  // Seed sellers
  for (let i = 0; i < numSellers; i++) {
    const ref = db.collection(collections.sellers).doc(`seller_${i}`);
    batch.set(ref, {
      uid: `seller_${i}`,
      fullName: `Seller ${i}`,
      role: "seller",
      isOnline: true,
      isAvailable: true,
      verificationStatus: "approved",
      currentLocation: {
        latitude: 12.9716 + (Math.random() - 0.5) * 0.05,
        longitude: 77.5946 + (Math.random() - 0.5) * 0.05,
      },
      tankSizes: [500, 1000],
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  // Seed drivers
  for (let i = 0; i < numDrivers; i++) {
    const ref = db.collection(collections.drivers).doc(`driver_${i}`);
    batch.set(ref, {
      uid: `driver_${i}`,
      fullName: `Driver ${i}`,
      role: "driver",
      isOnline: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  await batch.commit();
  console.log(`[SEED] Successfully seeded all actors.`);
}

// Simulate Concurrent Acceptances (Race Conditions)
async function runAcceptanceRace(numRaces) {
  console.log(`[RACE] Running ${numRaces} concurrent acceptance races...`);
  let successes = 0;
  let failures = 0;
  let doubleAssignments = 0;

  for (let r = 0; r < numRaces; r++) {
    const orderId = `race_order_${r}`;
    const offerIdA = `offer_${orderId}_seller_A`;
    const offerIdB = `offer_${orderId}_seller_B`;

    // 1. Create order and offers
    await db.collection(collections.orders).doc(orderId).set({
      id: orderId,
      customerId: "customer_0",
      status: "OFFER_SENT",
      currentOfferId: offerIdA, // Pointing to offer A initially
      amount: 500,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await db.collection(collections.orderOffers).doc(offerIdA).set({
      id: offerIdA,
      orderId: orderId,
      sellerId: "seller_A",
      status: "pending",
    });

    await db.collection(collections.orderOffers).doc(offerIdB).set({
      id: offerIdB,
      orderId: orderId,
      sellerId: "seller_B",
      status: "pending",
    });

    // 2. Concurrently attempt to accept both
    const acceptOfferTx = async (offerId, sellerId) => {
      return db.runTransaction(async (transaction) => {
        const offerRef = db.collection(collections.orderOffers).doc(offerId);
        const offerSnap = await transaction.get(offerRef);
        const offer = offerSnap.data();

        if (!offer || offer.status !== "pending") {
          throw new Error("Offer not pending");
        }

        const orderRef = db.collection(collections.orders).doc(offer.orderId);
        const orderSnap = await transaction.get(orderRef);
        const order = orderSnap.data();

        if (!order || order.status !== "OFFER_SENT" || order.sellerId) {
          throw new Error("Order not available or already accepted");
        }

        // Apply accept logic
        transaction.update(offerRef, { status: "accepted" });
        transaction.update(orderRef, {
          status: "ACCEPTED",
          sellerId: sellerId,
          assignedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });
    };

    // Execute races concurrently
    const p1 = acceptOfferTx(offerIdA, "seller_A").then(() => "A").catch((err) => err.message);
    const p2 = acceptOfferTx(offerIdB, "seller_B").then(() => "B").catch((err) => err.message);

    const [res1, res2] = await Promise.all([p1, p2]);

    if (res1 === "A" && res2 === "B") {
      doubleAssignments++;
    } else if (res1 === "A" || res2 === "B") {
      successes++;
    } else {
      failures++;
    }
  }

  console.log(`[RACE] Successes: ${successes}, Failures: ${failures}, Double Assignments: ${doubleAssignments}`);
  return { successes, failures, doubleAssignments };
}

// Full Load Test Runner
async function runLoadTest() {
  const startTime = Date.now();
  await seedConfig();

  // Phase A: 100 customers, 50 sellers, 20 drivers
  console.log("\n--- PHASE 1: 100 Customers / 50 Sellers / 20 Drivers ---");
  await seedActors(100, 50, 20);
  const race1 = await runAcceptanceRace(20);

  // Phase B: 500 customers, 100 sellers, 50 drivers
  console.log("\n--- PHASE 2: 500 Customers / 100 Sellers / 50 Drivers ---");
  await seedActors(500, 100, 50);
  const race2 = await runAcceptanceRace(50);

  // Phase C: 1000 customers, 200 sellers, 100 drivers
  console.log("\n--- PHASE 3: 1000 Customers / 200 Sellers / 100 Drivers ---");
  await seedActors(1000, 200, 100);
  const race3 = await runAcceptanceRace(100);

  const duration = Date.now() - startTime;
  console.log(`\n[COMPLETE] Load testing completed in ${(duration / 1000).toFixed(2)} seconds.`);

  return {
    race1,
    race2,
    race3,
    durationMs: duration,
  };
}

runLoadTest().then((results) => {
  // Write stats reports
  console.log("Load test results:", JSON.stringify(results, null, 2));
  process.exit(0);
}).catch((err) => {
  console.error("Load test failed", err);
  process.exit(1);
});
