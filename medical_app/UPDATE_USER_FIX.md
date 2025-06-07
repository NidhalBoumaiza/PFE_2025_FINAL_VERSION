# Fix for UpdateUser Creating New Documents Instead of Updating

## Problem Description

The `updateUser` method in `AuthRemoteDataSource` was creating new
documents instead of updating existing ones when updating user
profiles, FCM tokens, or location data. This happened because:

1. **Using `.set()` instead of `.update()`**: The method used
   `firestore.collection(collection).doc(user.id).set(updatedUser.toJson())`
   which **replaces the entire document**.

2. **Missing fields in updates**: The `updatedUser` object was missing
   critical fields like:

   - `fcmToken`
   - `location`
   - `address`
   - `allergies`, `chronicDiseases`, `emergencyContact` (for patients)
   - `education`, `experience`, `consultationFee` (for doctors)
   - `isOnline`, `lastLogin`, `createdAt`, etc.

3. **Incomplete model reconstruction**: When creating updated user
   models, only basic fields were included, so `.set()` overwrote
   documents with incomplete data.

## Solution Implemented

### 1. Fixed `updateUser` Method

- **Changed from `.set()` to `.update()`**: Now uses
  `firestore.collection(collection).doc(user.id).update(updateData)`
  to preserve existing fields.

- **Selective field updates**: Only updates fields that are provided,
  preserving all existing data.

- **Proper data retrieval**: After updating, retrieves the complete
  document and caches it locally.

### 2. Added Helper Method

Created `updateUserTokenAndLocation()` for safe FCM token and location
updates:

```dart
Future<void> updateUserTokenAndLocation({
  required String userId,
  String? fcmToken,
  Map<String, dynamic>? location,
  Map<String, dynamic>? address,
}) async
```

## Usage Examples

### Updating User Profile

```dart
// This will now safely update only the provided fields
await authRemoteDataSource.updateUser(updatedUserModel);
```

### Updating FCM Token Only

```dart
// Use the helper method for token/location updates
await authRemoteDataSource.updateUserTokenAndLocation(
  userId: currentUser.id,
  fcmToken: newFcmToken,
);
```

### Updating Location Only

```dart
await authRemoteDataSource.updateUserTokenAndLocation(
  userId: currentUser.id,
  location: {'latitude': 36.8065, 'longitude': 10.1815},
  address: {'city': 'Tunis', 'country': 'Tunisia'},
);
```

### Updating Both Token and Location

```dart
await authRemoteDataSource.updateUserTokenAndLocation(
  userId: currentUser.id,
  fcmToken: newFcmToken,
  location: newLocation,
  address: newAddress,
);
```

## Key Benefits

1. **No Data Loss**: Existing fields are preserved during updates
2. **Efficient Updates**: Only modified fields are sent to Firestore
3. **Safe Operations**: Uses `.update()` which fails if document
   doesn't exist
4. **Proper Caching**: Updated documents are properly cached locally
5. **Dual Collection Updates**: FCM tokens are updated in both main
   collection and users collection for notifications

## Migration Notes

- Existing code using `updateUser()` will now work correctly without
  changes
- For FCM token and location updates, consider using the new
  `updateUserTokenAndLocation()` helper method
- The fix is backward compatible and doesn't break existing
  functionality

## Testing

Test the following scenarios:

1. Update user profile → Should preserve FCM token and location
2. Update FCM token → Should preserve all other user data
3. Update location → Should preserve all other user data
4. Update multiple fields → Should preserve all non-updated fields
