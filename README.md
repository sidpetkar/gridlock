# Gridlock

A strategic word-building game built with Flutter. Compete against an AI opponent to create intersecting words on an expanding grid.

## Features

- 🎮 Play against AI or local 2-player mode
- 📱 **Mobile-first design** - optimized for smartphones with touch-friendly interface
- 💻 Responsive layout for desktop and mobile
- 🎯 Strategic gameplay with scoring system
- 💡 Built-in hint system (offline ghost hints + AI hints)
- 🎨 Multiple color themes
- 🌐 Progressive Web App (PWA) - installable on mobile devices

## Play Online

[Play Gridlock](https://your-deployment-url.com) - Works on desktop and mobile!

## Mobile Experience

The game features a **mobile-first interface** with:
- Large, easy-to-read scores at the top
- Touch-optimized grid that fits your screen
- Bottom sheet keyboard for word input
- No scrolling required - everything fits on one screen
- 4 large action buttons (Submit, Pass, Ghost hint, AI hint)
- Compact moves history
- PWA support for installing as a native app

See [MOBILE_UPDATES.md](MOBILE_UPDATES.md) for detailed mobile features.

## How to Play

Read the comprehensive [Game Guide](GAME_GUIDE.md) to learn the rules, strategy, and tips for winning.

## Development

### Prerequisites

- Flutter SDK (3.8.0 or higher)
- Dart SDK

### Running the App

```bash
# Get dependencies
flutter pub get

# Run on web (desktop browser)
flutter run -d chrome

# Run on mobile device
flutter run

# Build for production
flutter build web --release
```

See [BUILDING_MOBILE.md](BUILDING_MOBILE.md) for detailed build and deployment instructions.

## Project Structure

```
lib/
├── features/game/
│   ├── application/      # Game controller and state management
│   ├── domain/          # Game logic (board, moves, scoring)
│   └── presentation/    # UI (screens and widgets)
├── services/           # Dictionary and AI hint services
└── theme/             # App theme configuration
```

## Documentation

- [GAME_GUIDE.md](GAME_GUIDE.md) - Complete game rules and strategy guide
- [MOBILE_UPDATES.md](MOBILE_UPDATES.md) - Mobile-first design details
- [BUILDING_MOBILE.md](BUILDING_MOBILE.md) - Build and deployment guide
- [LAYOUT_COMPARISON.md](LAYOUT_COMPARISON.md) - Before/after mobile layout comparison

## License

MIT License - feel free to use and modify!
