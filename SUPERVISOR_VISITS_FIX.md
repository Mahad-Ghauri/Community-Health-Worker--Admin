# Supervisor CHW Visits Viewing Feature

## Problem Identified
The supervisor role was unable to view CHW (Community Health Worker) field visits and the captured information. This was a critical missing feature for supervisors to monitor field activities.

## Changes Made

### 1. Enhanced Visit Service (`lib/services/visit_service.dart`)
Added three new methods to support supervisor access to visits:

- **`getCHWVisits(String chwId)`**: Stream visits for a specific CHW
- **`getAllVisits({String? facilityId})`**: Stream all visits with optional facility filtering
- Both methods return complete visit data including visit ID

### 2. New CHW Visits Screen (`lib/screens/supervisor/chw_visits_screen.dart`)
Created a comprehensive screen for supervisors to view all CHW field visits with the following features:

#### Features:
- **Real-time Visit List**: Displays all CHW field visits in real-time using Firestore streams
- **Search Functionality**: Search by CHW name, patient name, or visit notes
- **Filter by Visit Type**: Quick filter chips for:
  - Home Visits
  - Follow-ups
  - Tracing
  - Medicine Delivery
  - Counseling
- **Visit Cards**: Each visit displays:
  - Visit type with color-coded icon
  - Date and time
  - Patient found/not found status
  - CHW name
  - Patient name
  - Visit notes
- **Detailed View**: Tap on any visit to see full details including:
  - Complete visit information
  - GPS location data (if captured)
  - Photos count (if captured)

### 3. Added Route Configuration (`lib/config/app_router.dart`)
- Added new route: `/supervisor/visits`
- Imported CHWVisitsScreen component
- Configured in supervisor ShellRoute

### 4. Updated Constants (`lib/constants/app_constants.dart`)
- Added `supervisorVisitsRoute` constant: `/supervisor/visits`

### 5. Enhanced Supervisor Dashboard (`lib/screens/dashboard/supervisor_dashboard.dart`)
- Added prominent "View CHW Field Visits" button at the top of the dashboard
- Button navigates directly to the new visits screen
- Positioned prominently after filters for easy access

### 6. Updated Main Layout Navigation (`lib/screens/main_layout.dart`)
- Added supervisor-specific navigation menu
- Included "CHW Field Visits" as a main navigation item
- Properly segregated supervisor navigation from admin navigation

## How to Use

### For Supervisors:
1. **Log in** with supervisor credentials
2. **From Dashboard**: Click the "View CHW Field Visits" button
3. **From Sidebar**: Click "CHW Field Visits" in the navigation menu
4. **Search**: Use the search bar to find specific visits
5. **Filter**: Click filter chips to show only specific visit types
6. **View Details**: Tap any visit card to see complete information

### Data Displayed:
- All visits from CHWs in the supervisor's facility (if facility filtering is implemented)
- Visit type and status
- CHW who performed the visit
- Patient visited
- Notes captured during the visit
- GPS location (if captured)
- Date and time of visit
- Whether patient was found

## Benefits
1. **Complete Visibility**: Supervisors can now see all field activities
2. **Easy Monitoring**: Real-time updates when CHWs log visits
3. **Quick Filtering**: Find specific types of visits quickly
4. **Detailed Information**: Access all captured data including notes and GPS
5. **Better Supervision**: Track CHW performance and patient coverage

## Database Structure Used
The solution queries the `visits` collection in Firestore with the following fields:
- `visitId`: Unique visit identifier
- `chwId`: CHW who performed the visit
- `patientId`: Patient who was visited
- `visitType`: Type of visit (home_visit, follow_up, etc.)
- `visitDate` or `date`: When the visit occurred
- `found`: Whether patient was found
- `notes`: Visit notes
- `gpsLocation`: GPS coordinates
- `photos`: Array of photo URLs (optional)
- `facilityId`: Associated facility (optional, for filtering)

## Technical Notes
- Uses Firestore real-time streams for live updates
- Implements proper error handling and loading states
- Responsive design works on mobile, tablet, and desktop
- Follows the existing app's theme and design patterns
- Properly integrated with the app's navigation system

## Future Enhancements (Optional)
1. Export visits to CSV/Excel
2. Date range filtering
3. Statistics dashboard for visit analytics
4. Map view showing GPS locations of visits
5. CHW performance metrics based on visits
6. Visit completion rate tracking
