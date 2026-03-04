# Backend Documentation

The main robust backend data operations are handled natively by **Supabase**. However, a supplementary **Node.js/Express Server** acts as an intermediary for custom routes and business logic that cannot be safely executed purely via frontend queries.

## Node.js Application Architecture

### Folder Structure
Located at `p:\pro\CRM\backend`
- **`src/app.js`**: Core Express setup, middleware (CORS, JSON parsing), and route registrations.
- **`src/config/db.js`**: PostgreSQL connection pool using `pg`. Connects directly to the Supabase database using `DATABASE_URL`.
- **`src/routes/`**: Route definition files (`contact.routes.js`, `lead.routes.js`) pointing to their respective HTTP endpoints. Note that `auth.routes.js` is minimal, as Supabase GoTrue Auth is the primary IAM mechanism.
- **`src/services/`**: Connects routes to the Database queries. Contains raw SQL definitions replicating complex queries.
- **`server.js`**: Application entry point defining port binding and instantiating the HTTP server.

## Notable Implementations

### Service Pattern
The services (`ContactService.js`, `LeadService.js`) encapsulate raw SQL into static methods representing complete domain operations. This creates a clean boundary strictly focused on business data logic. 

**Pagination & Searching Details:**
- `LeadService.searchLeads()` implements safe, parameterized wildcard SQL `ILIKE` searches to return matching queries instantly minimizing injection risks.
- Paginates queries deeply utilizing `OFFSET $X LIMIT $Y` variables keeping massive arrays optimized.

### The Conversion Transaction (`LeadService.convertLead()`)
Considered the most complex route, this avoids corrupting the user database funnel:
1. Obtains a raw client connection pool.
2. Starts transaction: `BEGIN`.
3. Issues a localized `SELECT ... FOR UPDATE` lock, preventing duplicate overlapping conversions on the same lead simultaneously.
4. Generates a new record in `contacts` linking `created_from_lead = TRUE` mapping identifiers.
5. Updates `leads` status flag cleanly to 'converted' applying timestamps.
6. Commits: `COMMIT`. Validates rollback on failure securely.
7. Enqueues a notification locally asynchronously for trailing team visibility without blocking the response.

### Extensibility
This Node layer is intended strictly as supplementary logic meant to run parallel behind API gateways. Future complex integrations (e.g., Stripe Payments for billing, Twilio for SMS) should reside heavily on this internal Express Node.js layer securing keys safely unlike the public thick-client Flutter side.
