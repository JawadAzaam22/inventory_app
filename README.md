
## Inventory App

This is a simple Flutter application for managing a retail inventory. It includes Arabic RTL support, a modern UI with light/dark themes, and uses the BLoC (Cubit) pattern for state management.

---

### Purpose

- Manage products (create, edit, delete, track quantities)
- Manage offers with images and prices in local currency
- Record sales and compute profit
- Manage exchange rates between USD and the local currency
- Generate reports and export PDF summaries
- Backup and restore the database and image files

---

### Architecture

- State Management: `flutter_bloc` with `InventoryCubit` and `InventoryState`.
- Separation of Concerns:
  - `database/db_helper.dart`: database setup and access using `sqflite`.
  - `bloc/inventory_cubit.dart`: business logic for products, sales, offers, exchange rates, cart, and categories.
  - `screens/*.dart`: UI layer using `BlocBuilder` / `context.read<InventoryCubit>()`.
  - `services/pdf_report_service.dart`: PDF report generation using the data from the Cubit.

Data flow summary:

1. UI calls Cubit methods (e.g. `addProduct`, `addOffer`, `checkoutCart`).
2. Cubit interacts with `DatabaseHelper` and emits updated `InventoryState`.
3. UI rebuilds automatically via `BlocBuilder`.

---

### Important Files

- `lib/main.dart`: App entry. Initializes `InventoryCubit` with `DatabaseHelper()` and configures themes.
- `lib/bloc/inventory_cubit.dart`: Contains `InventoryState` and `InventoryCubit` methods like `loadAll`, CRUD operations, sales, exchange rates, profit calculation, search, and cart management.
- `lib/database/db_helper.dart`: Creates `inventory.db` and provides database access.
- `lib/screens/home_screen.dart`: Main UI with a `BottomNavigationBar` for Products, Offers, and Settings.
- `lib/screens/*`: Screens for adding/editing products and offers, sales, cart, exchange rates, reports, and backup/restore.

---

### Features

- BLoC/Cubit state management
- Local storage with `sqflite`
- Image storage in `app_images` under app Documents
- Cart with batch checkout
- Dynamic product categories
- Charts using `syncfusion_flutter_charts`
- PDF generation via `pdf` and `printing`
- Backup/restore using `archive`
- RTL Arabic support with embedded Arabic fonts

---

### Run locally

1. Install the Flutter SDK
2. From the project root run:

```bash
flutter pub get
flutter run
```

Supported platforms: Android, iOS, Windows, macOS, Linux (depending on your Flutter setup).

---

### Notes and future improvements

- Replace `Get` usage with standard `Navigator` and `ScaffoldMessenger` for clearer separation.
- Use strong model classes (`Product`, `Offer`, `Sale`) instead of raw `Map<String, dynamic>` throughout the app.

# inventory_app

A Flutter inventory management starter project.

Resources:

- https://docs.flutter.dev/get-started/codelab
- https://docs.flutter.dev/cookbook
