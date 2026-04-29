# Firebase Setup Guide

This document outlines the steps to set up Firebase for the Oval.

## Step 1: Create a Firebase Project

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project"
3. Enter project name: "Oval"
4. Enable Google Analytics (optional but recommended)
5. Create project

## Step 2: Register Your Apps

### Mobile App
1. In the Firebase console, click "Add app" and select iOS and Android
2. For iOS:
   - Bundle ID: `com.tennismatch.mobileapp`
   - Download the `GoogleService-Info.plist` file
   - Place it in the iOS folder of your Flutter project
3. For Android:
   - Package name: `com.tennismatch.mobileapp`
   - Download the `google-services.json` file
   - Place it in the Android/app folder of your Flutter project

### Web Dashboard
1. In the Firebase console, click "Add app" and select Web
2. App nickname: "Oval Dashboard"
3. Register app
4. Copy the Firebase configuration

## Step 3: Enable Required Services

### Authentication
1. Go to Authentication in the Firebase console
2. Enable the following sign-in methods:
   - Email/Password
   - Google Sign-In (optional)
   - Phone (optional)

### Firestore Database
1. Go to Firestore Database in the Firebase console
2. Create database
3. Start in production mode
4. Choose a location closest to your target users

### Firebase Hosting
1. Go to Hosting in the Firebase console
2. Click "Get started"
3. Follow the setup instructions

### Firebase Storage
1. Go to Storage in the Firebase console
2. Click "Get started"
3. Set up storage rules

## Step 4: Set Up Firebase Cloud Functions

1. Go to Functions in the Firebase console
2. Click "Get started"
3. Set up Node.js environment
4. Define functions for:
   - Invitation management
   - Booking confirmation
   - Payment processing
   - Notification system

## Step 5: Set Up Firebase Security Rules

### Firestore Rules
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Tennis Centers can only modify their own data
    match /tennisCenters/{centerId} {
      allow read;
      allow write: if request.auth != null && request.auth.uid == centerId;
      
      // Courts can be modified by their owner tennis center
      match /courts/{courtId} {
        allow read;
        allow write: if request.auth != null && request.auth.uid == centerId;
        
        // Availability slots can be read by anyone, modified by tennis center
        match /availability/{slotId} {
          allow read;
          allow write: if request.auth != null && request.auth.uid == centerId;
        }
      }
    }
    
    // Users can only modify their own data
    match /users/{userId} {
      allow read;
      allow write: if request.auth != null && request.auth.uid == userId;
      
      // Bookings can be modified by participants
      match /bookings/{bookingId} {
        allow read;
        allow create: if request.auth != null;
        allow update, delete: if request.auth != null && 
          (request.auth.uid == resource.data.creatorId || 
           request.auth.uid == resource.data.inviteeId ||
           request.auth.uid == resource.data.tennisCenter);
      }
      
      // Invitations can be created by any user, but only accepted by invitee
      match /invitations/{invitationId} {
        allow read;
        allow create: if request.auth != null;
        allow update: if request.auth != null && 
          (request.auth.uid == resource.data.creatorId || 
           request.auth.uid == resource.data.inviteeId);
        allow delete: if request.auth != null && request.auth.uid == resource.data.creatorId;
      }
    }
  }
}
```

### Storage Rules
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /tennisCenters/{centerId}/{allPaths=**} {
      allow read;
      allow write: if request.auth != null && request.auth.uid == centerId;
    }
    
    match /courts/{courtId}/{allPaths=**} {
      allow read;
      allow write: if request.auth != null && 
        (request.resource.metadata.ownerId == request.auth.uid);
    }
  }
}
```

## Step 6: Set Up Stripe Integration

1. Create a Stripe account
2. Get API keys (publishable and secret)
3. Set up webhook endpoints
4. Configure Firebase Cloud Functions to handle Stripe events

## Required API Keys (store these securely)

1. Firebase Web API Key: From Firebase console
2. Stripe Publishable Key: From Stripe Dashboard
3. Stripe Secret Key: From Stripe Dashboard (keep this secure)
4. Google Maps API Key (optional): For location services
