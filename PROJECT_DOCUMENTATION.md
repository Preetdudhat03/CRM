# CRM Project Implementation Documentation

This document provides a comprehensive, step-by-step record of all features, modifications, design decisions, and database changes implemented in the CRM application. It serves as a reference for developers to understand the system architecture, authentication flow, data models, and UI interactions.

---

## 1. Foundation & Architecture

### **Technology Stack**
- **Frontend**: Flutter (Dart)
- **State Management**: Riverpod (`flutter_riverpod`)
- **Backend & Auth**: Supabase (`supabase_flutter`)
- **Routing**: Flutter Navigator & Material Routes (some parts use simpler navigation for now)
- **Database**: PostgreSQL (via Supabase)

### **Project Structure**
- `lib/models/`: Data models (Contact, Lead, User, Role, etc.)
- `lib/providers/`: Riverpod providers for state management.
- `lib/screens/`: UI screens organized by feature (Auth, Contacts, Leads, etc.)
- `lib/services/`: Service classes for Supabase interactions.
- `lib/widgets/`: Reusable widgets (Cards, Animations, Input Fields).
- `backend/schema.sql`: Source of truth for database schema.

---

## 2. Authentication & IAM System

### **Authentication Flow**
- **Login Screen**:
  - Implemented `LoginScreen` with email/password fields.
  - Added a "Check Connection" button (dev-only) to verify Supabase reachability.
  - Integrated `AuthService` to handle `signInWithPassword`.
  - Added error handling for "Email not confirmed" and invalid credentials.
- **Registration**:
  - Implemented `RegisterScreen` for new user creation via `signUp`.
  - Uses `auth.users` for credentials and triggers a backend function to create a public profile.
- **Auth Guard**:
  - Implemented `AuthGate` widget to listen to auth state changes.
  - Automatically redirects users to `MainLayout` upon login or `LoginScreen` upon logout.

### **Identity & Access Management (IAM)**
- **Role-Based Access Control (RBAC)**:
  - Defined `Role` enum: `SuperAdmin`, `Admin`, `Manager`, `Employee`, `Viewer`.
  - Defined `Permission` enum for granular access (e.g., `viewContacts`, `createLeads`, `manageUsers`).
  - Implemented logic to map Roles to specific Permissions.
- **User Management**:
  - Created `UserManagementScreen` (Settings -> User Management) for Admins.
  - Implemented `UserService` to fetch users from the `profiles` table.
  - Enabled "Add User" (Invite simulation) and "Edit User" (Role change).
  - Added `AddEditUserScreen` with form validation and proper `async/await` handling for UI feedback.
- **Database Security (RLS)**:
  - Enabled **Row Level Security (RLS)** on sensitive tables (`profiles`).
  - Added SQL Policies to:
    - Allow authenticated users to view all profiles (for directory listing).
    - Allow users to update their *own* profile.
    - Added a trigger `on_auth_user_created` to automatically create a `profiles` entry when a user signs up.
    - Added a backfill script to ensure existing users have profile entries.

---

## 3. Contact Management

### **Models & Schema**
- **ContactModel**:
  - Added fields: `id`, `name`, `email`, `phone`, `company`, `position`, `status` (Lead/Customer/Churned).
  - Added **`avatarUrl`**: String field for profile images.
  - Added **`isFavorite`**: Boolean field to mark VIP contacts.
- **Database**:
  - Defined `contacts` table with matching columns.
  - Added `is_favorite` column (default `FALSE`).

### **Features**
- **Listing**:
  - `ContactCard` widget displays contact info with initials avatar if image missing.
  - Implemented **Avatar Logic**: Checks if `avatarUrl` is valid; falls back to initials.
- **Adding/Editing**:
  - `AddEditContactScreen`:
    - Form with validation.
    - **Phone Validation**: Added strict Regex `r'^[+]?[0-9\s-]{10,}$'` to ensure valid numbers.
    - Supports creating new records and updating existing ones.
    - **State Management**: Using `ContactNotifier` (Riverpod) to update the UI instantly without refresh.
- **Contact Details**:
  - `ContactDetailScreen`:
    - Shows full info.
    - wired up **Edit Button** to navigate to `AddEditContactScreen`.
    - Wired up **Favorite Button** (Star icon):
      - Toggles `isFavorite` state via `ContactService.toggleFavorite`.
      - Updates UI instantly via `Consumer` widget.
- **Search**:
  - Implemented real-time search filtering in `ContactNotifier`.

---

## 4. Lead Management

### **Architecture Decision**
- **Dual Source of Truth**:
  - Leads exist in a dedicated `leads` table.
  - BUT, Contacts with `status = 'lead'` are ALSO treated as leads.
- **Unified View**:
  - Modified `LeadService.getLeads()` to **fetch from both tables**:
    1. Query `leads` table.
    2. Query `contacts` table where `status == 'lead'`.
    3. Merge the results, map Contacts to `LeadModel` structure, remove duplicates, and sort by date.
  - This ensures users see *all* potential business opportunities in one screen.

### **Features**
- **Models**: `LeadModel` includes `estimatedValue`, `source`, `assignedTo`.
- **UI**:
  - `LeadsScreen` displays the merged list.
  - `AddEditLeadScreen` includes specific fields like "Estimated Value" and "Source" (e.g., LinkedIn, Web, Referral).
  - Added phone validation regex to Lead forms as well.

---

## 5. Dashboard & Activity

### **Home Screen**
- **Statistics Cards**:
  - Implemented dynamic counters for:
    - **Total Contacts** (from `contactStatsProvider`).
    - **Total Leads** (from `leadStatsProvider`).
    - **Active Deals** (from `dealStatsProvider`).
    - **Revenue**: Restricted to users with `viewAnalytics` permission.
  - Cards are interactive and navigate to their respective tabs.
- **Recent Activity**:
  - Created `RecentActivityWidget` to show a timeline of actions.
  - Implemented `ActivityService` to fetch logs from `activities` table.
  - Added `timeago` package for "5m ago" timestamps.
  - Color-coded icons based on activity type (Created, Updated, Deleted).

---

## 6. Code Quality & Fixes

### **Bug Fixes**
- **Build Errors**:
  - Fixed missing fields in `ContactModel` (`avatarUrl`, `isFavorite`) which caused compilation errors.
  - Fixed invalid `try/catch` syntax in `ContactProvider.deleteContact`.
  - Fixed syntax errors in `ContactDetailScreen` (extra brackets).
- **Logic Fixes**:
  - Corrected `AddEditUserScreen`: It was firing requests without `await`, causing "Success" messages even on failure. Added `await` and `try/catch` block for proper UX.
  - Fixed `LeadService` logic to correctly map Contact JSON to Lead Models.

### **Database Schema (SQL Executed)**
- Created `profiles` table to sync with `auth.users`.
- Created trigger `handle_new_user` for auto-profile creation.
- Enabled RLS on `profiles`.
- Backfilled missing profiles for legacy users.
- Added `is_favorite` to `contacts`.

---

## 7. Recent Improvements (Feb 16, 2026)

### **Lead Management Enhancements (Fixes & Features)**
- **Lead Promotion Mechanism**:
  - Implemented logic in `LeadService.updateLead` to automatically **promote** "Contact-Leads" (which originate from the `contacts` table) to "Real Leads" in the `leads` table upon any edit.
  - This ensures that fields specific to leads (e.g., `Status`, `Source`, `Assigned To`) are permanently saved and not lost on app restart.
  - Uses `upsert` with the **same ID** as the contact to maintain a single identity for the record.
- **Deduplication Strategy**:
  - Enhanced `LeadService.getLeads` to intelligently merge records from both tables.
  - Implemented strict filtering: If a record exists in the `leads` table, any corresponding record in the `contacts` table (matching by **ID** or **Email**) is hidden.
  - This prevents duplicate entries in the UI and ensures the "Real Lead" version (with the latest data) always takes precedence.
- **Lead Status Management**:
  - Defined `LeadStatus` enum (`newLead`, `contacted`, `interested`, `qualified`, `lost`, `converted`) for consistent status tracking.

### **User Experience & Persistence**
- **Theme Persistence**:
  - Integrated `shared_preferences` package.
  - Updated `ThemeModeNotifier` to save the user's theme choice (Light/Dark/System) to local storage.
  - The app now remembers and applies the preferred theme immediately upon launch.
- **User Role Refresh**:
  - Added `refreshUser` method to `AuthNotifier`.
  - Updated `AddEditUserScreen` to immediately trigger a session refresh when a user updates their own role, ensuring UI permissions reflect changes without needing to relogin.

### **Stability & Infrastructure**
- **Build Configuration**:
  - Optimized `gradle.properties` memory settings (`-Xmx4G`) to prevent "Gradle daemon disappeared" crashes during build.
- **Error Handling**:
  - Wrapped `Supabase.initialize` in a `try-catch` block in `main.dart`.
  - The app now displays a user-friendly error screen instead of crashing silently if initialization fails (e.g., due to network issues).

---

## 8. Next Steps (Pending)
- **Automatic Activity Logging**: Currently, we have the `activities` table and reader, but we need to implement Triggers or Service calls to *write* into it whenever a record changes.
- **Image Upload**: Implement actual file upload to Supabase Storage for Avatars.
- **Advanced Permissions**: Enforce RLS policies based on roles (e.g. "Managers can create, Viewers can only read").

---
**Document Generated by:** Antigravity AI Agent
**Last Updated:** 2026-02-16
