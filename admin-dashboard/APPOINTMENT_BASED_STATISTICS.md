# Appointment-Based User Activity Statistics

## Overview

The admin dashboard now displays user activity statistics based on
appointment usage rather than account status. This provides a more
meaningful measure of user engagement with the medical app.

## Activity Definition

### Active Users

- **Active Patients**: Users who have **5 or more appointments**
  (`rendez_vous`)
- **Active Doctors**: Users who have **5 or more appointments**
  (`rendez_vous`)

### Inactive Users

- **Inactive Patients**: Users who have **less than 5 appointments**
- **Inactive Doctors**: Users who have **less than 5 appointments**

## Implementation Details

### Backend Changes

#### 1. Data Source Layer (`UsersRemoteDataSource`)

- Added `getUserStatistics()` method to calculate activity statistics
- Added `getUserAppointmentCount()` method to count appointments per
  user
- Queries the `rendez_vous` collection to count appointments by
  `patientId` and `doctorId`

#### 2. Repository Layer (`UsersRepository`)

- Added statistics methods to the repository interface and
  implementation
- Proper error handling with `Either<Failure, T>` pattern

#### 3. Use Cases

- Created `GetUserStatistics` use case following Clean Architecture
  principles
- No parameters required, returns `Map<String, int>` with statistics

#### 4. BLoC State Management

- Added `LoadUserStatistics` event
- Added `UserStatisticsLoading` and `UserStatisticsLoaded` states
- Automatic statistics refresh after CRUD operations

### Frontend Changes

#### 1. Statistics Cards

The dashboard now shows 4 cards instead of the previous general
statistics:

- **Active Patients** (Green) - "5+ appointments"
- **Inactive Patients** (Orange) - "Less than 5 appointments"
- **Active Doctors** (Blue) - "5+ appointments"
- **Inactive Doctors** (Red) - "Less than 5 appointments"

#### 2. Real-time Updates

- Statistics automatically refresh when users are created, updated, or
  deleted
- Loading states show progress indicators while calculating statistics
- Proper error handling and user feedback

#### 3. UI Enhancements

- Color-coded cards for easy visual distinction
- Loading skeleton cards during calculation
- Descriptive subtitles explaining the criteria

## Statistics Returned

The `getUserStatistics()` method returns a map with the following
keys:

```dart
{
  'activePatients': int,      // Patients with 5+ appointments
  'inactivePatients': int,    // Patients with <5 appointments
  'activeDoctors': int,       // Doctors with 5+ appointments
  'inactiveDoctors': int,     // Doctors with <5 appointments
  'totalPatients': int,       // Total patient count
  'totalDoctors': int,        // Total doctor count
  'totalUsers': int,          // Total user count
  'totalActiveUsers': int,    // Total active users
  'totalInactiveUsers': int,  // Total inactive users
}
```

## Database Queries

### Patient Activity Count

```dart
await firestore
    .collection('rendez_vous')
    .where('patientId', isEqualTo: userId)
    .get();
```

### Doctor Activity Count

```dart
await firestore
    .collection('rendez_vous')
    .where('doctorId', isEqualTo: userId)
    .get();
```

## Performance Considerations

- Statistics are calculated on-demand when requested
- Efficient Firestore queries using indexed fields (`patientId`,
  `doctorId`)
- Results are cached in BLoC state until refresh is needed
- Loading states prevent UI blocking during calculation

## Usage

The statistics automatically load when the Users screen is opened:

```dart
// Automatically triggered on screen load
context.read<UsersBloc>().add(LoadUserStatistics());

// Manual refresh after operations
context.read<UsersBloc>().add(LoadUserStatistics());
```

## Benefits

1. **Meaningful Metrics**: Shows actual app usage rather than just
   registration status
2. **User Engagement**: Identifies highly engaged vs. low-engagement
   users
3. **Business Insights**: Helps understand user behavior patterns
4. **Real-time Data**: Always reflects current appointment data
5. **Visual Clarity**: Color-coded cards make it easy to understand at
   a glance

## Future Enhancements

Potential improvements could include:

- Configurable activity thresholds (currently fixed at 5 appointments)
- Time-based activity (e.g., appointments in last 30 days)
- Activity trends over time
- Export functionality for detailed reports
