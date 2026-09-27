# AttendEase

An attendance tracker app initially made for my own use — but why not share it.

## Features

- Track daily attendance across multiple subjects/classes
- Build and manage weekly timetables, including support for multiple timetables (e.g. per semester) and archiving old ones
- Mark attendance as Present, Late, or Absent, with custom point weighting for late arrivals
- View attendance statistics overall and broken down per subject
- Bunk predictor: see how many classes you can safely skip while staying above your minimum attendance threshold
- Goal tracker: see how many classes you need to attend to reach a target attendance percentage
- Holiday support, including public holidays and custom/weekly holidays that pause attendance tracking
- Class reminders and missed-class notifications
- Light and dark themes with selectable accent colors
- Backup and restore your data locally

## Getting Started

1. Clone the repository:
```bash
   git clone https://github.com/obhirup/AttendEase.git
   cd AttendEase
```

2. Install dependencies:
```bash
   flutter pub get
```

3. Run the app:
```bash
   flutter run
```

## Built With

- [Flutter](https://flutter.dev/)
- [provider](https://pub.dev/packages/provider) — state management
- [shared_preferences](https://pub.dev/packages/shared_preferences) — local storage
- [intl](https://pub.dev/packages/intl) — date formatting

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
