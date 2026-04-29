# Oval

A two-sided platform for booking tennis courts and organizing matches.

## App Overview

This platform serves two distinct user types:
1. **Tennis players** - who use a mobile app to book courts and invite others to play
2. **Tennis centres** - which use a web dashboard to manage their courts, calendars, and bookings

## Technology Stack

- **Flutter** - Cross-platform framework for both mobile app and web dashboard
- **Firebase Authentication** - For user authentication and management
- **Firestore** - Cloud database for storing all app data
- **Firebase Hosting** - For deploying the web dashboard
- **Cloud Functions** - For server-side logic like invitation management
- **Stripe** - Payment processing for court bookings
- **GitHub Actions** - CI/CD pipeline for automated testing and deployment

## System Architecture

### Mobile App (Player Side)
- Flutter application for iOS and Android
- Features:
  - User authentication and profile management
  - Browse available tennis courts
  - View court availability calendar
  - Book time slots
  - Invite other players
  - Manage bookings and invitations
  - Process payments

### Web Dashboard (Tennis Centre Side)
- Flutter Web application
- Features:
  - Tennis centre authentication and profile management
  - Court management (add, edit, remove)
  - Calendar and availability management
  - View and manage bookings
  - Analytics and reporting

### Backend (Firebase)
- Authentication services
- Database for user profiles, courts, bookings
- Cloud functions for:
  - Invitation management logic
  - Booking confirmation flow
  - Payment processing
  - Notification system

## Key Flows

### Booking Flow
1. Player browses available courts
2. Player selects a time slot
3. Player invites others to join (priority list)
4. Invitees receive notification and respond
5. When 2 players confirm, booking is locked and payment processed

### Invitation Logic
- One active invitation at a time
- Timeouts for responses (customizable, 15 mins to 24 hours)
- Automatic cascade to next invitee if declined or timed out
- Notification system keeps all parties informed

### Payment System
- Secure card storage through Stripe
- 50/50 split between players
- Payment processed only when two players confirm
- Tennis centre receives payment after booking is confirmed

## UI/UX Design

- **Color Scheme**:
  - Primary: White and dark green
  - Accent: Tennis ball green/yellow
- **Typography**: Google Fonts "Poppins"
- **Design Style**: Modern minimalistic aesthetic with playful elements

## Development Requirements

To set up the development environment, you'll need:
1. Flutter SDK
2. Firebase account and project setup
3. Stripe account for payment processing
4. GitHub account for version control and CI/CD

## External APIs and Keys Required

- **Firebase Configuration** - Project setup and credentials
- **Stripe API Keys** - For payment processing
- **Google Maps API Key** (optional) - For location services

## Next Steps

1. Set up development environment
2. Create Firebase project
3. Configure authentication
4. Design database schema
5. Implement core functionality
6. Integrate payment processing
7. Test and deploy
