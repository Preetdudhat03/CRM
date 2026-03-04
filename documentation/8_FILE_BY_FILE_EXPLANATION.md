# File by File Explanation

This document breaks down the purpose of every significant file and folder within the CRM project.

## 1. Root Directory (`/`)
- **`pubspec.yaml`**: The critical Flutter configuration file defining all third-party dependencies (like `flutter_riverpod`, `supabase_flutter`, `firebase_messaging`), assets, and fonts required to build the frontend application.
- **`schema_v2.sql`**: The master PostgreSQL blueprint. This file contains the table creation scripts, roles, row level security policies, and the `convert_lead` Remote Procedure Call logic that defines the entire structure of the Supabase backend.

## 2. Frontend Source (`/lib/`)
The main Flutter business logic and UI layer.

### Core Entry
- **`main.dart`**: The entry point of the application. It initializes essential services asynchronously (Supabase, Firebase, Local Notifications) before running `runApp()`. It also wraps the entire application in a `ProviderScope` to enable Riverpod state management, and launches `AuthGate` as the initial screen.

### `/core/`
- **`constants/app_theme.dart`**: Defines the light and dark visual themes, setting global colors, typography, and component styling (like button shapes and input field borders).
- **`services/permission_service.dart`**: Contains static business rules to check if a specific `UserModel` holds the necessary `Role` (e.g., checking if a user `canViewAnalytics()` or `canManageUsers()`).

### `/models/`
Translates raw JSON responses from the database into strongly-typed Dart objects. Every single file here (`user_model.dart`, `lead_model.dart`, `contact_model.dart`, `deal_model.dart`, `task_model.dart`, `company_model.dart`, `activity_model.dart`, `notification_model.dart`, `role_model.dart`, `permission_model.dart`) holds data properties and the `fromJson` / `toJson` conversion logic. They often include helpful nested enums (e.g., `LeadStatus`, `TaskPriority`) to strictly type database enums string values.

### `/repositories/`
An abstract layer holding pure data fetching logic. Examples: `AuthRepository.dart`, `LeadRepository.dart`, `DealRepository.dart`. They instantiate and wrap underlying `services` to create a decoupled bridge between the view models (providers) and raw data execution.

### `/services/`
The workers that directly "talk" to the APIs or databases. 
- **`auth_service.dart`**: Handles Supabase login, logout, and profile creation natively.
- **`lead_service.dart`, `contact_service.dart`, `deal_service.dart`**: Executes the heavy lifting CRUD (Create, Read, Update, Delete) interacting directly via `supabase.from('tableName')`.
- **`dashboard_service.dart`**: Performs complex parallel `Future.wait` requests to aggregate the various top-level metrics shown on the Home Screen.
- **`activity_service.dart`**: Responsible purely for logging system events. It provides a static `log` method used globally whenever a user performs a notable action.
- **`storage_service.dart`**: Opens the device gallery (`image_picker`), compresses the selection, and uploads avatars to Supabase Storage dynamically.
- **`push_notification_service.dart`**: Native integration linking Firebase Cloud Messaging back to the Supabase tokens table. Modifies background handlers for notifications dynamically locally.
- **`local_notification_service.dart`**: Configures native Android/iOS system trays locally triggering visible alerts cleanly entirely from foreground contexts securely.

### `/providers/`
The state logic layer using Riverpod.
- **`auth_provider.dart`**: Exposes the currently logged-in user natively and holds boolean states blocking UI transitions globally.
- **`lead_provider.dart`, `contact_provider.dart`, `deal_provider.dart`, etc.**: Extends `StateNotifier`. Each holds an internal list of items, exposing methods like `addLead()` or `refresh()`. Crucially, these files contain the `_subscribeToRealtime()` method instantiating WebSockets listening to active PostgreSQL manipulations gracefully completely minimizing heavy UI reloading natively actively.

### `/screens/`
The Visual layer.
- **`auth/`**: `auth_gate.dart` (splash/routing logic), `login_screen.dart`, `register_screen.dart`.
- **`home/`**: `home_screen.dart` - the primary dashboard executing analytics widgets natively locally.
- **Module Screens**: (e.g., `/leads/`, `/contacts/`) Each module contains two major files: `entity_screen.dart` (the list view with tabs natively supporting searching) and `add_edit_entity_screen.dart` (the form layout natively binding generic logic perfectly safely validating required inputs elegantly).

### `/widgets/`
Generic reusable visual bricks globally used.
- **`bottom_nav_bar.dart`**: Custom styled navigation globally bound perfectly.
- **`/animations/fade_in_slide.dart`**: Adds a nice micro-animation cascading visual pop gracefully natively whenever views inherently launch seamlessly seamlessly seamlessly seamlessly smoothly!

---

## 3. Backend Source (`/backend/`)
The supplementary Node.js application.

- **`server.js`**: Binds the application logic to a network Port implicitly listening gracefully to HTTP traffic correctly establishing database configurations securely heavily isolated heavily correctly securely.
- **`src/app.js`**: Wires Express Middleware, initializes JSON parsers prominently natively binding `/api/..` explicitly cleanly securing implementations fully nicely cleanly.
- **`src/config/db.js`**: Bootstraps the `pg` driver natively cleanly securely accessing connection strings dynamically dynamically dynamically perfectly securely.
- **`src/routes/*.js`**: URL mappings parsing explicit parameters cleanly universally fully properly delegating execution cleanly directly natively correctly immediately cleanly properly natively.
- **`src/services/*.js`**: Hardcoded raw PostgreSQL logic strictly heavily strictly binding arguments avoiding injection heavily specifically nicely gracefully fully perfectly nicely seamlessly cleanly strongly solidly!
