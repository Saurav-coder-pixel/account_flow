# Toolbox

A privacy-focused, offline-first multi-tool super application built with Flutter. Toolbox brings together everyday productivity utilities into a clean, modern interface with zero tracking, zero network requirements, and complete on-device privacy.

## Included Tools

1. **Account Flow**  
   A full-featured personal and business ledger app:
   - **Personal Cashbook**: Track personal income and expenses.
   - **Account Ledger**: Track credits and debits with friends, family, or clients.
   - **Bill Splitting**: Split group expenses easily and automatically sync amounts.
   - **Built-in Expression Calculator**: Evaluate amounts directly in the input field.
   - **Multi-Currency**: Configurable currency symbols per user preference.

2. **Converters**  
   Offline conversion utilities for documents and media:
   - Image ➔ PDF (multi-image, page sizing, reordering)
   - Text ➔ PDF
   - PDF ➔ Images
   - Image format conversions (JPG, PNG, WEBP) & compression

3. **Video Player**  
   A speed-controlled local video player:
   - Variable playback speed controls (0.25x – 5x) with preset chips and continuous slider
   - Volume & brightness gestures
   - Video library browser with album filtering
   - Wake-lock retention during playback

4. **Extensible Registry**  
   Designed with a modular `ToolDefinition` registry (`lib/launcher/tool_registry.dart`) allowing new tools to be plugged in with a single entry.

## Architecture

The codebase is organized into modular features with scoped providers:

```
lib/
├── core/                       # Shared theme, constants, and utilities
├── launcher/                   # Launcher screen, tool cards, and ToolRegistry
│   ├── launcher_screen.dart
│   ├── tool_card.dart
│   └── tool_registry.dart
├── features/
│   ├── account_flow/           # Khatabook ledger (scoped providers & screens)
│   ├── converters/             # Document and image converters
│   └── video_player/           # Speed-controlled local video player
└── main.dart                   # Global theme provider and app entry point
```

## Privacy & Offline Advantages

- **100% Offline**: No network calls, analytics, or remote tracking.
- **On-Device Storage**: Data is kept securely in local SQLite databases and SharedPreferences.
- **Fast & Responsive**: Immediate interaction without waiting for network requests.

## Getting Started

1. **Install dependencies:**
   ```sh
   flutter pub get
   ```
2. **Run tests:**
   ```sh
   flutter test
   ```
3. **Run the app:**
   ```sh
   flutter run
   ```
