import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../services/patient_service.dart';

class FacilityPatientsFilters {
  FacilityPatientsFilters({
    Set<String>? tbStatuses,
    this.gender,
    this.assignedCHW,
    this.registeredFrom,
    this.registeredTo,
  }) : tbStatuses = tbStatuses ?? <String>{};

  final Set<String> tbStatuses;
  final String? gender;
  final String? assignedCHW;
  final DateTime? registeredFrom;
  final DateTime? registeredTo;

  FacilityPatientsFilters copyWith({
    Set<String>? tbStatuses,
    String? gender,
    String? assignedCHW,
    DateTime? registeredFrom,
    DateTime? registeredTo,
    bool resetGender = false,
    bool resetAssignedCHW = false,
    bool resetRegisteredFrom = false,
    bool resetRegisteredTo = false,
  }) {
    return FacilityPatientsFilters(
      tbStatuses: tbStatuses ?? Set<String>.from(this.tbStatuses),
      gender: resetGender ? null : (gender ?? this.gender),
      assignedCHW: resetAssignedCHW ? null : (assignedCHW ?? this.assignedCHW),
      registeredFrom: resetRegisteredFrom
          ? null
          : (registeredFrom ?? this.registeredFrom),
      registeredTo: resetRegisteredTo
          ? null
          : (registeredTo ?? this.registeredTo),
    );
  }
}

enum FacilityPatientsSort {
  nameAsc,
  nameDesc,
  registrationNewest,
  registrationOldest,
}

class FacilityPatientsProvider extends ChangeNotifier {
  FacilityPatientsProvider({PatientService? patientService})
    : _patientService = patientService ?? PatientService();

  final PatientService _patientService;

  final List<Patient> _patients = <Patient>[];
  List<Patient> get patients => List.unmodifiable(_patients);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String? _facilityId;
  String? get facilityId => _facilityId;

  FacilityPatientsFilters _filters = FacilityPatientsFilters(
    tbStatuses: <String>{},
  );
  FacilityPatientsFilters get filters => _filters;

  FacilityPatientsSort _sort = FacilityPatientsSort.registrationNewest;
  FacilityPatientsSort get sort => _sort;

  String _searchTerm = '';
  String get searchTerm => _searchTerm;

  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  final Set<String> _selectedIds = <String>{};
  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);

  Timer? _searchDebounce;

  void init(String facilityId) {
    if (facilityId.isEmpty) return;
    if (_facilityId == facilityId && _patients.isNotEmpty) return;
    _facilityId = facilityId;
    refresh();
  }

  Future<void> refresh() async {
    if (_facilityId == null) return;
    _isLoading = true;
    _error = null;
    _patients.clear();
    _lastDoc = null;
    _hasMore = true;
    notifyListeners();

    try {
      await _loadPage();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore || _facilityId == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      await _loadPage();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadPage() async {
    if (_facilityId == null) return;

    String sortField = 'createdAt';
    bool descending = true;
    switch (_sort) {
      case FacilityPatientsSort.nameAsc:
        sortField = 'name';
        descending = false;
        break;
      case FacilityPatientsSort.nameDesc:
        sortField = 'name';
        descending = true;
        break;
      case FacilityPatientsSort.registrationNewest:
        sortField = 'createdAt';
        descending = true;
        break;
      case FacilityPatientsSort.registrationOldest:
        sortField = 'createdAt';
        descending = false;
        break;
    }

    final String? tbStatus = _filters.tbStatuses.length == 1
        ? _filters.tbStatuses.first
        : null;

    final snapshot = await _patientService.getFacilityPatientsPage(
      facilityId: _facilityId!,
      limit: 20,
      lastDocument: _lastDoc,
      tbStatus: tbStatus,
      assignedCHW: _filters.assignedCHW,
      gender: _filters.gender,
      registeredFrom: _filters.registeredFrom,
      registeredTo: _filters.registeredTo,
      sortField: sortField,
      descending: descending,
    );

    if (snapshot.docs.isEmpty) {
      _hasMore = false;
      return;
    }

    _lastDoc = snapshot.docs.last;
    final fetched = snapshot.docs
        .map((d) => Patient.fromMap(d.data(), d.id))
        .toList();

    // Apply client-side search and multi-status filtering if needed
    final List<Patient> postProcessed = fetched.where((p) {
      bool matchesSearch = true;
      if (_searchTerm.isNotEmpty) {
        final q = _searchTerm.toLowerCase();
        matchesSearch =
            p.name.toLowerCase().contains(q) ||
            p.phone.toLowerCase().contains(q) ||
            p.address.toLowerCase().contains(q) ||
            p.patientId.toLowerCase().contains(q);
      }
      bool matchesStatuses =
          _filters.tbStatuses.isEmpty ||
          _filters.tbStatuses.contains(p.tbStatus);
      return matchesSearch && matchesStatuses;
    }).toList();

    _patients.addAll(postProcessed);
  }

  void setSort(FacilityPatientsSort sort) {
    _sort = sort;
    refresh();
  }

  void updateFilters(FacilityPatientsFilters filters) {
    _filters = filters;
    refresh();
  }

  void setSearchTerm(String value) {
    _searchTerm = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      refresh();
    });
  }

  void toggleSelect(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedIds.clear();
    notifyListeners();
  }
}
