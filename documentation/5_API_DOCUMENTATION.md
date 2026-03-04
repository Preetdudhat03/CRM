# API Documentation

The CRM system utilizes a dual-API approach. Most primary CRUD operations are handled directly by **Supabase PostgREST APIs** implicitly called by the Flutter client. However, a custom **Node.js/Express Backend** is provided for complex integrations, background processing, and as an alternative standard REST API.

This document details the custom Express Node.js application routes available.

## Base URL
`/api`

## 1. Leads API
The Leads API manages potential connections.

### `GET /api/leads`
Fetches a paginated list of leads.
- **Query Params:**
  - `page` (default: 0)
  - `pageSize` (default: 20)
  - `search` (optional string): Filters by `first_name`, `last_name`, `email`, or `lead_source`.
  - `status` (optional string)
  - `source` (optional string)
- **Response:** `{ success: true, data: [...], pagination: {...} }`

### `GET /api/leads/stats`
Gets overall lead statistics for the dashboard.
- **Response:** `total`, `new_leads`, `contacted`, `interested`, `qualified`, `lost`, `converted`, `pipeline_value`, `new_this_month`.

### `GET /api/leads/:id`
Gets a single lead by its UUID.

### `POST /api/leads`
Creates a new lead.
- **Body:** `{ first_name, last_name, email, phone, lead_source, status, assigned_to, notes, estimated_value }`

### `PUT /api/leads/:id`
Updates an existing lead.

### `DELETE /api/leads/:id`
Deletes a lead by ID.

### `POST /api/leads/:id/convert`
Translates a lead into a contact using the `convert_lead` PostgreSQL RPC transaction.
- **Response:** `{ success: true, data: { contactId, leadId }, message: '...' }`

---

## 2. Contacts API
Manages qualified connections and individuals.

### `GET /api/contacts`
Fetches a paginated list of contacts.
- **Query Params:** `page`, `pageSize`, `search` (filters by name, email, or company name).

### `GET /api/contacts/stats`
Returns aggregated contact data (e.g., total count, returning customers vs leads, favorites).

### `GET /api/contacts/:id`
Gets a single contact.

### `POST /api/contacts`
Creates a new contact.
- **Body:** `{ first_name, last_name, email, phone, company_name, position, address, notes, assigned_to, is_customer, avatar_url, is_favorite }`

### `PUT /api/contacts/:id`
Updates a contact.

### `PATCH /api/contacts/:id/favorite`
Toggles a contact's `is_favorite` boolean status.

### `DELETE /api/contacts/:id`
Deletes a contact.

---

## 3. Notifications API
Manages system and push notifications.

### `POST /api/notifications`
Creates a new notification globally or targeted to a user.
- **Body:** `{ title, message, user_id, type_encoding }`

### `PUT /api/notifications/:id/read`
Marks a specific notification as read.

## Implementation Details
- Errors are returned in a standard format: `{ success: false, error: "Error message details" }`.
- Status codes: `200` OK, `201` Created, `404` Not Found, `409` Conflict (e.g., Lead already converted), `500` Internal Server Error.
