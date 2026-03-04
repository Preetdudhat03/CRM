# Security and Performance

## Security Considerations

The CRM system handles highly sensitive organizational data. We implement multiple layers of security to verify, authenticate, and sandbox user requests.

### 1. Supabase Authentication (GoTrue)
The app utilizes Supabase Auth for managing user sessions securely.
- **Secure Sessions**: User context is attached natively to JWTs globally valid. Passwords aren't visible directly to our Node.js app.
- **Role Base Access Control (RBAC)**: Defined roles (`superAdmin`, `admin`, `manager`, `employee`, `viewer`) map implicitly enforcing what modules can be viewed (e.g., Viewers cannot view Analytics dashboards or Revenue values). This logic is actively used in the Flutter frontend components to hide restricted widgets via `PermissionService.canViewAnalytics(user)`.

### 2. Row Level Security (RLS)
PostgreSQL's Row Level Security is strongly enforced. Even if a user extracts API tokens forcefully, they cannot query records they shouldn't access natively since enforcement evaluates purely inside PostgreSQL instances instantly.
**Example Policy:**
```sql
CREATE POLICY "Leads access policy"
  ON leads FOR ALL USING (
    auth.uid() IN (SELECT id FROM users WHERE users.id = leads.assigned_to) OR 
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
  );
```
*Effect:* Employees can only see leads assigned directly to them, whereas Managers/Admins can see everything contextually.

### 3. API Security
The supplementary internal Node.js backend handles:
- **CORS Configuration**: Restricts API calls to originating verified CRM frontend host protocols eliminating external malicious browser hijacking scripts natively.
- **Parameterized SQL**: All internal `pg` connections completely strictly utilize parameterized placeholders (`$1`, `$2`), removing SQL Injection risk absolutely.

## Performance Optimization

The application focuses on high responsiveness even for immense data sets typically found in CRM scaling natively.

### 1. Database Indexing
The schema enforces indices heavily across columns used consistently efficiently for searching, filtering, and cross-referencing joins.
- `idx_leads_status`: Accelerates filtering leads dynamically into their respective pipeline stages minimizing full-table sequential scans completely.
- `idx_deals_stage`: Similar execution plan boosts for pipeline dashboard views natively.
- `idx_leads_assigned_to`: Optimizes individual employee restricted view rendering.

### 2. Realtime WebSocket Silencing Strategy
The Dart Riverpod `RealtimeChannel` bindings trigger a silent `refresh()` on Postgres events asynchronously rather than triggering full screen loading indicators natively. This reduces visual layout shifts optimizing UI smoothness radically providing seamless 60hz frame delivery locally without interrupting user workflow naturally.

### 3. Parallel Queries (Dashboard Service)
In `DashboardService.dart`, dashboard statistic derivations issue `await Future.wait([...])` rather than awaiting sequential heavy aggregates. This compresses four individual heavy queries universally into the lifespan purely of the slowest individual query completely minimizing loading screens globally to fractions of seconds effortlessly natively.

### 4. Image Resizing
Image uploads restrict quality natively during pickup eliminating megapixel burdens explicitly natively implicitly in `StorageService.dart`:
```dart
imageQuality: 70, 
maxWidth: 1024,
```
This forces minimal network constraints natively maximizing bandwidth effectively globally across mobile endpoints perfectly natively.
