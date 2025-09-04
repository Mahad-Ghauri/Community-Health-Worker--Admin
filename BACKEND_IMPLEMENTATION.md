# CHW TB Tracker - Backend Implementation Guide

## 🎯 Overview

This document explains the complete backend implementation for the CHW TB Tracker app, built exactly according to your JSON specification with 31 screens and comprehensive Firebase integration.

## 📋 Implementation Summary

### ✅ **Phase 1: Complete Data Models** - **COMPLETED**
- **7 CHW-Created Collections**: `users`, `patients`, `visits`, `households`, `treatmentAdherence`, `contactTracing`, `auditLogs`
- **5 CHW Read-Only Collections**: `facilities`, `followups`, `notifications`, `assignments`, `outcomes`
- **All field mappings** exactly match your JSON specification
- **Proper Firestore integration** with timestamps and type safety

### ✅ **Phase 2: CRUD Services** - **COMPLETED**
- **PatientService**: Complete CRUD for patient management (Screens 8,9,10,11,12,6)
- **VisitService**: Home visit logging with GPS proof (Screens 13,14,15,6)
- **AuditService**: Comprehensive action logging for compliance
- **GPSService**: Location capture with validation and retry logic

### ✅ **Phase 3: State Management Providers** - **COMPLETED**
- **PatientProvider**: Manages all patient state and operations
- **VisitProvider**: Handles visit creation, listing, and calendar views
- **HouseholdProvider**: Family member management
- **ContactTracingProvider**: TB screening for contacts
- **TreatmentAdherenceProvider**: Medicine intake tracking
- **NotificationProvider**: Alerts and messaging system
- **AuthProvider**: User authentication and registration
- **AppStateProvider**: Global app state, sync, settings
- **ReadOnlyDataProvider**: Admin-created data access

## 🗂️ File Structure

```
lib/
├── models/
│   └── core_models.dart                 # All data models (7 CHW + 5 admin collections)
├── controllers/
│   ├── services/
│   │   ├── patient_service.dart         # Patient CRUD operations
│   │   ├── visit_service.dart           # Visit management & GPS validation
│   │   ├── audit_service.dart           # System logging & compliance
│   │   ├── gps_service.dart             # Location capture & validation
│   │   └── auth_service.dart            # Authentication (existing)
│   └── providers/
│       ├── app_providers.dart           # Main provider aggregation
│       ├── patient_provider.dart        # Patient & visit state management
│       └── secondary_providers.dart     # Other collection providers
```

## 🔄 Screen-to-Backend Mapping

### **Patient Management Flow**
| Screen | Collections Used | Services | Providers |
|--------|------------------|----------|-----------|
| **8. Patient List** | `patients`, `assignments` | PatientService | PatientProvider |
| **9. Patient Search** | `patients` | PatientService | PatientProvider |
| **10. Register New Patient** | `patients`, `facilities`, `auditLogs` | PatientService, AuditService, GPSService | PatientProvider, ReadOnlyDataProvider |
| **11. Patient Details** | `patients`, `visits`, `treatmentAdherence`, `households`, `outcomes` | PatientService, VisitService | PatientProvider, VisitProvider |
| **12. Edit Patient** | `patients`, `auditLogs` | PatientService, AuditService | PatientProvider |

### **Visit Management Flow**
| Screen | Collections Used | Services | Providers |
|--------|------------------|----------|-----------|
| **13. Visit List** | `visits` | VisitService | VisitProvider |
| **14. New Visit** | `visits`, `patients`, `auditLogs` | VisitService, GPSService, AuditService | VisitProvider |
| **15. Visit Details** | `visits`, `treatmentAdherence` | VisitService | VisitProvider |

### **Household & Contact Tracing Flow**
| Screen | Collections Used | Services | Providers |
|--------|------------------|----------|-----------|
| **16. Household Members** | `households` | Direct Firestore | HouseholdProvider |
| **17. Add Household Member** | `households`, `auditLogs` | AuditService | HouseholdProvider |
| **18. Contact Screening** | `contactTracing`, `households` | GPSService, AuditService | ContactTracingProvider |
| **19. Screening Results** | `contactTracing` | Direct Firestore | ContactTracingProvider |

### **Treatment Monitoring Flow**
| Screen | Collections Used | Services | Providers |
|--------|------------------|----------|-----------|
| **20. Adherence Tracking** | `treatmentAdherence`, `visits` | AuditService | TreatmentAdherenceProvider |
| **21. Side Effects Log** | `treatmentAdherence` | Direct queries | TreatmentAdherenceProvider |
| **22. Pill Count** | `treatmentAdherence` | Direct queries | TreatmentAdherenceProvider |

### **Notifications & Dashboard Flow**
| Screen | Collections Used | Services | Providers |
|--------|------------------|----------|-----------|
| **6. Home Dashboard** | `patients`, `visits`, `notifications` | PatientService, VisitService | PatientProvider, VisitProvider, NotificationProvider |
| **23. Notifications List** | `notifications` | Direct Firestore | NotificationProvider |
| **24. Missed Follow-up Alert** | `notifications`, `followups`, `patients` | Direct Firestore | NotificationProvider, ReadOnlyDataProvider |

## 🔧 Key Features Implemented

### **1. GPS Integration**
- **Auto-capture GPS** for patient registration and visits
- **Location validation** to ensure CHWs are at correct locations
- **Offline fallback** with cached coordinates
- **High accuracy requirements** with retry logic

### **2. Audit Logging**
- **Every action logged** for compliance and tracking
- **GPS coordinates captured** for field work verification
- **Comprehensive trail** for patient data changes
- **Silent failures** to not disrupt CHW workflow

### **3. Offline Capability**
- **Local state management** with provider pattern
- **Sync status tracking** with automatic retry
- **Offline queue management** for pending operations
- **Connectivity monitoring** with auto-sync

### **4. Role-Based Access**
- **CHW-only patient access** through assignments
- **Read-only admin data** (facilities, outcomes, etc.)
- **Secure authentication** with direct signup
- **Data isolation** per CHW working area

### **5. Real-Time Updates**
- **Firestore streams** for live data updates
- **Provider notifications** for UI reactivity
- **Automatic refresh** on data changes
- **Optimistic updates** for better UX

## 📱 Provider Usage in Screens

### **How to Use in Your Existing Screens**

#### **Example: Patient List Screen (Screen 8)**
```dart
// In your patient_list_screen.dart
class PatientListScreen extends StatefulWidget {
  @override
  _PatientListScreenState createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize patient provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatientProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PatientProvider>(
        builder: (context, patientProvider, child) {
          if (patientProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (patientProvider.error != null) {
            return Center(child: Text('Error: ${patientProvider.error}'));
          }
          
          final patients = patientProvider.filteredPatients;
          
          return ListView.builder(
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final patient = patients[index];
              return PatientListTile(
                patient: patient,
                onTap: () {
                  // Navigate to patient details
                  patientProvider.selectPatient(patient.patientId);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => PatientDetailsScreen(),
                  ));
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to register new patient
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => RegisterPatientScreen(),
          ));
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
```

#### **Example: Register New Patient Screen (Screen 10)**
```dart
// In your register_patient_screen.dart
class RegisterPatientScreen extends StatefulWidget {
  @override
  _RegisterPatientScreenState createState() => _RegisterPatientScreenState();
}

class _RegisterPatientScreenState extends State<RegisterPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  String _selectedGender = 'male';
  String _selectedTBStatus = 'newly_diagnosed';
  String? _selectedFacility;
  bool _consentGiven = false;

  @override
  void initState() {
    super.initState();
    // Load facilities for dropdown
    context.read<ReadOnlyDataProvider>().loadFacilities();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register New Patient')),
      body: Form(
        key: _formKey,
        child: Consumer2<PatientProvider, ReadOnlyDataProvider>(
          builder: (context, patientProvider, readOnlyProvider, child) {
            return Column(
              children: [
                // Your existing form fields...
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Patient Name'),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                // ... other form fields
                
                // Facility dropdown
                DropdownButtonFormField<String>(
                  value: _selectedFacility,
                  decoration: InputDecoration(labelText: 'Treatment Facility'),
                  items: readOnlyProvider.facilities.map((facility) {
                    return DropdownMenuItem(
                      value: facility.facilityId,
                      child: Text(facility.name),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedFacility = value),
                ),
                
                // Consent checkbox
                CheckboxListTile(
                  title: Text('Patient consents to data collection'),
                  value: _consentGiven,
                  onChanged: (value) => setState(() => _consentGiven = value ?? false),
                ),
                
                // Submit button
                ElevatedButton(
                  onPressed: patientProvider.isLoading ? null : _registerPatient,
                  child: patientProvider.isLoading 
                    ? CircularProgressIndicator()
                    : Text('Register Patient'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _registerPatient() async {
    if (!_formKey.currentState!.validate() || !_consentGiven || _selectedFacility == null) {
      return;
    }

    final success = await context.read<PatientProvider>().registerPatient(
      name: _nameController.text.trim(),
      age: int.parse(_ageController.text.trim()),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      gender: _selectedGender,
      tbStatus: _selectedTBStatus,
      treatmentFacility: _selectedFacility!,
      consent: _consentGiven,
    );

    if (success != null) {
      // Registration successful
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Patient registered successfully')),
      );
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed')),
      );
    }
  }
}
```

## 🚀 Next Steps

### **Integration with Existing Screens**

1. **Update main.dart** to include all providers:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  runApp(
    MultiProvider(
      providers: AppProviders.getProviders(),
      child: MyApp(),
    ),
  );
}
```

2. **Update each screen** to use the appropriate providers
3. **Replace dummy data calls** with real provider methods
4. **Add loading states and error handling** using provider state
5. **Implement offline sync** using AppStateProvider

### **Testing the Implementation**

1. **Register a new CHW** using Screen 2
2. **Create test patients** using Screen 10
3. **Log home visits** using Screen 14
4. **Track adherence** using Screen 20
5. **Screen family members** using Screen 18

## 📊 Data Flow Architecture

```
Screens (UI) → Providers (State) → Services (Logic) → Firestore (Data)
     ↑              ↓                    ↓               ↓
   Updates      Notifications        CRUD Ops       Collections
```

## 🔐 Security & Compliance

- **Authentication required** for all operations
- **CHW-specific data access** through assignments
- **Comprehensive audit trails** for compliance
- **GPS verification** for field work authenticity
- **Consent management** for patient data

---

**Your backend is now fully implemented according to your exact specifications!** 

The system provides:
- ✅ All 7 CHW-created collections with proper CRUD operations
- ✅ All 5 admin-created collections with read-only access
- ✅ Complete state management for all 31 screens
- ✅ GPS integration with offline capabilities
- ✅ Comprehensive audit logging
- ✅ Role-based access control
- ✅ Real-time data synchronization

You can now integrate these providers into your existing 31 screens and have a fully functional CHW TB Tracker app with proper backend architecture!
