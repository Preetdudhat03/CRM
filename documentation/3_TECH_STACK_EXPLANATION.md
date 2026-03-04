# Tech Stack Explanation

This project leverages a cutting-edge, reactive technology stack designed for rapid development, cross-platform capabilities, and scalable database management. Here is a breakdown of every major technology chosen and the reasoning behind it.

## 1. Frontend: Flutter
**Why we use it:**
Flutter is a UI toolkit created by Google for building natively compiled applications for mobile, web, and desktop from a single codebase.
- **Single Codebase:** Saves enormous amounts of development time. We don't need a separate iOS team and Android team.
- **Performance:** Compiles to native ARM machine code, resulting in 60-120fps performance on devices.
- **Custom UI:** Allows pixel-perfect designs, leveraging built-in UI components that follow Material Design guidelines.

## 2. State Management: Riverpod
**Why we use it:**
Riverpod is a reactive caching and data-binding framework for Flutter. It is an evolution of the widely used `Provider` package.
- **Compile-Time Safety:** Catches provider errors during compilation rather than at runtime (no `ProviderNotFoundException`).
- **Simplicity with Async Data:** Makes handling loading/error/data states for network requests extremely easy using `AsyncValue`.
- **Decoupling:** Allows strict separation of UI, business logic, and data layers, making the app highly testable.

## 3. Core Backend & Database: Supabase (PostgreSQL)
**Why we use it:**
Supabase is an open-source alternative to Firebase. It wraps a powerful PostgreSQL database with tools for auto-generated APIs, real-time subscriptions, and authentication.
- **Relational Integrity:** Unlike NoSQL databases (like Firebase Firestore), PostgreSQL allows us to build complex relationships (e.g., a Deal belongs to a Contact, a Contact belongs to a Company) and ensures data consistency using Foreign Keys.
- **Row Level Security (RLS):** Policies are enforced directly at the database level. Even if an API endpoint is compromised, RLS ensures users can only read/write data they have permission to access.
- **Realtime:** Supabase turns PostgreSQL into a realtime database using Elixir-based WebSockets, allowing the UI to react instantly to data changes from other users.

## 4. Supplementary API: Node.js with Express
**Why we use it:**
While Supabase provides instant APIs via PostgREST, a custom Node.js server is used for complex aggregations, background workers, or integrations with third-party software that shouldn't live directly on the client.
- **Flexibility:** Allows writing custom server-side routing, integrations with advanced email providers, or highly customized data exports.
- **Separation of Concerns:** Heavy computational tasks or data syncing routines are handled efficiently without blocking the client.

## 5. Push Notifications: Firebase Cloud Messaging (FCM)
**Why we use it:**
FCM is the industry standard for delivering push notifications to mobile devices globally.
- **Reliability:** Ensures that background push notifications will wake up the device or place a message in the system tray consistently.
- **Cross-Platform:** Provides a unified way to send messages to Android (via Google Play Services) and iOS (via APNs).
- **Integration with Supabase:** We store FCM device registration tokens in Supabase and trigger messages via Supabase Edge Function webhooks.

## 6. Edge Functions (Deno)
**Why we use it:**
Supabase Edge Functions are serverless scripts deployed globally to run backend logic close to the user.
- **Webhook Processing:** Used seamlessly to react to DB triggers (like sending an FCM notification immediately after a row is added to the database).
- **No Cold Starts:** Deno-based isolate architecture ensures incredibly quick startup times compared to traditional serverless environments.
