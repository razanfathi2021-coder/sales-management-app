# Sales Management App - Flutter & SQLite

Mobile app to manage products, customers and daily sales orders,
inspired by real sales-operations workflows.

## Features
- CRUD for products (name, price, stock) and customers (name, phone)
- Create sales orders (customer + product + quantity), stock auto-decreases
- Monthly report: orders count and revenue for the current month
- Search/filter on products and customers
- Bilingual UI (Arabic / English) with one-tap toggle
- Local storage with SQLite

## Run
```bash
flutter pub get
flutter run   # on an Android emulator/device
```

## Project structure
- `lib/main.dart` - UI: orders, products, customers, monthly report
- `lib/db_helper.dart` - SQLite database helper (CRUD + report queries)
