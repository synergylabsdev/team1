# QR Code Check-In System - Complete Implementation Guide

## Overview

This is a simple QR code check-in system for Flutter + Supabase with **no security requirements**. Users scan QR codes at events to check in and earn points.

## Architecture

### QR Code Format
The QR code contains a simple JSON object:
```json
{
  "eventId": "12345",
  "fallbackCode": "ABCD1234"
}
```

### Workflow
1. Event organizer generates QR code with event ID and fallback code
2. QR code is displayed at event venue
3. User scans QR code or enters fallback code manually
4. App calls Supabase RPC function `check_in_event`
5. RPC validates and processes check-in
6. User receives points and confirmation

## Database Schema

### Tables Created

#### `event_checkins`
- `id` (UUID, Primary Key)
- `user_id` (UUID, FK to auth.users)
- `event_id` (UUID, FK to events)
- `timestamp` (TIMESTAMPTZ)
- `fallback_code` (TEXT)
- `created_at` (TIMESTAMPTZ)
- **Unique constraint**: `(user_id, event_id)` - prevents duplicate check-ins

#### `points_ledger`
- `id` (UUID, Primary Key)
- `user_id` (UUID, FK to auth.users)
- `event_id` (UUID, FK to events, nullable)
- `points` (INTEGER)
- `description` (TEXT)
- `timestamp` (TIMESTAMPTZ)
- `created_at` (TIMESTAMPTZ)

### Events Table (Existing)
Must have:
- `id` (UUID)
- `fallback_code` (TEXT, UNIQUE)
- `date_start` (TIMESTAMPTZ)
- `date_end` (TIMESTAMPTZ)
- Other metadata fields

## Supabase RPC Function

### Function: `check_in_event`

**Parameters:**
- `p_user_id` (UUID)
- `p_event_id` (UUID)
- `p_fallback_code` (TEXT)

**Returns:** JSON
```json
{
  "status": "success",
  "points": 50
}
```
or
```json
{
  "status": "error",
  "message": "Error reason"
}
```

**Validation Logic:**
1. ✅ Event exists
2. ✅ Fallback code matches
3. ✅ Current time is within event time range
4. ✅ User hasn't already checked in
5. ✅ Insert check-in record
6. ✅ Insert points ledger entry
7. ✅ Update user's total points

## Flutter Implementation

### Files Created

1. **`lib/models/qr_check_in_payload.dart`**
   - Model for QR code JSON payload
   - Parsing and serialization

2. **`lib/services/qr_check_in_service.dart`**
   - Service to call Supabase RPC
   - QR code processing
   - Manual fallback code entry

3. **`lib/screens/events/qr_check_in_screen.dart`**
   - Full-screen check-in UI
   - QR scanner with camera
   - Manual code entry field
   - Success/error dialogs

4. **`lib/utils/qr_code_generator.dart`**
   - Utility to generate QR code data
   - Widget generator for display

### Usage

#### From Event Details Screen
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const QRCheckInScreen(),
  ),
);
```

#### Generate QR Code for Event
```dart
// Generate JSON string
final qrData = QRCodeGenerator.generateQRCodeData(
  eventId: event.id,
  fallbackCode: event.fallbackCode!,
);

// Generate widget for display
final qrWidget = QRCodeGenerator.generateQRCodeWidget(
  eventId: event.id,
  fallbackCode: event.fallbackCode!,
  size: 200,
);
```

## Setup Instructions

### 1. Run Supabase Migration

Execute the SQL migration file:
```bash
# In Supabase Dashboard > SQL Editor
# Copy and paste contents of:
supabase_migrations/001_qr_check_in_system.sql
```

### 2. Install Flutter Dependencies

Already included in `pubspec.yaml`:
- `mobile_scanner: ^5.2.3` - QR code scanning
- `qr_flutter: ^4.1.0` - QR code generation

### 3. Permissions

#### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to scan QR codes for event check-in</string>
```

#### Android (`android/app/src/main/AndroidManifest.xml`)
Camera permission is automatically handled by `mobile_scanner`.

### 4. Test the System

1. Create an event in Supabase with:
   - `fallback_code`: "TEST1234"
   - `date_start`: Current time or future
   - `date_end`: Future time

2. Generate QR code:
   ```dart
   final qrData = QRCodeGenerator.generateQRCodeData(
     eventId: 'your-event-id',
     fallbackCode: 'TEST1234',
   );
   ```

3. Test scanning or manual entry

## Error Handling

The system handles these error cases:
- ✅ **Already checked in** - User has already checked in to this event
- ✅ **Invalid fallback code** - Code doesn't match event
- ✅ **Event not active** - Current time outside event time range
- ✅ **Event not found** - Event ID doesn't exist
- ✅ **Generic errors** - Database or network errors

## Points System

- Default points per check-in: **50 points**
- Points are:
  - Added to `points_ledger` table
  - Added to user's total points in `users` table
  - Tracked with event reference

## Security Notes

⚠️ **This is a NO-SECURITY implementation** as requested:
- No token signing
- No authentication checks beyond user existence
- Any camera can scan and check in
- Fallback code is the only validation

For production, consider adding:
- JWT token validation
- Rate limiting
- Location verification
- Time-based code expiration

## Example QR Code Payload

```json
{
  "eventId": "550e8400-e29b-41d4-a716-446655440000",
  "fallbackCode": "EVENT2024"
}
```

This JSON string is encoded in the QR code and can be scanned by any QR reader.

