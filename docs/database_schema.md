# Database Schema

This document outlines the database structure for the Oval using Firestore.

## Collections and Documents

### Users Collection

**Collection**: `users`

**Document ID**: `{userId}` (Firebase Auth UID)

**Fields**:
- `email`: String - User's email address
- `displayName`: String - User's display name
- `phoneNumber`: String - User's phone number
- `profileImageUrl`: String - URL to profile image
- `createdAt`: Timestamp - Account creation date
- `stripeCustomerId`: String - ID for Stripe customer
- `paymentMethods`: Array - List of saved payment methods
- `playerLevel`: String - Self-assessed playing level (Beginner, Intermediate, Advanced, Pro)
- `preferredPlayTimes`: Array - Preferred days/times to play
- `preferredLocations`: Array - Preferred tennis centers

**Sub-Collections**:
- `bookings` - User's bookings
- `invitations` - Invitations sent and received
- `contacts` - User's tennis contacts and priority list

### Tennis Centers Collection

**Collection**: `tennisCenters`

**Document ID**: `{centerId}` (Firebase Auth UID)

**Fields**:
- `name`: String - Tennis center name
- `address`: Map - Address details
  - `street`: String
  - `city`: String
  - `state`: String
  - `zipCode`: String
  - `country`: String
- `location`: GeoPoint - Coordinates for map display
- `phoneNumber`: String - Contact phone
- `email`: String - Contact email
- `website`: String - Center website
- `description`: String - About the center
- `amenities`: Array - Available amenities
- `operatingHours`: Map - Opening hours
- `images`: Array - Image URLs
- `stripeAccountId`: String - Stripe connected account ID
- `createdAt`: Timestamp

**Sub-Collections**:
- `courts` - Tennis courts at this center

### Courts Sub-Collection

**Collection**: `tennisCenters/{centerId}/courts`

**Document ID**: `{courtId}` (auto-generated)

**Fields**:
- `name`: String - Court name/number
- `surface`: String - Court surface type
- `indoor`: Boolean - Whether court is indoor
- `hourlyRate`: Number - Cost per hour
- `availability`: Map - Standard availability
- `images`: Array - Court images
- `features`: Array - Special features

**Sub-Collections**:
- `availability` - Available time slots

### Availability Sub-Collection

**Collection**: `tennisCenters/{centerId}/courts/{courtId}/availability`

**Document ID**: `{date}_{timeSlot}` (e.g., "2023-06-15_09:00-10:00")

**Fields**:
- `date`: String - Date in YYYY-MM-DD format
- `startTime`: String - Start time in 24hr format
- `endTime`: String - End time in 24hr format
- `status`: String - "available", "booked", "pending", "maintenance"
- `price`: Number - Price for this specific slot (can override hourly rate)
- `specialEvent`: Boolean - Whether this is a special event
- `maxPlayers`: Number - Maximum number of players allowed (default 2)
- `bookingId`: String - Reference to booking if status is "booked" or "pending"

### Bookings Collection

**Collection**: `bookings`

**Document ID**: `{bookingId}` (auto-generated)

**Fields**:
- `courtId`: String - Reference to court
- `tennisCenter`: String - Reference to tennis center
- `date`: String - Booking date
- `startTime`: String - Start time
- `endTime`: String - End time
- `creatorId`: String - User who created the booking
- `inviteeId`: String - User who accepted the invitation
- `status`: String - "pending", "confirmed", "cancelled"
- `paymentStatus`: String - "pending", "partial", "complete"
- `creatorPaymentId`: String - Stripe payment ID for creator
- `inviteePaymentId`: String - Stripe payment ID for invitee
- `totalAmount`: Number - Total booking amount
- `amountPerPlayer`: Number - Amount per player
- `createdAt`: Timestamp
- `confirmedAt`: Timestamp

### Invitations Collection

**Collection**: `invitations`

**Document ID**: `{invitationId}` (auto-generated)

**Fields**:
- `bookingId`: String - Reference to pending booking
- `creatorId`: String - User who created the booking
- `inviteeId`: String - User invited to join
- `status`: String - "pending", "accepted", "declined", "expired"
- `createdAt`: Timestamp - When invitation was sent
- `expiresAt`: Timestamp - When invitation will expire
- `respondedAt`: Timestamp - When invited user responded
- `priority`: Number - Position in priority list
- `message`: String - Optional message from creator

## Data Relationships

1. **User → Bookings**: One-to-many relationship
2. **User → Invitations**: One-to-many relationship
3. **Tennis Center → Courts**: One-to-many relationship
4. **Court → Availability Slots**: One-to-many relationship
5. **Booking → Court**: Many-to-one relationship
6. **Booking → Invitation**: One-to-many relationship

## Security Considerations

- Users can only modify their own data
- Tennis centers can only modify their own courts and availability
- Bookings can be modified by participating users and the tennis center
- Invitations can be created by any user but can only be accepted by the invitee

## Example Queries

### Find Available Courts
```dart
// Find all courts available on a specific date and time
FirebaseFirestore.instance
    .collectionGroup('availability')
    .where('date', isEqualTo: 'YYYY-MM-DD')
    .where('startTime', isEqualTo: 'HH:MM')
    .where('status', isEqualTo: 'available')
    .get()
```

### Get User's Active Bookings
```dart
// Get all active bookings for a user
FirebaseFirestore.instance
    .collection('bookings')
    .where('creatorId', isEqualTo: userId)
    .where('status', isEqualTo: 'confirmed')
    .where('date', isGreaterThanOrEqualTo: 'YYYY-MM-DD') // today's date
    .orderBy('date')
    .orderBy('startTime')
    .get()
```

### Check Pending Invitations
```dart
// Check if user has any pending invitations
FirebaseFirestore.instance
    .collection('invitations')
    .where('inviteeId', isEqualTo: userId)
    .where('status', isEqualTo: 'pending')
    .orderBy('createdAt', descending: true)
    .get()
```
