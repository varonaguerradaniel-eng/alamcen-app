# 📦 Warehouse Elite — B2B Inventory Management System

![Flutter](https://img.shields.io/badge/Flutter-%5E3.11.0-02569B?style=flat-square&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-%5E3.11.0-0175C2?style=flat-square&logo=dart)
![SQLite](https://img.shields.io/badge/SQLite-Offline_First-003B57?style=flat-square&logo=sqlite)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Windows%20%7C%20Linux%20%7C%20macOS-lightgrey?style=flat-square)
![Version](https://img.shields.io/badge/Version-1.0.0-success?style=flat-square)

**Warehouse Elite** is an offline-first B2B inventory management system built with **Flutter**. It is designed to digitalize, accelerate, and minimize error margins in warehouse and stock management for businesses.

You can easily perform stock entries/exits by scanning barcodes, import products in bulk via Excel, and monitor your warehouse in real-time through an advanced dashboard.

---

## ✨ Key Features

* **📱 Barcode & QR Integration:** Fast product recognition, inbound (goods receipt), and outbound (dispatch) operations using the device camera.
* **🔌 Offline-First:** All data is securely stored directly on your device using SQLite. No internet connection is required.
* **📊 Dynamic Dashboard:** View daily check-in/out statistics and receive low stock alerts.
* **📥 Bulk Excel Import:** Upload thousands of products in seconds using `.xlsx` template files.
* **📈 Profit/Loss Analysis:** Automatic profit margin calculations based on cost and sale prices.
* **🔄 Comprehensive Stock Movements:** Dedicated flows for Goods Receipt, Dispatch, Inventory Count, and Waste/Return operations.
* **💻 Cross-Platform:** Native support for Android and iOS mobile devices, as well as Windows, macOS, and Linux desktop environments.
* **🎨 Modern UI:** A user-friendly, responsive interface adhering to Material Design 3 (M3) guidelines with beautiful Glassmorphic details.

---

## 🛠️ Tech Stack

* **Framework:** [Flutter](https://flutter.dev/)
* **Language:** [Dart](https://dart.dev/)
* **Database:** `sqflite` (Mobile) & `sqflite_common_ffi` (Desktop)
* **Barcode Scanner:** `mobile_scanner`
* **File Operations:** `excel` (XLSX parsing) & `file_picker`
* **Design:** `google_fonts` (Inter), Custom Material 3 Theming

---

## 🏗️ Architecture & Project Structure

The project follows a **Layered Architecture** pattern to improve maintainability, scalability, and ease of testing.

```text
lib/
├── main.dart                 # Application entry point
├── models/                   # Data models (Product, StockMovement)
├── screens/                  # UI Screens (Dashboard, Scanner, etc.)
├── services/                 # Business logic (DatabaseHelper, ExcelImport)
├── theme/                    # Color palette and Material 3 configuration
└── widgets/                  # Reusable global UI components