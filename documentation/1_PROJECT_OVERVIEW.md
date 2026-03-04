# Project Overview

## What Problem This Software Solves
The CRM (Customer Relationship Management) project is designed to give field agents, sales teams, and managers a single, unified platform to track customer interactions, manage leads, handle deals through various pipeline stages, and organize daily tasks. Traditional CRMs can be overly complex or lack seamless mobile functionality. This software solves that by providing a robust, mobile-first approach (using Flutter) while ensuring real-time data synchronization and instantaneous push notifications, ensuring sales personnel are always informed whether they are at their desk or in the field.

## Target Users
- **Sales Representatives / Agents:** To track their daily calls, meetings, tasks, leads, and ongoing deals.
- **Sales Managers:** To oversee team performance, view dashboard analytics, monitor sales pipelines, and track team activities.
- **Administrators:** To manage user roles, system permissions, and overall application settings.

## Core Features
1. **User Authentication & Role-Based Access Control (RBAC):** Secure login with multi-tier roles (SuperAdmin, Admin, Manager, Employee, Viewer) determining who can view, edit, or delete records.
2. **Lead & Contact Management:** Tracking potential customers (Leads) and converting them into established connections (Contacts) once qualified. Includes detailed status tracking and communication logging.
3. **Deal Tracking (Sales Pipeline):** Managing sales opportunities through various stages (e.g., Qualification, Proposal, Negotiation, Closed Won, Closed Lost) with estimated revenue tracking.
4. **Company Management:** Grouping contacts and deals under parent organizations to form a B2B view of the CRM.
5. **Task & Activity Logging:** Users can create tasks with due dates, priorities, and status indicators. Any major action (e.g., creating a lead, moving a deal) is automatically logged to a global and entity-specific activity timeline.
6. **Real-time Synchronization & Notifications:** Using Supabase Realtime and Firebase Cloud Messaging (FCM), users see updates instantaneously without refreshing their apps, and receive background push alerts for important events (like tasks due or leads assigned).
7. **Dashboard & Analytics:** A birds-eye view of total contacts, leads, deals, revenue trends, tasks due today, and recent activities.

## High-Level Architecture
```text
[ Mobile/Web Client (Flutter) ]
        |
        |-- (REST APIs & Realtime WebSockets)
        v
[ Backend & Database Layer ]
   |-- Supabase Platform
   |    |-- Authentication (GoTrue)
   |    |-- Database (PostgreSQL)
   |    |-- Realtime (WebSockets)
   |    |-- Edge Functions (Deno - for FCM Triggers)
   |    |-- Storage (Avatars, Attachments)
   |
   |-- Node.js Backend (Express)
        |-- Custom API Routes / Business Logic
        |-- Background Workers (e.g., Notification Queue)

[ External Services ]
   |-- Firebase Cloud Messaging (Push Notifications)
```
