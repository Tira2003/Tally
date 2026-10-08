# Tally

Tally is a Flutter mobile app for splitting shared trip expenses among friends.

## Development

### Requirements
- Flutter stable
- Dart bundled with Flutter
- Android Studio or another Android/iOS development environment

### Run

```bash
flutter pub get
flutter run
```

### Test

```bash
flutter test
```

## Project principles

- Simple by default, transparent on demand.
- Rs (LKR) is the default currency for the MVP.
- Expenses have independent **Payers** and **Shares** ledgers.
- Balance = total paid − total consumed.
- Settlements are separate records and never mutate original expenses.

## Repository workflow

- `main` is the stable branch.
- Use feature branches for development.
- Link commits and pull requests to the corresponding Jira ticket.
