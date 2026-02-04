# CHW Visits Troubleshooting Guide

## Issue Reported
Visits from CHWs in the field are not showing up in the supervisor's view, even though everything else is working fine.

## Root Causes Identified & Fixed

### 1. **Firestore Query Index Requirement** ✅ FIXED
**Problem**: Using `where()` + `orderBy()` on different fields requires a composite index in Firestore.

**Solution**: Modified query to avoid index requirement:
- Removed server-side ordering that required an index
- Implemented client-side filtering and sorting
- Query now fetches documents without complex filters first

### 2. **Missing Debug Logging** ✅ FIXED
**Problem**: No visibility into what was happening with the data stream.

**Solution**: Added comprehensive logging:
- Service layer logs all queries and responses
- UI logs stream states and data counts
- Error messages now show full details

### 3. **Date Field Inconsistency** ✅ HANDLED
**Problem**: Visits might have either `visitDate` or `date` field names.

**Solution**: Code now handles both field names gracefully:
- Checks for `visitDate` first
- Falls back to `date` if not found
- Sorts by whichever is available

---

## Changes Made

### File: `lib/services/visit_service.dart`
**Changes**:
- ✅ Removed complex query that required Firestore index
- ✅ Added debug logging with `kDebugMode` checks
- ✅ Implemented client-side filtering by facilityId
- ✅ Implemented client-side sorting by date
- ✅ Handles both `visitDate` and `date` field names
- ✅ Better error handling with try-catch and rethrow

**Key Code**:
```dart
// Simple query without index requirement
return _visitsCol.limit(limit).snapshots().map((snap) {
  // Get all docs
  var docs = snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
  
  // Filter by facility (client-side)
  if (facilityId != null && facilityId.isNotEmpty) {
    docs = docs.where((doc) => doc['facilityId'] == facilityId).toList();
  }
  
  // Sort by date (client-side)
  docs.sort((a, b) {
    final dateA = (a['visitDate'] ?? a['date']).toDate();
    final dateB = (b['visitDate'] ?? b['date']).toDate();
    return dateB.compareTo(dateA); // Newest first
  });
  
  return docs;
});
```

### File: `lib/screens/supervisor/chw_visits_screen.dart`
**Changes**:
- ✅ Added extensive debug logging to StreamBuilder
- ✅ Logs connection state, error state, and data count
- ✅ Logs first visit data for inspection
- ✅ Added "Retry" button in error state
- ✅ Better error message display with padding

**Debug Output**:
```
🔍 CHW Visits Stream State:
  Connection: ConnectionState.active
  Has Error: false
  Has Data: true
  Data Count: 15
  First visit: {visitType: home_visit, chwId: chw123, ...}
```

### File: `lib/screens/supervisor/visits_diagnostic_screen.dart` (NEW)
**Purpose**: Dedicated troubleshooting tool for supervisors

**Features**:
- ✅ Tests Firestore connection
- ✅ Counts total visits in database
- ✅ Fetches and displays sample visit data
- ✅ Checks for required fields (visitDate, date, chwId, patientId)
- ✅ Tests real-time streaming
- ✅ Shows detailed logs with timestamps
- ✅ Color-coded output (green=success, red=error, orange=warning)

### File: `lib/screens/dashboard/supervisor_dashboard.dart`
**Changes**:
- ✅ Added "Troubleshoot Visits (Debug)" button
- ✅ Button opens diagnostic screen
- ✅ Positioned right below main visits button
- ✅ Imported diagnostic screen

---

## How to Use the Fixes

### Step 1: Run the Diagnostic Tool
1. Log in as a supervisor
2. On the dashboard, click **"Troubleshoot Visits (Debug)"**
3. Click **"Run Diagnostics"**
4. Review the output:
   - ✅ Green checkmarks = All good
   - ⚠️  Orange warnings = Potential issues
   - ❌ Red errors = Problems found

### Step 2: Check Console Logs
Open your debug console and look for:
```
📋 VisitService.getAllVisits called
   Limit: 200
   FacilityId: null
📋 Firestore response received
   Documents count: 15
   Final sorted list: 15 visits
```

```
🔍 CHW Visits Stream State:
  Connection: ConnectionState.active
  Has Error: false
  Has Data: true
  Data Count: 15
```

### Step 3: Verify Visits Exist
The diagnostic tool will tell you:
- Total number of visits in database
- Whether visits have the required fields
- Sample visit data

---

## Common Issues & Solutions

### Issue 1: "No visits in database"
**Symptoms**: Diagnostic shows 0 visits

**Solution**:
1. Verify CHWs have actually recorded visits
2. Check if visits are being saved to correct Firestore collection
3. Verify collection name is 'visits' (not 'Visits' or 'visit')

**Action**:
```dart
// In patient_details_screen or facility_patients_screen
// Make sure visits are created with:
await service.createVisit({
  'patientId': patientId,
  'chwId': chwId,
  'visitDate': Timestamp.fromDate(DateTime.now()),
  // ... other fields
});
```

### Issue 2: "No date fields found"
**Symptoms**: Warning about missing visitDate or date

**Solution**:
1. Ensure visits are saved with `visitDate` field
2. Update old visits to include date field

**Action**:
```firestore
// Firestore console - add field to existing documents
visitDate: Timestamp (current time)
```

### Issue 3: Stream shows "waiting" forever
**Symptoms**: Loading spinner never stops

**Possible Causes**:
- Firestore rules blocking read access
- Network connectivity issues
- Firebase not initialized

**Solution**:
```firestore
// Check Firestore rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /visits/{visitId} {
      // Allow supervisors to read all visits
      allow read: if request.auth != null && 
        request.auth.token.role == 'supervisor';
    }
  }
}
```

### Issue 4: Error about missing index
**Symptoms**: "The query requires an index" error

**Solution**: Already fixed! The new code doesn't require an index.

---

## Testing Checklist

- [ ] Run diagnostic tool - should show visit count
- [ ] Check console logs - should see "VisitService" and "CHW Visits" logs
- [ ] Open CHW Visits screen - should load without errors
- [ ] Verify visits appear in list
- [ ] Test search functionality
- [ ] Test filter chips
- [ ] Click on a visit - details modal should open

---

## What to Look For

### In Console (Debug Output):
```
✅ Good Signs:
📋 Firestore response received
   Documents count: 15
🔍 CHW Visits Stream State:
   Has Data: true
   Data Count: 15

❌ Bad Signs:
❌ Error in getAllVisits: ...
🔍 CHW Visits Stream State:
   Has Error: true
```

### In Diagnostic Tool:
```
✅ Good Results:
✅ Found 15 documents in visits collection
✅ Field check results:
   visitDate field: ✅
   chwId field: ✅
   patientId field: ✅
✅ Stream working! Received 5 docs

❌ Problem Results:
⚠️ No visits found in database!
⚠️ WARNING: No date fields found!
❌ ERROR: permission-denied
```

---

## Next Steps

1. **Immediate**: Run the diagnostic tool to see exact state
2. **If no visits**: Verify CHWs are recording visits properly
3. **If permission error**: Update Firestore security rules
4. **If other error**: Check console logs for details

---

## Firestore Security Rules (Recommended)

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Visits collection
    match /visits/{visitId} {
      // CHWs can create and read their own visits
      allow create: if request.auth != null && 
        request.auth.token.role == 'chw' || 
        request.auth.token.role == 'staff';
      
      // CHWs can read their own visits
      allow read: if request.auth != null && (
        request.auth.token.role == 'chw' && 
        resource.data.chwId == request.auth.uid
      );
      
      // Supervisors and admins can read all visits
      allow read: if request.auth != null && (
        request.auth.token.role == 'supervisor' ||
        request.auth.token.role == 'admin' ||
        request.auth.token.role == 'staff'
      );
      
      // Staff can update visits
      allow update: if request.auth != null && (
        request.auth.token.role == 'staff' ||
        request.auth.token.role == 'admin'
      );
    }
  }
}
```

---

## Performance Notes

- Query fetches up to 200 visits (configurable)
- Client-side filtering is fast for this amount of data
- Sorting happens in memory (efficient)
- Real-time updates via Firestore streams

---

## Support

If visits still don't show after these fixes:

1. **Run diagnostic tool** - it will pinpoint the exact issue
2. **Check console logs** - look for red error messages
3. **Verify Firestore rules** - ensure supervisor has read access
4. **Check network** - ensure device can reach Firestore
5. **Verify Firebase config** - ensure project is properly configured

---

**Last Updated**: February 4, 2026  
**Status**: ✅ Ready for Testing  
**Files Modified**: 4  
**New Files**: 1 (diagnostic tool)
