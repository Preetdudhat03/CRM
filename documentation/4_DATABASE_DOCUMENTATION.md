# Database Documentation

The CRM application uses **PostgreSQL**, hosted on Supabase, as its primary relational database. This document details the core tables, their purposes, and relationships.

## Core Tables

### 1. `users` (Managed by Supabase Auth - `auth.users`)
Provides core authentication infrastructure, handling encrypted passwords and email verifications.

### 2. `profiles`
Because `auth.users` is isolated for security, the `profiles` table is a public reflection of the user. It is automatically synchronized via a trigger whenever a new user registers.
- `id` (UUID, Primary Key) - Matches `auth.users.id`.
- `name` (TEXT)
- `email` (TEXT)
- `role` (TEXT) - Maps to roles defined in the application (e.g., admin, manager, viewer).
- `avatar_url` (TEXT)

### 3. `companies`
Represents client organizations or B2B partners.
- `id` (UUID, Primary Key)
- `name` (TEXT)
- `industry` (TEXT)
- `website` (TEXT)

### 4. `contacts`
Represents individuals. Contacts can be standalone or linked to a `company`. They can also be generated directly from previously unqualified `leads`.
- `id` (UUID, Primary Key)
- `first_name`, `last_name`, `email`, `phone`
- `company_id` (UUID, Foreign Key) -> `companies.id`
- `assigned_to` (UUID, Foreign Key) -> `users.id`
- `is_customer`, `is_favorite` (BOOLEAN)
- `source_lead_id` (UUID, Foreign Key) -> `leads.id` (helps trace origin).

### 5. `leads`
Represents unqualified prospects. A lead becomes a contact once qualified, through the `convert_lead` Remote Procedure Call (RPC).
- `id` (UUID, Primary Key)
- `first_name`, `last_name`, `email`, `phone`
- `lead_source` (TEXT) - e.g., Website, Referral, Trade Show
- `status` (TEXT) - new, contacted, interested, qualified, lost, converted
- `converted_contact_id` (UUID, Foreign Key) -> `contacts.id`

### 6. `deals`
Represents sales opportunities or pipelines. Linked to `contacts`.
- `id` (UUID, Primary Key)
- `title` (TEXT)
- `contact_id` (UUID, Foreign Key) -> `contacts.id`
- `value` (NUMERIC) - Estimated amount expected from the deal.
- `stage` (TEXT) - prospecting, qualification, proposal, negotiation, closed_won, closed_lost

### 7. `tasks`
Actionable to-do items assigned to users. Can be generically linked to other entities (Contacts, Leads, Deals) using a polymorphic relationship.
- `id` (UUID, Primary Key)
- `title`, `description`, `due_date`
- `status` (pending, in_progress, completed)
- `related_entity_id` (UUID) - ID of the lead, contact, or deal to which the task belongs.
- `related_entity_type` (TEXT) - "lead", "contact", or "deal".

### 8. `activities`
Serves as an immutable audit log and timeline. Whenever a record is created, updated, or deleted, an entry is recorded here.
- `id` (UUID, Primary Key)
- `title`, `description`
- `activity_type` (TEXT) - e.g., "lead_created", "call_logged"
- `related_entity_id`, `related_entity_type`
- `created_by` (TEXT) - Name of user who performed the action.

### 9. `notifications` & `fcm_tokens`
Used to manage in-app and push notifications.
- `notifications`: Stores the message, read status, and intended audience (encoded in `related_entity_type`).
- `fcm_tokens`: Stores mapping between User IDs and Firebase device tokens.

## Relationships & Flow
- **1-to-Many**: A User can be assigned many Contacts, Leads, Deals, and Tasks.
- **1-to-Many**: A Company can have many Contacts.
- **Polymorphic**: `activities` and `tasks` use `related_entity_id` and `related_entity_type` to connect to multiple different tables dynamically without requiring multiple foreign key columns.

## Key Database Procedures
- **`handle_new_user()` Trigger**: Automatically inserts a matching row into `profiles` when a user signs up.
- **`convert_lead(lead_uuid)` RPC**: An atomic SQL function that:
  1. Takes a lead.
  2. Copies its info creating a new `contact`.
  3. Updates the lead's status to 'converted' and securely maps the new `converted_contact_id`.
  4. Commits as a single atomic transaction avoiding orphaned data.
