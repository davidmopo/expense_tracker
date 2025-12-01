cat > README.md << 'EOF'
# Expense Tracker Pro

A beautiful, fully functional **Flutter Expense Tracker** with:

- Add/Edit/Delete expenses
- Live search & month filtering
- Interactive pie chart (fl_chart)
- Dark mode toggle
- Export to CSV & share
- Offline-first with Hive DB
- Modern Material 3 design

## Screenshots
*(Add your own screenshots later in `/screenshots` folder)*

## Features
- Responsive: Mobile, Web (Chrome), Desktop
- Visual spending breakdown
- Smart search by title/category
- Monthly summary & filtering
- Dark/Light mode
- One-tap CSV export

## Run Locally
```bash
git clone https://github.com/davidmopo/expense_tracker.git
cd expense_tracker
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run