# Account Flow

A modern, privacy-focused, offline-first ledger and expense management application built with Flutter. Account Flow helps you manage your personal finances and track money owed to and by others with ease and complete privacy.

## Why Account Flow is Different

While many financial apps move your data to the cloud and require extensive permissions, Account Flow takes a different approach. We believe your financial data is your own. Our app is designed to be a private, secure, and simple tool that works for you, without compromising on essential features or your privacy. Your data stays on your device, and the app works perfectly without an internet connection.

## Key Features

- **Separate Personal Cashbook**: Manage your own income and expenses in a dedicated personal ledger.
- **Account Ledger System**: Easily track credit (money you've given) and debit (money you've taken) with friends, family, or customers.
- **Split Expenses**: Split bills and group expenses with multiple people. The app handles all the calculations automatically to figure out who owes who.
- **Built-in Calculator**: Perform calculations directly in the amount entry field, eliminating the need to switch to a separate calculator app.
- **Automatic Balance Updates**: Balances for each person and the cashbook are updated instantly with every transaction.
- **Complete History**: View a detailed transaction and split history for each person, providing a clear record of all financial activities.
- **Clean & Simple UI**: An intuitive and clutter-free user interface that is easy to navigate and use.

## Privacy & Offline Advantages

- **100% Offline**: No internet connection required. Use the app anywhere, anytime.
- **Your Data Stays on Your Device**: All financial data is stored locally on your device. We do not collect or have access to your information.
- **No Unnecessary Permissions**: Account Flow does not require access to your contact list, phone number, or any other private information on your device.
- **Fast Performance**: Because all data is stored and processed locally, the app is incredibly fast and responsive.

## Technology Stack

- **Framework**: [Flutter](https://flutter.dev/)
- **Programming Language**: [Dart](https://dart.dev/)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Database**: Local Storage (e.g., sqflite) for on-device data persistence.

## Project Structure

The project follows a standard Flutter project structure to maintain clean and scalable code.

```
/
|- lib/
|  |- main.dart           # App entry point
|  |- models/             # Data models (Person, Transaction, etc.)
|  |- providers/          # State management logic
|  |- helpers/            # Database and other helper classes
|  |- screens/            # UI screens for different features
|  |- widgets/            # Reusable UI components
|- assets/                 # Static assets like images and icons
|- android/                # Android-specific files
|- ios/                    # iOS-specific files
|- ...                     # Other platform folders
```

## Target Users

- Individuals looking for a simple tool to track personal expenses.
- People who frequently lend or borrow money among friends and family.
- Roommates or groups who need to split household bills and expenses.
- Small business owners or freelancers who want a basic ledger for customer accounts without the complexity of full accounting software.
- Anyone who is privacy-conscious and prefers offline-first applications over cloud-based ones.

## Future Improvements

- [ ] Local data backup and restore functionality.
- [ ] Multi-currency support.
- [ ] Option to add recurring transactions.
- [ ] Export transaction history to CSV or PDF formats.
- [ ] Enhanced reporting with visual charts and graphs.

## Getting Started for Developers

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

To run this project locally:

1.  **Clone the repository:**
    ```sh
    git clone <repository-url>
    ```
2.  **Install dependencies:**
    ```sh
    flutter pub get
    ```
3.  **Run the app:**
    ```sh
    flutter run
    ```
