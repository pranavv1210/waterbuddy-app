# WaterBuddy Production Release Checklist

This checklist outlines the deployment validations and steps required before releasing the WaterBuddy Superapp to production.

---

## 1. Firebase Backend Infrastructure
- [ ] Deploy Security Rules to Production:
  ```bash
  firebase deploy --only firestore:rules
  ```
- [ ] Deploy Indexes Configuration:
  ```bash
  firebase deploy --only firestore:indexes
  ```
- [ ] Deploy Firebase Cloud Functions:
  ```bash
  firebase deploy --only functions
  ```
- [ ] Deploy Scheduled Cron Scheduler Tasks:
  ```bash
  firebase deploy --only scheduler
  ```

---

## 2. Telemetry & Monitoring
- [ ] Enable Firebase Crashlytics on the Google Firebase Dashboard.
- [ ] Enable Firebase Performance Monitoring.
- [ ] Set up custom alert triggers in Slack/Email for Function crashes.

---

## 3. Payments and Push Alerts
- [ ] Set Razorpay Key to Live mode in `.env.production`.
- [ ] Set Razorpay webhook endpoint pointing to backend production server.
- [ ] Verify APNs (Apple Push Notification service) and FCM configuration certificates are up to date.

---

## 4. Play Store Listing
- [ ] Upload compiled App Bundle (AAB):
  - Path: `apps/waterbuddy_superapp/build/app/outputs/bundle/release/app-release.aab`
- [ ] Fill Store Listing copy deck matching [PLAYSTORE_ASSETS_REPORT.md](file:///c:/Users/Pranav/Desktop/waterbuddy-app/PLAYSTORE_ASSETS_REPORT.md).
- [ ] Upload feature graphics and screenshots.
