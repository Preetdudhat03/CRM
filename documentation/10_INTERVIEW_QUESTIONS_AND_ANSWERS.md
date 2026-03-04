# Interview Questions & Answers

If you study these questions, you will be deeply prepared to discuss the architectural decisions, functionality, and technological mechanisms of this CRM platform.

## 1. Frontend & State Management

**Q: Why was Flutter chosen over React Native for this CRM?**
A: Flutter was chosen primarily for its consistent rendering engine (Skia) ensuring pixel-perfect UI execution across all platforms natively. Flutter natively compiles to ARM machine code which offers significantly better performance (60-120fps), meaning less UI jank for complex tables/dashboards compared to React Native's JS bridge. It also provides a purely consistent visual implementation across Android and iOS out-of-the-box.

**Q: How does Riverpod solve state management issues better than simple Provider?**
A: Riverpod provides compile-time safety explicitly preventing `ProviderNotFoundException`. It heavily handles asynchronous data streams effectively using `AsyncValue` efficiently, eliminating boilerplate for mapping `loading`, `error`, and `data` states independently.

**Q: Explain how real-time updates are propagated to the UI.**
A: In our Riverpod Providers (e.g., `LeadNotifier`), we instantiate a Supabase `RealtimeChannel` listening actively purely natively directly on specific database tables. Whenever an event (Insert/Update) triggers from the database, the provider's native `refresh()` implicitly pulls fresh data asynchronously and updates the list without displaying a heavy loading screen, resulting in a smooth UI update for the user.

## 2. Backend & Architecture

**Q: Why use Supabase over Firebase?**
A: Supabase offers a relational PostgreSQL database. Because a CRM relies heavily on relationships (e.g., tracking a specific Task tied to a specific Deal, which is tied to a specific Contact at a Company), using a relational database with strict foreign-key constraints ensures data consistency. Firebase Firestore is NoSQL, which would require massive data duplication and complex manual syncing to achieve the same result.

**Q: How does Row Level Security (RLS) work in this application?**
A: RLS ensures that access policies are enforced directly at the database level. For example, a policy on the `leads` table uses `auth.uid()` to only return rows where the user ID matches the `assigned_to` column (unless the user has the 'admin' role). This means even if someone bypasses the client application and uses the raw API directly, they are still blocked by the database from seeing unauthorized leads.

**Q: How does the Lead Conversion flow guarantee data consistency?**
A: Lead conversion requires creating a new Contact and updating the Lead simultaneously. If one fails, the data becomes disjointed. We handle this inside a PostgreSQL Remote Procedure Call (RPC) using an atomic `BEGIN` and `COMMIT` transaction block natively. It locks the lead row (`FOR UPDATE`), verifies it hasn't already been converted, inserts the contact, updates the lead, and commits gracefully. If any step fails, everything rolls back seamlessly.

## 3. Notifications & Integrations

**Q: Describe the lifecycle of a Push Notification when a manager assigns a task.**
A: 
1. Manager creates a task specifically assigned to Employee X via the Flutter App.
2. The UI triggers an insert into the Task table, and an accompanying insert into the `notifications` DB table globally via `PushNotificationLocally`. 
3. This row creation fires a database Webhook implicitly reaching a Supabase Edge Function seamlessly.
4. The Edge function decodes the intended recipient, queries the `fcm_tokens` table internally to get the device token natively, constructs the Firebase payload strongly, and fires the REST request to Firebase servers.
5. Firebase Cloud Messaging receives the ping. FCM then pushes the notification to the employee's registered device instantaneously.
