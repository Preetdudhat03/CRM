# Frontend Documentation

The Flutter frontend is the primary user interface for the CRM system. It is designed around the principles of reactive state management and component reusability.

## Project Structure
The `lib/` directory is organized by architectural layered concerns:
- **`core/`**: Central configuration, theming (`app_theme.dart`), constants (colors, dimensions), and global utility services like `PermissionService`.
- **`models/`**: Dart implementations of the database schemas implementing `fromJson` and `toJson` methods for serialization. E.g., `UserModel`, `LeadModel`.
- **`repositories/`**: Abstractions that dictate how data is fetched. They call `services`. E.g., `LeadRepository`.
- **`services/`**: Concrete classes interacting with external APIs or Supabase directly. E.g., `LeadService`, `PushNotificationService`.
- **`providers/`**: Using Riverpod to manage application state. E.g., `lead_provider.dart` uses `StateNotifier` to keep track of a list of leads, handle pagination, and manage `loading` states.
- **`screens/`**: UI definitions grouped by core feature module (e.g., `/auth`, `/home`, `/leads`, `/contacts`). Includes the main routing hub `MainLayoutScreen.dart`.
- **`widgets/`**: Reusable generic components (Buttons, Input Fields, Custom Bottom Navigation Bars, specific Animations like `FadeInSlide`).

## Key Implementation Concepts

### State Management: Riverpod (`providers/`)
Riverpod powers the CRM. Providers are strictly scoped:
- `FutureProvider`: Used for fetching one-time async operations, such as loading Dashboard metrics or recent activities.
- `StateNotifierProvider`: Used for complex states. E.g., `ContactNotifier` manages the local list of contacts, pagination logic (`loadMore()`, `refresh()`), and updating the local list optimally without re-fetching everything from the server when a single entity changes (`addContact()`, `updateContact()`).
- `Provider.family`: Used to create parameterized providers dynamically, such as fetching activities related *specifically* to one Lead ID (`entityActivitiesProvider`).

### Realtime Synchronization
In `LeadNotifier`, `ContactNotifier`, and `DealNotifier`, a `RealtimeChannel` instance is created inside the class constructor:
```dart
void _subscribeToRealtime() {
  _realtimeChannel = supabase.channel('public:leads')
    .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'leads',
      callback: (payload) { refresh(); }
    ).subscribe();
}
```
If another user updates a lead, the `refresh()` function is called silently (without showing a loading spinner), re-fetching the current page and updating the UI instantly.

### Multi-Platform Navigation
`MainLayoutScreen.dart` automatically adapts to screen width:
- **Mobile (<800px width):** Uses a standard bottom tab bar (`BottomNavigationBar`) hiding the menu off canvas.
- **Web / Desktop Tablet (>800px width):** Unfurls a `NavigationRail` pinned to the left side to utilize widescreen space efficiently.

### Push Notifications handling
`PushNotificationService` uses Firebase Messaging.
- Requests notification permissions cleanly via `PermissionService`.
- Retrieves the Firebase Device Token securely.
- Updates the token to the Supabase `fcm_tokens` table.
- Listens to active notifications while the app is foregrounded using `flutter_local_notifications` (invoked via `PushNotificationService.onMessage()`).
