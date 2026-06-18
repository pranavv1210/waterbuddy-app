# WaterBuddy Backup & Disaster Recovery Report

This report documents the automated backup policies, storage configurations, and disaster recovery procedures for the WaterBuddy Firebase infrastructure.

---

## 1. Backup Strategies

We configure multi-tiered backup schedules using Google Cloud Platform (GCP) and Firebase:

### A. Firestore Automated Exports
- **Action:** Daily export of the entire Firestore database collection set.
- **Trigger:** Cloud Scheduler trigger invoking a Google Cloud Function.
- **Target Storage:** Cold-tier Google Cloud Storage bucket (`gs://waterbuddy-backups/firestore/`).
- **Retention Policy:** 30 days of daily backups, after which files are auto-deleted via GCS Lifecycle Management.

### B. Cloud Storage Backups
- **Action:** Periodic replication of media assets, user documents, and licensing certificates.
- **Target Storage:** Dual-region backup bucket (`gs://waterbuddy-backups-dr/`).
- **Frequency:** Weekly automated synchronization task.

---

## 2. Disaster Recovery (DR) Procedures

In the event of database corruption, deletion, or regional outage:

### A. Restoring Firestore from Export
1. Identify the target backup timestamp folder in GCS.
2. Authenticate using `gcloud` CLI:
   ```bash
   gcloud config set project waterbuddy-edcf7
   ```
3. Execute the restoration command:
   ```bash
   gcloud firestore import gs://waterbuddy-backups/firestore/YYYY-MM-DD-timestamp/
   ```
4. Verify indexing finishes (restoration blocks writes until indexing completes).

### B. Recovery Time Objectives (RTO) and Recovery Point Objectives (RPO)
- **RPO (Max Data Loss Window):** 24 hours (governed by daily cron exports).
- **RTO (Max System Downtime):** < 30 minutes (governed by GCS import speeds).
