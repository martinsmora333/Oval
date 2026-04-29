# Oval: Key Workflows

This document describes the core workflows and user journeys in the Oval.

## 1. Player Registration Process

```mermaid
sequenceDiagram
    participant User
    participant App
    participant Firebase Auth
    participant Firestore
    participant Stripe

    User->>App: Opens app for first time
    App->>User: Shows onboarding screens
    User->>App: Taps "Sign Up"
    App->>User: Shows registration form
    User->>App: Completes form and submits
    App->>Firebase Auth: Create new user
    Firebase Auth->>App: Returns user ID
    App->>Firestore: Create user profile
    App->>Stripe: Create Stripe customer
    Stripe->>App: Returns Stripe customer ID
    App->>Firestore: Save Stripe customer ID
    App->>User: Shows profile setup screen
    User->>App: Completes profile (level, preferences)
    App->>Firestore: Save player preferences
    App->>User: Shows add payment method screen
    User->>App: Adds payment method
    App->>Stripe: Save payment method
    App->>User: Shows app home screen
```

## 2. Tennis Center Registration Process

```mermaid
sequenceDiagram
    participant Admin
    participant Dashboard
    participant Firebase Auth
    participant Firestore
    participant Stripe

    Admin->>Dashboard: Visits web dashboard
    Dashboard->>Admin: Shows registration form
    Admin->>Dashboard: Completes form and submits
    Dashboard->>Firebase Auth: Create new account
    Firebase Auth->>Dashboard: Returns center ID
    Dashboard->>Firestore: Create tennis center profile
    Dashboard->>Stripe: Create Stripe connected account
    Stripe->>Dashboard: Returns account link
    Dashboard->>Admin: Redirects to Stripe onboarding
    Admin->>Stripe: Completes Stripe onboarding
    Stripe->>Dashboard: Webhook notification
    Dashboard->>Firestore: Update Stripe account status
    Dashboard->>Admin: Shows court setup screen
    Admin->>Dashboard: Adds courts and availability
    Dashboard->>Firestore: Save courts and availability
    Dashboard->>Admin: Shows dashboard home
```

## 3. Court Booking and Invitation Flow

```mermaid
sequenceDiagram
    participant Player
    participant App
    participant Firestore
    participant Functions
    participant Invitee
    participant Stripe

    Player->>App: Searches for available courts
    App->>Firestore: Query available courts
    Firestore->>App: Returns available courts
    Player->>App: Selects court and time slot
    App->>Firestore: Creates pending booking
    Player->>App: Creates priority invitation list
    App->>Firestore: Saves invitation with priority
    Firestore->>Functions: Trigger invitation function
    Functions->>Invitee: Sends invitation notification
    Invitee->>App: Views invitation
    Invitee->>App: Accepts invitation
    App->>Firestore: Updates invitation status
    Firestore->>Functions: Trigger booking confirmation
    Functions->>Stripe: Process payments (both players)
    Stripe->>Functions: Payment confirmation
    Functions->>Firestore: Update booking as confirmed
    Functions->>Player: Send booking confirmation
    Functions->>Invitee: Send booking confirmation
```

## 4. Invitation Timeout and Cascade Flow

```mermaid
sequenceDiagram
    participant Invitee1
    participant App
    participant Functions
    participant Firestore
    participant Invitee2

    Note over Invitee1,Firestore: Invitation sent to first priority player
    
    Functions->>Functions: Scheduled timeout check
    Functions->>Firestore: Check invitation status
    Firestore->>Functions: Status "pending", past expiry time
    Functions->>Firestore: Update invitation status to "expired"
    Functions->>Firestore: Get next invitee from priority list
    Firestore->>Functions: Returns next invitee (Invitee2)
    Functions->>Firestore: Create new invitation for Invitee2
    Functions->>Invitee2: Send invitation notification
    Invitee2->>App: Views invitation
    Invitee2->>App: Accepts invitation
    App->>Firestore: Updates invitation status
    Firestore->>Functions: Trigger booking confirmation
```

## 5. Tennis Center Court Management Flow

```mermaid
sequenceDiagram
    participant Admin
    participant Dashboard
    participant Firestore
    
    Admin->>Dashboard: Logs into web dashboard
    Dashboard->>Firestore: Fetch center data
    Firestore->>Dashboard: Returns center data
    Admin->>Dashboard: Navigates to court management
    Dashboard->>Firestore: Fetch courts
    Firestore->>Dashboard: Returns courts
    Admin->>Dashboard: Adds new court
    Dashboard->>Firestore: Save new court
    Admin->>Dashboard: Sets court availability
    Dashboard->>Firestore: Save court availability
    Admin->>Dashboard: Views booking calendar
    Dashboard->>Firestore: Fetch bookings
    Firestore->>Dashboard: Returns bookings
    Admin->>Dashboard: Modifies a time slot
    Dashboard->>Firestore: Update availability
```

## 6. Payment Processing Flow

```mermaid
sequenceDiagram
    participant Player1
    participant Player2
    participant Functions
    participant Stripe
    participant TennisCenter
    
    Functions->>Stripe: Create payment intent for Player1
    Stripe->>Functions: Returns payment intent
    Functions->>Stripe: Create payment intent for Player2
    Stripe->>Functions: Returns payment intent
    Functions->>Player1: Request payment confirmation
    Functions->>Player2: Request payment confirmation
    Player1->>Stripe: Confirm payment
    Player2->>Stripe: Confirm payment
    Stripe->>Functions: Webhook: both payments successful
    Functions->>Stripe: Transfer to tennis center (minus platform fee)
    Stripe->>TennisCenter: Payment received
    Functions->>Firestore: Update booking payment status
```

## 7. Booking Cancellation Flow

```mermaid
sequenceDiagram
    participant Player
    participant App
    participant Firestore
    participant Functions
    participant Stripe
    
    Player->>App: Views upcoming bookings
    App->>Firestore: Fetch bookings
    Firestore->>App: Returns bookings
    Player->>App: Selects booking to cancel
    App->>Player: Shows cancellation policy
    Player->>App: Confirms cancellation
    App->>Firestore: Update booking status
    Firestore->>Functions: Trigger cancellation function
    Functions->>Firestore: Check cancellation policy
    Functions->>Stripe: Process refund (if applicable)
    Stripe->>Functions: Refund confirmation
    Functions->>Firestore: Update payment status
    Functions->>Player: Send cancellation confirmation
```

## 8. User Feedback and Rating Flow

```mermaid
sequenceDiagram
    participant Player
    participant App
    participant Firestore
    
    Player->>App: Views past bookings
    App->>Firestore: Fetch completed bookings
    Firestore->>App: Returns bookings
    Player->>App: Selects booking to rate
    App->>Player: Shows rating form
    Player->>App: Submits rating and feedback
    App->>Firestore: Save rating to booking
    App->>Firestore: Update court rating average
    App->>Firestore: Update tennis center rating
    App->>Player: Shows confirmation
```

## 9. Notification System

```mermaid
sequenceDiagram
    participant Functions
    participant Firebase Messaging
    participant Player App
    participant TennisCenter Dashboard
    
    Functions->>Firebase Messaging: Send invitation notification
    Firebase Messaging->>Player App: Deliver notification
    Functions->>Firebase Messaging: Send booking confirmation
    Firebase Messaging->>Player App: Deliver notification
    Firebase Messaging->>TennisCenter Dashboard: Deliver notification
    Functions->>Firebase Messaging: Send reminder (24h before)
    Firebase Messaging->>Player App: Deliver notification
```

## 10. Tennis Center Analytics Dashboard

```mermaid
flowchart TB
    A[Dashboard Home] --> B[Bookings Overview]
    A --> C[Revenue Analytics]
    A --> D[Court Utilization]
    A --> E[Customer Insights]
    
    B --> B1[Daily View]
    B --> B2[Weekly View]
    B --> B3[Monthly View]
    
    C --> C1[Revenue by Court]
    C --> C2[Revenue by Time]
    C --> C3[Payment History]
    
    D --> D1[Heat Map]
    D --> D2[Usage Statistics]
    D --> D3[Availability Management]
    
    E --> E1[Regular Players]
    E --> E2[Ratings & Feedback]
    E --> E3[Player Demographics]
```
