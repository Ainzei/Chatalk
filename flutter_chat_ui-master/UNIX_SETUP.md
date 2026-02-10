# Running on macOS / Linux

## First Time Setup

1. Make the scripts executable:
   ```bash
   chmod +x setup.sh run.sh
   ```

2. Run the setup:
   ```bash
   ./setup.sh
   ```

## Running the App (After Setup)

```bash
./run.sh
```

Or use Flutter directly:
```bash
flutter run -d chrome
```

## Prerequisites

Make sure Flutter is installed:
- macOS: https://flutter.dev/docs/get-started/install/macos
- Linux: https://flutter.dev/docs/get-started/install/linux

## Troubleshooting

### Permission Denied
If you get "Permission denied", run:
```bash
chmod +x setup.sh run.sh
```

### Flutter Not Found
Add Flutter to your PATH by adding this to your `~/.bashrc` or `~/.zshrc`:
```bash
export PATH="$PATH:[PATH_TO_FLUTTER]/flutter/bin"
```

Then restart your terminal.
