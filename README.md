# Field CRM

> [!IMPORTANT]
> This project is currently in the **Development Phase !**

A comprehensive, mobile-first Customer Relationship Management (CRM) platform designed specifically for field agents, sales teams, and managers. Field CRM provides a unified interface to track customer interactions, manage leads, handle complex sales pipelines, and organize daily activities with real-time synchronization.

## 🚀 Project Overview

Field CRM addresses the complexity and lack of mobile optimization in traditional CRM systems. By leveraging a modern, mobile-first approach with Flutter, it ensures that sales personnel stay informed and productive whether they are at their desk or in the field.

### Target Users
- **Sales Representatives / Agents**: Track daily calls, meetings, tasks, and leads.
- **Sales Managers**: Oversee team performance, monitor pipelines, and analyze trends.
- **Administrators**: Manage user roles, system permissions, and application settings.

## ✨ Core Features

1.  **Lead & Contact Management**: Intelligent tracking of potential customers and seamless conversion from Leads to Contacts.
2.  **Deal Tracking (Sales Pipeline)**: Manage sales opportunities through multi-stage pipelines (Qualification, Proposal, Negotiation, etc.) with real-time revenue tracking.
3.  **Company Management**: B2B view of the CRM, grouping contacts and deals under parent organizations.
4.  **Task & Activity Logging**: Actionable tasks with priorities and due dates, integrated with a global activity timeline.
5.  **Real-time Synchronization**: Powered by **Supabase Realtime**, ensuring UI updates occur instantaneously without refreshing.
6.  **Push Notifications**: Integrated with **Firebase Cloud Messaging (FCM)** for background alerts on critical events.
7.  **Role-Based Access Control (RBAC)**: Secure multi-tier roles (SuperAdmin, Admin, Manager, Employee, Viewer) with enforced Row Level Security (RLS).

## 🛠 Tech Stack

-   **Frontend**: Flutter (Dart)
-   **State Management**: Riverpod (`flutter_riverpod`)
-   **Backend & Database**: Supabase (PostgreSQL, GoTrue Auth, Edge Functions)
-   **Infrastructure**: Firebase Cloud Messaging (FCM) for notifications
-   **Local Storage**: `shared_preferences` for settings and theme persistence

## 📐 Architecture

Field CRM follows a robust architectural pattern:
-   **Repository Pattern**: Abstracting Supabase logic for clean service-to-UI interaction.
-   **Service Layer**: Handling complex business logic and notification payloads.
-   **Realtime Providers**: Utilizing Riverpod to stream live data directly into the UI.

## 🚦 Implementation Status

### Completed ✅
- [x] Premium UI Redesign for Contacts, Leads, and Deals.
- [x] Full Companies / Accounts Module with revenue aggregation.
- [x] Multi-tier RBAC and Supabase RLS integration.
- [x] FCM and Realtime notification system.
- [x] Task management with entity linking.
- [x] Theme persistence (Light/Dark mode).

### In Progress 🏗️
- [ ] Supabase Storage Integration for file/avatar uploads.
- [ ] Advanced Analytics Dashboards with interactive charts.
- [ ] Bulk actions for listing screens.
- [ ] Offline synchronization and local caching.

## 🏁 Getting Started

### Prerequisites
- Flutter SDK (Latest Stable)
- Supabase Project URL and Anon/Service Keys
- Firebase Project for FCM

### Installation
1.  Clone the repository.
2.  Run `flutter pub get` to install dependencies.
3.  Configure your environment variables for Supabase and Firebase.
4.  Run the application using `flutter run`.

---
*Last Updated: April 2026*