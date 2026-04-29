# UI Design Guidelines

This document outlines the design principles and UI guidelines for the Oval.

## Brand Colors

```
PRIMARY_DARK_GREEN = #1A5D1A
PRIMARY_WHITE = #FFFFFF
ACCENT_TENNIS_BALL = #D6ED17
SECONDARY_LIGHT_GREEN = #4CAF50
BACKGROUND_LIGHT = #F5F5F5
TEXT_DARK = #212121
TEXT_LIGHT = #FFFFFF
ERROR_RED = #E53935
SUCCESS_GREEN = #43A047
COURT_BLUE = #1E88E5
```

## Typography

Font Family: **Poppins** (Google Fonts)

Weights:
- Light (300)
- Regular (400)
- Medium (500)
- SemiBold (600)
- Bold (700)

Text Sizes:
- Display Large: 34px
- Display Medium: 28px
- Display Small: 24px
- Headline: 20px
- Title: 18px
- Body Large: 16px
- Body: 14px
- Caption: 12px

## Design System

### Buttons

**Primary Button**
- Background: PRIMARY_DARK_GREEN
- Text: PRIMARY_WHITE
- Border Radius: 8px
- Height: 48px
- Font: Poppins Medium, 16px

**Secondary Button**
- Background: Transparent
- Border: 2px solid PRIMARY_DARK_GREEN
- Text: PRIMARY_DARK_GREEN
- Border Radius: 8px
- Height: 48px
- Font: Poppins Medium, 16px

**Accent Button**
- Background: ACCENT_TENNIS_BALL
- Text: TEXT_DARK
- Border Radius: 8px
- Height: 48px
- Font: Poppins Medium, 16px

**Icon Button**
- Size: 48px x 48px
- Border Radius: 24px
- Icon Size: 24px

### Cards

**Standard Card**
- Background: PRIMARY_WHITE
- Border Radius: 12px
- Elevation: 2dp
- Padding: 16px
- Shadow: 0px 2px 4px rgba(0, 0, 0, 0.1)

**Court Card**
- Background: PRIMARY_WHITE
- Border Radius: 12px
- Elevation: 2dp
- Image Height: 160px
- Padding: 0px (image), 16px (content)
- Shadow: 0px 2px 4px rgba(0, 0, 0, 0.1)

**Booking Card**
- Background: PRIMARY_WHITE
- Border Radius: 12px
- Elevation: 2dp
- Left Border: 4px (color indicates status)
- Padding: 16px
- Shadow: 0px 2px 4px rgba(0, 0, 0, 0.1)

### Input Fields

**Text Input**
- Background: PRIMARY_WHITE
- Border: 1px solid #E0E0E0
- Border Radius: 8px
- Height: 56px
- Padding: 16px
- Font: Poppins Regular, 16px
- Focus Border: PRIMARY_DARK_GREEN

**Dropdown**
- Background: PRIMARY_WHITE
- Border: 1px solid #E0E0E0
- Border Radius: 8px
- Height: 56px
- Padding: 16px
- Font: Poppins Regular, 16px
- Focus Border: PRIMARY_DARK_GREEN

**Calendar Input**
- Background: PRIMARY_WHITE
- Border: 1px solid #E0E0E0
- Border Radius: 8px
- Height: 56px
- Padding: 16px
- Font: Poppins Regular, 16px
- Selected Date Background: ACCENT_TENNIS_BALL

### Navigation

**Bottom Navigation (Mobile App)**
- Background: PRIMARY_WHITE
- Selected Icon Color: PRIMARY_DARK_GREEN
- Unselected Icon Color: #757575
- Icon Size: 24px
- Text: Poppins Medium, 12px
- Height: 56px

**Sidebar Navigation (Web Dashboard)**
- Background: PRIMARY_DARK_GREEN
- Text Color: PRIMARY_WHITE
- Selected Item Background: rgba(255, 255, 255, 0.1)
- Icon Size: 24px
- Text: Poppins Medium, 14px
- Width: 240px

### Status Indicators

**Booking Status Colors**
- Available: SUCCESS_GREEN
- Pending: #FFC107 (Amber)
- Booked: PRIMARY_DARK_GREEN
- Maintenance: #757575 (Grey)
- Expired: #9E9E9E (Light Grey)
- Cancelled: ERROR_RED

**Progress Indicators**
- Loading Spinner Color: PRIMARY_DARK_GREEN
- Progress Bar Color: ACCENT_TENNIS_BALL
- Background: #E0E0E0
- Height: 4px

## UI Mockups

### Mobile App Screens

#### 1. Player Home Screen

```
┌─────────────────────────────────┐
│ [Profile] Oval   [Bell] │
├─────────────────────────────────┤
│                                 │
│  ┌───────────────────────────┐  │
│  │ Find a Court              │  │
│  │ ┌─────────┐ ┌───────────┐ │  │
│  │ │ Date    │ │ Time      │ │  │
│  │ └─────────┘ └───────────┘ │  │
│  │ ┌───────────────────────┐ │  │
│  │ │ Search                │ │  │
│  │ └───────────────────────┘ │  │
│  └───────────────────────────┘  │
│                                 │
│  Upcoming Matches               │
│  ┌───────────────────────────┐  │
│  │ [Tennis Ball Icon]        │  │
│  │ Central Courts            │  │
│  │ Tomorrow • 3:00 - 4:00 PM │  │
│  │ with Alex Rodriguez       │  │
│  │ [CONFIRMED]               │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │ [Tennis Ball Icon]        │  │
│  │ Riverside Tennis          │  │
│  │ Friday • 5:30 - 6:30 PM   │  │
│  │ with Sarah Johnson        │  │
│  │ [PENDING]                 │  │
│  └───────────────────────────┘  │
│                                 │
│  Recent Courts                  │
│  ┌───────┐ ┌───────┐ ┌───────┐  │
│  │ Court │ │ Court │ │ Court │  │
│  │  #1   │ │  #2   │ │  #3   │  │
│  └───────┘ └───────┘ └───────┘  │
│                                 │
├─────────────────────────────────┤
│ [Home] [Calendar] [Bookings] [] │
└─────────────────────────────────┘
```

#### 2. Court Selection Screen

```
┌─────────────────────────────────┐
│ ← Courts Near You        [Map]  │
├─────────────────────────────────┤
│  ┌───────────────────────────┐  │
│  │ ┌─────┐ ┌────┐ ┌────────┐ │  │
│  │ │Today│ │9 AM│ │ Filter │ │  │
│  │ └─────┘ └────┘ └────────┘ │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │ [Court Image]             │  │
│  │ Central Tennis Club       │  │
│  │ ⭐⭐⭐⭐☆ (4.2)             │  │
│  │ Clay • Indoor             │  │
│  │ 3 courts available        │  │
│  │ $25/hour                  │  │
│  │ 1.2 miles away            │  │
│  │ [BOOK NOW]                │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │ [Court Image]             │  │
│  │ Riverside Tennis Center   │  │
│  │ ⭐⭐⭐⭐⭐ (4.8)             │  │
│  │ Hard • Outdoor            │  │
│  │ 5 courts available        │  │
│  │ $30/hour                  │  │
│  │ 2.5 miles away            │  │
│  │ [BOOK NOW]                │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │ [Court Image]             │  │
│  │ Community Tennis Park     │  │
│  │ ⭐⭐⭐☆☆ (3.1)             │  │
│  │ Hard • Outdoor            │  │
│  │ 2 courts available        │  │
│  │ $15/hour                  │  │
│  │ 3.8 miles away            │  │
│  │ [BOOK NOW]                │  │
│  └───────────────────────────┘  │
│                                 │
└─────────────────────────────────┘
```

#### 3. Court Calendar Screen

```
┌─────────────────────────────────┐
│ ← Central Tennis Club           │
├─────────────────────────────────┤
│  [Court Image]                  │
│  Court #3 • Clay • Indoor       │
│  ⭐⭐⭐⭐☆ (4.2)                │
│                                 │
│  ┌───────────────────────────┐  │
│  │ April 2025                │  │
│  │ ◀ [Calendar Week View] ▶  │  │
│  └───────────────────────────┘  │
│                                 │
│  Available Times                │
│  ┌───────┐ ┌───────┐ ┌───────┐  │
│  │ 9:00  │ │ 10:00 │ │ 11:00 │  │
│  │ -10:00│ │ -11:00│ │ -12:00│  │
│  │ $25   │ │ $25   │ │ $25   │  │
│  └───────┘ └───────┘ └───────┘  │
│  ┌───────┐ ┌───────┐ ┌───────┐  │
│  │ 12:00 │ │ 1:00  │ │ 2:00  │  │
│  │ -1:00 │ │ -2:00 │ │ -3:00 │  │
│  │ $25   │ │ $30   │ │ $30   │  │
│  └───────┘ └───────┘ └───────┘  │
│  ┌───────┐ ┌───────┐ ┌───────┐  │
│  │ 3:00  │ │ 4:00  │ │ 5:00  │  │
│  │ -4:00 │ │ -5:00 │ │ -6:00 │  │
│  │ $30   │ │ $30   │ │ $35   │  │
│  └───────┘ └───────┘ └───────┘  │
│                                 │
│  [BOOK SELECTED TIME]           │
│                                 │
└─────────────────────────────────┘
```

#### 4. Invite Players Screen

```
┌─────────────────────────────────┐
│ ← Invite Players                │
├─────────────────────────────────┤
│  Booking Details                │
│  Central Tennis Club            │
│  Court #3 • Today               │
│  5:00 PM - 6:00 PM              │
│  $17.50 per player              │
│                                 │
│  Invitation Order               │
│  Drag to reorder priority       │
│                                 │
│  ┌───────────────────────────┐  │
│  │ 1. [Profile Pic] Sarah    │  │
│  │    Advanced • 80% accept  │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │ 2. [Profile Pic] Alex     │  │
│  │    Intermediate • 65%     │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │ 3. [Profile Pic] Jamie    │  │
│  │    Advanced • 45%         │  │
│  └───────────────────────────┘  │
│                                 │
│  [+ ADD MORE PLAYERS]           │
│                                 │
│  Response Time                  │
│  ┌───────────────────┐          │
│  │ 2 hours        ▼ │          │
│  └───────────────────┘          │
│                                 │
│  [CONFIRM & SEND INVITATIONS]   │
│                                 │
└─────────────────────────────────┘
```

### Web Dashboard Screens

#### 1. Tennis Center Dashboard Home

```
┌─────────────────────────────────────────────────────────────────┐
│ Oval            [Notifications] [Profile]      │
├────────────┬────────────────────────────────────────────────────┤
│            │                                                    │
│  Tennis    │  Dashboard Overview                               │
│  Match     │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌───────┐ │
│            │  │ 24       │ │ $1,250   │ │ 82%      │ │ 4.7/5 │ │
│ ┌──────────┤  │ Bookings │ │ Revenue  │ │ Courts   │ │ User  │ │
│ │ Dashboard│  │ Today    │ │ This Week│ │ Occupied │ │ Rating│ │
│ ├──────────┤  └──────────┘ └──────────┘ └──────────┘ └───────┘ │
│ │ Courts   │                                                    │
│ ├──────────┤  Today's Bookings                                  │
│ │ Calendar │  ┌──────────────────────────────────────────────┐ │
│ ├──────────┤  │ Time    │ Court  │ Players        │ Status  │ │
│ │ Bookings │  ├─────────┼────────┼────────────────┼─────────┤ │
│ ├──────────┤  │ 9:00 AM │ Court 1│ John & Sarah   │ Checked │ │
│ │ Customers│  ├─────────┼────────┼────────────────┼─────────┤ │
│ ├──────────┤  │ 10:00 AM│ Court 3│ Mike & David   │ Confirmed│ │
│ │ Analytics│  ├─────────┼────────┼────────────────┼─────────┤ │
│ ├──────────┤  │ 11:00 AM│ Court 2│ Emma & Alex    │ Confirmed│ │
│ │ Settings │  ├─────────┼────────┼────────────────┼─────────┤ │
│ └──────────┤  │ 1:00 PM │ Court 1│ Lisa & Robert  │ Pending │ │
│            │  ├─────────┼────────┼────────────────┼─────────┤ │
│            │  │ 3:00 PM │ Court 2│ James & Sophia │ Confirmed│ │
│            │  ├─────────┼────────┼────────────────┼─────────┤ │
│            │  │ 5:00 PM │ Court 1│ Thomas & Nina  │ Confirmed│ │
│            │  └──────────────────────────────────────────────┘ │
│            │                                                    │
│            │  Court Utilization                                 │
│            │  ┌──────────────────────────────────────────────┐ │
│            │  │ [Bar Chart showing hourly court utilization] │ │
│            │  └──────────────────────────────────────────────┘ │
│            │                                                    │
│            │  Recent Notifications                              │
│            │  ┌──────────────────────────────────────────────┐ │
│            │  │ • New booking confirmed for Court 3 at 7PM   │ │
│            │  │ • Maintenance for Court 2 scheduled tomorrow │ │
│            │  │ • New review: 5 stars from David Johnson     │ │
│            │  └──────────────────────────────────────────────┘ │
│            │                                                    │
└────────────┴────────────────────────────────────────────────────┘
```

#### 2. Court Management Screen

```
┌─────────────────────────────────────────────────────────────────┐
│ Oval            [Notifications] [Profile]      │
├────────────┬────────────────────────────────────────────────────┤
│            │                                                    │
│  Tennis    │  Court Management                                 │
│  Match     │                                                    │
│            │  [+ ADD NEW COURT]                                 │
│ ┌──────────┤                                                    │
│ │ Dashboard│  ┌──────────────────────────────────────────────┐ │
│ ├──────────┤  │ Court 1                                 [Edit]│ │
│ │ Courts   │  │ ⭐⭐⭐⭐⭐ (4.9)                                │ │
│ ├──────────┤  │ Hard Surface • Outdoor • Lights               │ │
│ │ Calendar │  │ $30/hour                                      │ │
│ ├──────────┤  │                                               │ │
│ │ Bookings │  │ [MANAGE AVAILABILITY] [VIEW BOOKINGS]        │ │
│ ├──────────┤  └──────────────────────────────────────────────┘ │
│ │ Customers│                                                    │
│ ├──────────┤  ┌──────────────────────────────────────────────┐ │
│ │ Analytics│  │ Court 2                                 [Edit]│ │
│ ├──────────┤  │ ⭐⭐⭐⭐☆ (4.2)                                │ │
│ │ Settings │  │ Clay Surface • Indoor                         │ │
│ └──────────┤  │ $35/hour                                      │ │
│            │  │                                               │ │
│            │  │ [MANAGE AVAILABILITY] [VIEW BOOKINGS]        │ │
│            │  └──────────────────────────────────────────────┘ │
│            │                                                    │
│            │  ┌──────────────────────────────────────────────┐ │
│            │  │ Court 3                                 [Edit]│ │
│            │  │ ⭐⭐⭐⭐☆ (4.1)                                │ │
│            │  │ Hard Surface • Indoor                         │ │
│            │  │ $35/hour                                      │ │
│            │  │                                               │ │
│            │  │ [MANAGE AVAILABILITY] [VIEW BOOKINGS]        │ │
│            │  └──────────────────────────────────────────────┘ │
│            │                                                    │
└────────────┴────────────────────────────────────────────────────┘
```

#### 3. Calendar Management Screen

```
┌─────────────────────────────────────────────────────────────────┐
│ Oval            [Notifications] [Profile]      │
├────────────┬────────────────────────────────────────────────────┤
│            │                                                    │
│  Tennis    │  Calendar Management                              │
│  Match     │                                                    │
│            │  ┌───────────────────────┐ ┌────────────────────┐ │
│ ┌──────────┤  │ Select Court        ▼ │ │ April 2025      ▼ │ │
│ │ Dashboard│  └───────────────────────┘ └────────────────────┘ │
│ ├──────────┤                                                    │
│ │ Courts   │  ┌──────────────────────────────────────────────┐ │
│ ├──────────┤  │ [Calendar Week View with all courts]         │ │
│ │ Calendar │  │                                              │ │
│ ├──────────┤  │ Mon │ Tue │ Wed │ Thu │ Fri │ Sat │ Sun     │ │
│ │ Bookings │  ├─────┼─────┼─────┼─────┼─────┼─────┼─────────┤ │
│ ├──────────┤  │     │     │     │     │     │     │         │ │
│ │ Customers│  │  C1 │  C1 │  C1 │  C1 │  C1 │  C1 │  C1     │ │
│ ├──────────┤  │  C2 │  C2 │  C2 │  C2 │  C2 │  C2 │  C2     │ │
│ │ Analytics│  │  C3 │  C3 │  C3 │  C3 │  C3 │  C3 │  C3     │ │
│ ├──────────┤  │     │     │     │     │     │     │         │ │
│ │ Settings │  │ 9AM │     │     │     │     │     │         │ │
│ └──────────┤  │ -   │     │  B  │     │  B  │  B  │         │ │
│            │  │ 6PM │  M  │     │  B  │     │     │  B      │ │
│            │  │     │     │     │     │     │     │         │ │
│            │  └──────────────────────────────────────────────┘ │
│            │                                                    │
│            │  Legend: [B] Booked [P] Pending [M] Maintenance   │
│            │                                                    │
│            │  ┌───────────────────────────────────────────────┐│
│            │  │ Set Court Hours                               ││
│            │  │ Apply to: ○ All Courts ● Selected Court       ││
│            │  │                                               ││
│            │  │ Monday    9:00 AM - 9:00 PM                   ││
│            │  │ Tuesday   9:00 AM - 9:00 PM                   ││
│            │  │ Wednesday 9:00 AM - 9:00 PM                   ││
│            │  │ Thursday  9:00 AM - 9:00 PM                   ││
│            │  │ Friday    9:00 AM - 9:00 PM                   ││
│            │  │ Saturday  8:00 AM - 10:00 PM                  ││
│            │  │ Sunday    8:00 AM - 8:00 PM                   ││
│            │  │                                               ││
│            │  │ [UPDATE HOURS]                                ││
│            │  └───────────────────────────────────────────────┘│
│            │                                                    │
└────────────┴────────────────────────────────────────────────────┘
```

## Responsive Design

The mobile app is designed for iOS and Android phones with the following breakpoints:
- Small phone: 320px - 360px
- Medium phone: 361px - 414px
- Large phone: 415px - 480px

The web dashboard is designed to be responsive with the following breakpoints:
- Mobile: < 768px (collapsed sidebar, optimized tables)
- Tablet: 768px - 1024px
- Desktop: > 1024px

## Animation Guidelines

- Use smooth transitions between screens (300ms)
- Button press animation: Scale down to 0.95 (100ms)
- Card hover effect: Subtle elevation increase
- Swipe animations for calendar navigation
- Loading indicators should use tennis ball animation
- Calendar selection animation: Tennis ball bounce

## Accessibility

- Maintain minimum contrast ratio of 4.5:1
- Support dynamic text sizing
- All interactive elements have minimum touch target of 48x48dp
- Include descriptive labels for screen readers
- Support right-to-left languages where applicable
