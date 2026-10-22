# Nosh Bistro

Nosh Bistro is a Flutter restaurant discovery and ordering app with separate
customer and restaurant-admin experiences. Its warm, dark interface follows the
Nosh Bistro visual direction in Google Stitch, with espresso-colored surfaces,
flame-orange accents, rounded cards, and food photography.

## What the app includes

### Customer experience

- Animated branded splash screen followed by Firebase authentication.
- Email/password sign-in and customer account creation.
- Home feed with restaurant feature, cuisine categories, popular dishes, prices,
  ratings, and add-to-cart actions.
- Search and category filtering for the sample dish catalog.
- Restaurant details and a full categorized menu.
- Dish details with quantity selection and add-to-cart.
- Cart quantity controls, item removal, and a bill summary.
- Checkout form for delivery address and phone, with card/cash payment-method
  selection.
- Firestore order creation and order-status tracking.
- Order list, order history, and customer profile screens.

### Restaurant experience

- Dashboard with recent orders and order totals from Firestore.
- Order actions to advance tickets through `Pending`, `Preparing`,
  `Ready for pickup`, and `Delivered`.
- Menu screen with category filtering, search, availability switches, and an
  add-dish form.
- Analytics screen with a seven-day revenue chart and top dishes calculated
  from recent Firestore order documents.

### Important feature boundaries

- The catalog in `lib/models/menu_item.dart` is sample data. Menu additions and
  availability changes in `lib/state/menu_catalog.dart` are held in memory and
  reset when the app process restarts; they are not written to Firestore.
- Checkout's card and cash choices are presentation only. The app does not
  process payments, tokenize cards, or confirm payment with a payment provider.
- Delivery addresses and phone numbers are saved with each order. The current
  profile's saved-address, favorites, help, and notification rows are visual
  entry points and do not yet manage persistent settings.
- Restaurant profile, delivery courier assignment, customer messaging, refunds,
  and push notifications are not implemented.
- Dish and restaurant photos use remote Unsplash URLs and require network access.
- Admin metrics and analytics are derived from a capped query of the 500 most
  recent orders; they are not a complete accounting or reporting system.

## Technology and project structure

- **Flutter / Dart** provides the cross-platform UI.
- **Firebase Authentication** handles email/password and Google sessions.
- **Cloud Firestore** stores user profiles and customer orders.
- **Material 3** is themed centrally in `lib/theme/nosh_theme.dart`.
- `lib/models/menu_item.dart` contains the sample menu model and catalog.
- `lib/state/order_cart.dart` manages cart contents and computes the subtotal,
  delivery fee, tax, and total.
- `lib/state/menu_catalog.dart` manages the in-memory menu state.
- `lib/screens/auth/` contains sign-in and sign-up.
- `lib/screens/user/` contains customer navigation, discovery, menu, cart,
  checkout, tracking, history, and profile.
- `lib/screens/admin/` contains the dashboard, order management, menu
  management, and analytics.
- `lib/screens/splash/` contains the animated splash experience.

## Requirements

- Flutter SDK with Dart `^3.11.1` or compatible.
- A Firebase project with Email/Password Authentication and Cloud Firestore
  enabled.
- Google as an enabled Firebase Authentication provider for Google sign-in.
- A Firebase Android app whose registered package ID matches the app's Android
  `applicationId`.
- Firebase platform configuration for each platform you intend to run.

## Firebase setup

Firebase is initialized in `lib/main.dart` using the generated
`lib/firebase_options.dart`. Run `flutterfire configure` after adding or
changing Firebase apps/platforms. If Firebase cannot initialize, the app opens
a setup screen with the configuration command instead of remaining blank.

### Enable and configure sign-in

1. In Firebase Console, enable **Email/Password** and **Google** under
   **Authentication → Sign-in method**. Add the deployed web origins to
   **Authentication → Settings → Authorized domains**.
2. For Android, register the app's exact `applicationId` in Firebase, add the
   signing certificate SHA-1 and SHA-256 fingerprints (debug and release) to
   that Firebase Android app, then download the refreshed
   `google-services.json` to `android/app/google-services.json`. Google sign-in
   requires the generated OAuth client configuration; the Android Firebase
   configuration currently in this checkout has no OAuth clients, so Android
   Google sign-in will not work until it is regenerated after Google is
   enabled and the signing fingerprints are registered.
3. For iOS and macOS, register each bundle ID in Firebase and add the
   platform's `GoogleService-Info.plist` and required reversed-client-ID URL
   scheme as described by the Google Sign-In plugin's platform setup guide.
   Re-run `flutterfire configure` for Firebase app options.
4. For web, configure the Firebase web app and its authorized domain. The app
   uses Firebase Auth's Google popup on web; Android/iOS/macOS use the native
   Google Sign-In flow.
5. Restart the app and test both a new customer account and an existing
   account. Authentication providers must also be enabled in any Firebase
   emulator/project used for testing.

Google sign-in is available from both the sign-in and sign-up screens. Google
accounts without a `users/{uid}` profile are given a customer profile on first
sign-in. Existing profile roles are retained, so an authorized admin who signs
in with Google is routed to the admin dashboard. Email/password accounts use
the same role lookup. The **Forgot Password?** action sends a Firebase reset
email.

### Authentication and roles

- Successful email or Google customer sign-up creates a Firebase
  Authentication account and a `users/{uid}` Firestore document with the
  user's email, customer role, and creation timestamp.
- Public sign-up intentionally does not offer admin account creation.
- At sign-in, the app reads `users/{uid}.role`; `admin` opens the restaurant
  dashboard and other values open the customer app. Missing profile documents
  are initialized as customer profiles. Firestore errors are shown rather than
  silently granting customer access.
- Grant admin access only through a trusted administrative process. A role
  stored in a client-readable profile is not, by itself, a secure authorization
  boundary. Enforce staff access in Firestore Security Rules or a trusted
  backend. Never let public sign-up set the admin role.

Firestore Security Rules must allow a signed-in user to read and create their
own `users/{uid}` profile while preventing users from changing their role.
Configure and test rules before using real accounts; there is no rules file in
this repository.

### Firestore order data

The app uses the `orders` collection. A checkout creates an order document with
the following fields:

| Field | Description |
| --- | --- |
| `userId` | Firebase Authentication UID of the customer |
| `restaurantName` | Restaurant name shown in the order |
| `status` | Order state, initially `Preparing` |
| `createdAt` | Firestore server timestamp |
| `updatedAt` | Written when an admin advances an order |
| `address`, `phone` | Delivery details supplied at checkout |
| `paymentMethod` | Selected payment-method label; no payment is processed |
| `items` | Snapshot list of item `id`, `name`, `price`, and `quantity` |
| `subtotal` | Sum of item prices multiplied by quantities |
| `deliveryFee` | $3.50 below a $35 subtotal; otherwise free |
| `tax` | 8% of the subtotal |
| `total` | Subtotal plus delivery fee and tax |

Customer order queries filter by `userId` and sort by `createdAt`. Admin order
views sort by `createdAt` and display recent order documents. These queries may
require Firestore indexes; follow the index link in a Firebase error if one is
reported.

Before handling real customer data, configure and test Firestore rules so that:

- Customers can create orders only for their own UID and read only their own
  orders.
- Only trusted restaurant staff can read all customer orders or update their
  status.
- Users cannot assign themselves the admin role or alter protected order totals
  and ownership fields.

Do not deploy permissive test rules to production. There is no Firestore rules
file or index definition included in this repository.

## Run locally

From the project root in PowerShell:

```powershell
flutter pub get
flutter run
```

Run on web with:

```powershell
flutter run -d chrome
```

Firebase must be configured for the selected platform. Complete the provider
and OAuth setup above before expecting Google sign-in to work.

## Verify changes

```powershell
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

The test suite covers cart totals/removal, adding a dish from the menu, Firebase
startup configuration messaging, and the email/Google options on both auth
screens.

## Build status and production checklist

- `flutter analyze`, `flutter test`, and `flutter build web --no-pub` have passed
  in the development environment.
- `flutter build apk --debug --no-pub` has passed. The Android Kotlin plugin
  uses version 2.4.21 to match the Firebase Auth Android library metadata.
- Live Google authentication still requires enabling Google in Firebase and
  adding the platform OAuth configuration described above.
- Configure Firebase platform options and production Firestore rules/indexes.
- Persist the menu and admin availability changes in Firestore or another
  authorized backend.
- Integrate a payment provider before treating card selection as payment.
- Review privacy, address retention, accessibility, remote image handling,
  order lifecycle, and error states before production release.
