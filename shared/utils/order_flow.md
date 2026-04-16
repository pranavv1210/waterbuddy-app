# Order Flow

1. Customer places order.
2. Function resolves nearby eligible sellers.
3. System broadcasts the request to 3 to 5 sellers.
4. First acceptance wins through a Firestore transaction.
5. Remaining candidate requests are marked rejected.
6. Customer and seller receive status updates in real time.

## Phase 1 Notes

- Nearby seller matching is abstracted behind a selection service.
- Notification delivery is abstracted behind an FCM service.
- Payments are mocked behind an interface and only begin after seller acceptance.
