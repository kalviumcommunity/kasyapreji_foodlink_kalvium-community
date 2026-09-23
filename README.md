# FoodLink

A mobile app that helps a non-profit coordinate food distribution across several communities during active campaigns.

Built with **Flutter + Dart**, with **Firebase** (Authentication, Cloud Firestore, Storage) as the backend.

## The Problem

A non-profit manages food distribution across several communities, but volunteer assignments and beneficiary updates are fragmented across group chats. During active campaigns, coordinators have no live count of what has been distributed and cannot reallocate supplies before shortages occur at individual sites.

## The Solution

FoodLink replaces group-chat coordination with a single real-time workspace:

- **Coordinators** see live distribution totals for each site, spot low-supply sites early, assign or reassign volunteers, and record supply reallocations.
- **Volunteers** see their current assignment, log distributions quickly from the field, and update beneficiary records for their site.

Every update goes to Cloud Firestore and reaches the coordinator dashboard straight away, so no one has to add up counts from chat messages by hand.

## Users

| Role | What they do in the app |
| --- | --- |
| Coordinator | Monitors sites, assigns volunteers, reallocates supplies, reviews beneficiary updates. |
| Volunteer | Views assignments, records distribution events and beneficiary updates. |
| Program / Operations Lead | Reviews campaign outcomes and operational status. |

Both roles use the same app. The screens a user sees depend on their role, and Firestore security rules decide what each role can read and change.

## Key Features

- Email/password sign-up and sign-in with role setup (coordinator or volunteer)
- Live campaign dashboard with distribution counts for each site
- Site list and site detail with supply status and distribution history
- Supply reallocation between sites, with confirmation and an audit record
- Distribution updates linked to site, volunteer and server timestamp
- Volunteer assignments with reassignment support
- Beneficiary records linked to campaign and site
- In-app alerts for low supply and assignment changes

## Screens

1. Splash / App Bootstrap
2. Sign In
3. Sign Up
4. Profile & Role Setup
5. Live Campaign Dashboard
6. Communities / Distribution Sites
7. Site Detail & Reallocation
8. Distribution Update
9. Volunteer Assignments
10. Beneficiaries
11. Alerts & Notifications
12. Profile & Settings

**Bottom navigation**

- Volunteer: Home · Assignments · Sites · Alerts · Profile
- Coordinator: Dashboard · Sites · Assignments · Alerts · Profile

## Tech Stack

| Layer | Technology |
| --- | --- |
| Mobile app | Flutter (stable channel), Dart |
| Authentication | Firebase Authentication |
| Database | Cloud Firestore (real-time listeners) |
| File storage | Firebase Storage |
| Local development | Firebase Emulator Suite, Android/iOS emulator |

## Data Model (Firestore)

```
users/{uid}
campaigns/{campaignId}
  ├── sites/{siteId}
  ├── assignments/{assignmentId}
  ├── beneficiaries/{beneficiaryId}
  ├── distributionEvents/{eventId}
  ├── reallocations/{reallocationId}
  └── alerts/{alertId}
```

All campaign data is stored under its `campaignId`. Distribution events are append-only: a correction is saved as a new record instead of overwriting an old one. Audit fields use server timestamps. See [PRD.md](PRD.md) for the full field list.

## Project Status

| Phase | Scope | Status |
| --- | --- | --- |
| 0 | PRD and data model | Done |
| 1 | Flutter app shell, theme, navigation, auth screens | In progress (frontend from Figma designs) |
| 2 | Campaigns, sites, assignments, beneficiaries, distribution events | Planned |
| 3 | Live dashboard, shortage rules, alerts, reallocation | Planned |
| 4 | Security rules, validation, offline/error states, device testing | Planned |
| 5 | Pilot campaign and KPI baseline measurement | Planned |

The frontend is being built first, one screen at a time from the Figma designs. The Firebase integration will follow.

## Getting Started

> The Flutter project is being set up. These steps will work once the app code is in the repository.

**Prerequisites:** Flutter SDK (stable), Dart, Android Studio or Xcode, and an emulator or physical device.

```bash
git clone https://github.com/kalviumcommunity/kasyapreji_foodlink_kalvium-community.git
cd kasyapreji_foodlink_kalvium-community
git checkout feature/mobile-app
flutter pub get
flutter run
```

Firebase setup (`flutterfire configure` and the Emulator Suite) will be documented when the backend is added.

## Documentation

- [PRD.md](PRD.md): the full product requirements, including goals, user stories, functional requirements, KPIs, risks and acceptance criteria.
