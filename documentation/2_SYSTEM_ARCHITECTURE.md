# System Architecture

## Overview
The CRM system follows a modern, decoupled client-server architecture. It utilizes a **Flutter** frontend for cross-platform compatibility (iOS, Android, Web), communicating primarily with a **Supabase** backend-as-a-service (BaaS) and a supplementary **Node.js/Express** backend for specific custom workflows and external integrations.

## Architectural Components

### 1. The Frontend Client (Flutter)
The frontend application is built with Flutter, heavily relying on **Riverpod** for state management. 
- **Providers:** Define how data is structured and globally accessible.
- **Repositories:** Abstract the data layer, allowing the app to switch backend sources if necessary without affecting the UI.
- **Services:** Manage the direct communication via REST or WebSockets to Supabase or the Node.js API.
- **UI (Screens & Widgets):** Listens to state changes from Riverpod and updates automatically.

### 2. The Primary Backend (Supabase)
Supabase acts as the core backend, providing several essential services out of the box:
- **PostgreSQL Database:** Holds all the structural data (Users, Leads, Contacts, Deals, Tasks, Activities).
- **GoTrue Authentication:** Manages secure JWT-based authentication for user sessions.
- **PostgREST:** Exposes the PostgreSQL database naturally through RESTful APIs securely via Row Level Security (RLS).
- **Realtime:** Uses WebSockets to stream database changes (Inserts, Updates, Deletes) directly to the Flutter app.
- **Edge Functions:** Deno-based serverless functions that react to database Webhooks (e.g., `send-fcm` function to trigger push notifications when new records are added to the `notifications` table).
- **Storage:** Used for uploading and serving user avatars or other related media.

### 3. The Supplementary Backend (Node.js)
While Supabase handles direct database operations, a separate Node.js application is used for:
- Complex transactional logic that goes beyond simple CRUD operations.
- Providing a standard REST backend (`/api/leads`, `/api/contacts`) that can be consumed by other services or webhooks.
- Running background jobs/workers (e.g., notification queues, aggregation tasks).

### 4. Push Notification Service (Firebase Cloud Messaging - FCM)
Firebase Cloud Messaging is used to deliver background and foreground push notifications to mobile devices. 
- The Flutter client requests FCM device tokens and stores them in the Supabase `fcm_tokens` table.
- When an event occurs (e.g., a lead is assigned), a notification record is inserted into the `notifications` table.
- A Supabase Edge Function (`send-fcm`) listens to this insert and pings Firebase with the payload, which then pushes it to the recipient's device.

## Request & Data Flow Example
**Scenario: A Manager assigns a Lead to a Sales Rep.**
1. **Client Action:** The Manager uses the Flutter app to update a Lead's `assigned_to` field.
2. **State Management:** The Riverpod `LeadNotifier` calls the `LeadRepository`.
3. **API Request:** The `LeadService` sends a `PATCH` request to Supabase to update the `leads` table.
4. **Database Exec:** PostgreSQL updates the row and evaluates Row Level Security (RLS) policies.
5. **Realtime Broadcast:** Supabase Realtime channels notice the update and broadcast the change over WebSockets.
6. **Client Reaction (Sales Rep):** The Sales Rep's app receives the Realtime event and updates their UI instantly without a manual refresh.
7. **Custom Trigger Action:** Concurrently, an `ActivityService` logs this change in the `activities` table, and a `Notification` is stored in the `notifications` table.
8. **Push Notification Delivery:** Inserting into `notifications` fires a webhook. Supabase Edge Function grabs the Sales Rep's FCM token, formats the notification, and sends it via Firebase. The Sales Rep gets a buzz on their phone.
