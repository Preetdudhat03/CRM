# CRM Project Implementation Documentation

This document provides a comprehensive, up-to-date record of the features, architecture, and design decisions implemented in the CRM application. It serves as the primary reference for understanding the system's integration with Supabase, Firebase, and the unified UI/UX patterns.

---

## 1. Core Architecture & Tech Stack

### **Technology Stack**
- **Frontend**: Flutter (Dart) - targeting Mobile (Android/iOS) and Web.
- **State Management**: **Riverpod** (`flutter_riverpod`) for robust, scalable state handling.
- **Backend**: **Supabase** (PostgreSQL) for Data, Auth, and Realtime subscriptions.
- **Infrastructure**: **Firebase Cloud Messaging (FCM)** for push notifications and background messaging.
- **Local Storage**: `shared_preferences` for theme and notification settings persistence.

### **Key Architectural Patterns**
- **Realtime Integration**: Supabase Realtime Channels are used in Providers to auto-refresh the UI and trigger push notifications across devices when data changes.
- **Repository Pattern**: Abstracting Supabase logic into dedicated repository classes for cleaner service-to-ui interaction.
- **Service Layer**: Handling complex business logic (e.g., merging leads from multiple tables, managing push payloads).

---

## 2. Authentication & IAM System

### **Authentication & Profiles**
- **Unified Auth Flow**: `AuthGate` manages the lifecycle between login and the main app layout.
- **Profile Synchronization**: An `on_auth_user_created` trigger in Supabase automatically creates a record in the `profiles` table for every new `auth.users` entry.
- **Role-Based Access Control (RBAC)**:
  - Users are assigned roles: `SuperAdmin`, `Admin`, `Manager`, `Employee`, `Viewer`.
  - Permissions are mapped to these roles (e.g., `viewAnalytics`, `manageUsers`).
  - Permissions are enforced both in the UI (hiding/showing elements) and via **Supabase Row Level Security (RLS)**.

---

## 3. CRM Feature Modules

### **Unified Premium UI Redesign (March 2026 Update)**
The primary screens (Leads, Contacts, and Deals) have been redesigned for a premium, consistent feel:
- **Status/Stage Indicators**: Horizontal, scrollable indicators with real-time counts for quick filtering.
- **Enhanced Search**: Integrated search bars and sort dropdowns in the `AppBar` bottom section.
- **Premium Cards**: Unified card design with consistent padding, borders, and interaction menus.
- **Skeleton Loading**: `SkeletonCard` system for smooth, shimmering placeholders during data fetch.

### **Lead Management**
- **Smart Merging**: `LeadService` aggregates data from both the `leads` table and the `contacts` table (where status is 'lead').
- **Deduplication**: Intelligent filtering ensures that "Real Leads" take precedence over older "Contact-Leads".
- **Promotion Flow**: Editing a contact-based lead promotes it to the dedicated `leads` table for persistent tracking of field-specific data (Source, Value, etc.).

### **Contact Management**
- **Relationship Tracking**: Full profile management with support for `AvatarUrl`, `isFavorite`, and position-based titles.
- **Status lifecycle**: Tracks transitions from Lead to Customer to Churned.

### **Companies (Accounts)**
- **Account Hierarchy**: Parent entity for Contacts and Deals. Stores revenue, industry, and HQ details.
- **Revenue Aggregation**: Automatically calculates total company value based on linked "Closed Won" deals via database triggers.

### **Deal Management (Pipeline)**
- **Deal Stages**: Tracks deals through a standard pipeline: `Qualification` → `Proposal` → `Negotiation` → `Closed Won/Lost`.
- **Value Tracking**: Real-time currency formatting and value estimation.
- **Account Linking**: Deals are linked to both a primary contact and a parent company for B2B tracking.

### **Task Management**
- **Actionable Tasks**: Supports titles, descriptions, due dates, and priority levels (`High`, `Medium`, `Low`).
- **Linked Entities**: Tasks can be linked to Contacts, Leads, or Deals for contextual tracking.

---

## 4. Notification System

### **Multi-Channel Architecture**
- **In-App Notifications**: Realtime-driven notification panel linked to the `notifications` table.
- **Local Notifications**: Background-safe local notifications for device-specific alerts.
- **Push Notifications (FCM)**:
  - **Firebase Integration**: Leverages FCM for delivery when the app is closed or in the background.
  - **Edge Functions**: Supabase Edge Functions (`send-fcm`) trigger push payloads to registered `fcm_tokens`.
  - **Role Targeting**: Notifications can be broadcast to entire roles (e.g., "Broadcast to all Admins").
  - **Self-Filtering**: Intelligent logic to ignore notifications triggered by the user's own actions on the same device.

---

## 5. Persistence & Infrastructure

- **Theme Management**: Support for Light, Dark, and System modes, persisted via `SharedPreferences`.
- **FCM Token Registry**: `fcm_tokens` table tracks device IDs for every user to ensure delivery across multiple logins.
- **Activity Logging**: `ActivityService` tracks core actions (Lead created, Deal added) into an `activities` table which powers the Home Screen timeline.

---

## 6. Implementation Status (Current)

### **Completed**
- [x] Premium Redesign of Contacts, Leads, and Deals screens.
- [x] **Companies / Accounts Module** (B2B hierarchy, revenue aggregation).
- [x] Full FCM and Realtime notification system.
- [x] Local notification persistence and settings.
- [x] Task management module with entity linking.
- [x] Theme persistence (Light/Dark mode).
- [x] RBAC enforcement for deletion and user management.

### **Upcoming / Pending**
- [ ] **Supabase Storage Integration**: Move from URL-only avatars to actual file uploads.
- [ ] **Advanced Analytics**: Interactive charts for revenue and pipeline velocity.
- [ ] **Bulk Actions**: Support for mass email/status updates in listing screens.
- [ ] **Offline Sync**: Local database caching for low-connectivity environments.

---
**Document Generated by:** Antigravity AI Agent
**Last Updated:** 2026-03-03 (Added Companies Module)
