# Voice Management System

Voice Management is a comprehensive, offline-first Flutter application designed for managing communities, specifically tailored for the Vedic Oasis community (VOICE). It streamlines member management, task assignment, meal planning, and leave requests.

## 🌟 Key Features

- **Offline-First Architecture**: Built with Drift (SQLite) and a custom Sync Engine. The app works flawlessly without an internet connection and syncs data to Supabase in the background when connectivity is restored.
- **Member Management**: Track members, roles, permissions, and statuses.
- **Task Delegation**: Assign tasks to members, track completion, and manage task boards.
- **Leave & Meal Planning**: Automated meal plan generation based on leave requests (e.g., auto-marking "Not Eating" when a member is away).
- **In-App Updater**: Built-in system to distribute APK updates directly via Supabase Storage, bypassing the Play Store for internal distribution.
- **Realtime Sync**: Powered by Supabase Realtime for instant updates across all devices.

## 🛠️ Technology Stack

- **Frontend Framework**: Flutter (Dart)
- **State Management**: Riverpod (`flutter_riverpod`)
- **Local Database**: Drift (SQLite)
- **Backend & Cloud Database**: Supabase (PostgreSQL, Auth, Storage, Realtime)
- **Networking**: Supabase Flutter SDK & Dio (for APK downloads)

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `^3.11.3`
- Supabase Project (Database, Storage)

### Setup Supabase

1. Create a new Supabase project.
2. Go to the **SQL Editor** in your Supabase dashboard.
3. Run the complete schema found in `supabase_schema_full.sql` (this sets up all tables, RLS policies, and the `app_versions` table for updates).
4. Go to **Storage** and create a public bucket named `apk-releases`.

### Run the App

1. Clone the repository.
2. Navigate to the `voice_app` directory.
3. Run `flutter pub get` to install dependencies.
4. Set up your `.env` file (or `SupabaseConfig`) with your Supabase URL and Anon Key.
5. Run `flutter run`.

## 📦 In-App Updater

The app includes a custom OTA (Over-The-Air) updater for Android. 
To distribute a new version:
1. Build your APK: `flutter build apk`
2. Upload the APK to your Supabase `apk-releases` storage bucket.
3. Insert a new row into the `app_versions` table in your Supabase database with a higher `build_number`.
4. Users will automatically be prompted to update upon their next app launch!

## 🔐 Authentication

Currently, the app uses a PIN-based authentication system backed by the `members` table in Supabase. 
- **Initial Setup**: The local database automatically seeds an initial Admin (`VO-001` / PIN `1234`) on first run. 
- You can add more members via the app interface or by importing data.

## 📄 License
Internal use only.
