# CashPilot

**Your Intelligent Personal Finance Co-Pilot.**

CashPilot is a comprehensive, offline-first personal finance application built with Flutter. It helps you track expenses, manage budgets, monitor net worth, and gain insights into your financial health with advanced analytics and AI-powered features.

## 🚀 Key Features

### 💰 Financial Management

- **Accounts & Balances**: Track multiple accounts (Cash, Bank, Savings) in one place.
- **Expense Tracking**: Log expenses with categories, locations, and merchant details.
- **Budgeting**: Create and manage monthly budgets with category-specific limits.
- **Savings Goals**: Set up goals and track your progress towards them.
- **Recurring Expenses**: Manage subscriptions and recurring bills.
- **Net Worth Tracking**: Monitor assets and liabilities to see your overall financial growth.

### 📊 Analytics & Insights

- **Visual Reports**: Interactive charts and graphs for spending analysis.
- **Cash Flow Analysis**: Understand your income vs. expenses trends.
- **Category Breakdown**: See exactly where your money goes.
- **Financial Health Score**: Get a quick assessment of your financial wellbeing.

### 🤖 Intelligent Features

- **Receipt Scanning**: Automatically extract expense details from receipt photos using OCR.
- **Smart Categorization**: AI-assisted categorization of transactions.
- **Forecasting**: Predictive insights into your future spending.

### 🔗 Connectivity & Sync

- **Offline-First**: Works completely offline with local database storage (Drift).
- **Multi-Device Sync**: Seamlessly sync data across devices when online.
- **Bank Connectivity**: Import transactions directly from your bank (where supported).
- **Family Sharing**: Manage finances together with family groups.

### 🛠️ Technical Highlights

- **Cross-Platform**: Runs on Android, iOS, and Web.
- **Secure Storage**: Local encryption for sensitive data.
- **Ad-Free Experience**: (Premium tiers available for advanced features).

## 📦 Getting Started

### Prerequisites

- Flutter SDK (v3.10.8 or compatible)
- Dart SDK

### Installation

1. **Clone the repository:**

    ```bash
    git clone https://github.com/yourusername/cashpilot.git
    cd cashpilot
    ```

2. **Install dependencies:**

    ```bash
    flutter pub get
    ```

3. **Run the app:**

    ```bash
    flutter run
    ```

### Web Setup (Important)

For the web version to work correctly, specifically the database text search and worker features, the `web/` folder must contain the correct versions of `sqlite3.wasm` and `drift_worker.js` that match the `sqlite3` and `drift` package versions in `pubspec.lock`.

If you encounter `LinkError: WebAssembly.instantiate()`:

1. Check `pubspec.lock` for `sqlite3` version (e.g., 2.9.4).
2. Download the matching `sqlite3.wasm` from [sqlite3.dart releases](https://github.com/simolus3/sqlite3.dart/releases).
3. Place it in the `web/` directory.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License. Test change for pull request
