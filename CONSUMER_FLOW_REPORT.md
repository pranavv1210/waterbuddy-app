# WaterBuddy Consumer Flow Report

This report outlines the end-to-end booking journey for consumers on the WaterBuddy platform.

## 1. Landing & Location Autocomplete
- **Dashboard:** The home screen presents a large map preview and dynamic nearby available tanker options.
- **Search Address:** Tapping "Where do you need water?" opens the location selection panel.
- **Google Places Suggestions:** Typing in the address input queries the Google Places Autocomplete API to fetch live, accurate location recommendations. Selecting a recommendation shifts the map camera, centers the marker on the address, and resolves latitude and longitude coordinates.

## 2. Booking Sheet & Pricing
- **Category Selection:** Once the location is confirmed, a bottom sheet slides up displaying available tanker categories (e.g. `10,000L`, `15,000L`, etc.) with real-time pricing retrieved from Firestore.
- **Dynamic Settings Toggle:** If bookings are disabled in the Admin settings, or if no tanker categories are available, a warning card is shown, blocking the checkout action.
- **CTA:** Tapping the primary "Book Water Now" button generates a Firestore order document.

## 3. Animated Searching Screen
- **Full Screen Radar:** A fullscreen animated searching screen is launched, featuring a background Google Map centered on the user location, an overlay of blue pulsing radar circles, and moving tanker icons.
- **Live Matchmaking Status:** A status bar displays cycling text updates ("Finding nearby tankers...", "Contacting nearest tanker...") and matching status.
- **Cancellation:** A visible "Cancel Request" button allows cancelling the request during the search phase.

## 4. Live Tracking & Delivery Pin
- **Driver Assignment:** When a driver accepts the order, the screen updates automatically to show:
  - Estimated arrival time (ETA).
  - Driver details (photo, name, plate number `KA01AB1234`).
  - Interactive "Call Driver" and "Message" actions.
- **Live Map Route:** The map plots a blue route between the driver and consumer, with the driver's vehicle marker updating in real-time.
- **Delivery Pin:** A 4-digit security PIN is displayed on the consumer's screen. The driver must input this PIN upon arrival to start the delivery, guaranteeing successful completion.
