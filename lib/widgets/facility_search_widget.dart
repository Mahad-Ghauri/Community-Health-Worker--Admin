import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/facility.dart';
import '../providers/facility_provider.dart';
import '../theme/theme.dart';

class FacilitySearchWidget extends StatefulWidget {
  final String label;
  final String? selectedFacilityId;
  final String? selectedFacilityName;
  final Function(String? facilityId, String? facilityName) onFacilitySelected;
  final String? Function(String?)? validator;
  final bool enabled;

  const FacilitySearchWidget({
    super.key,
    required this.label,
    this.selectedFacilityId,
    this.selectedFacilityName,
    required this.onFacilitySelected,
    this.validator,
    this.enabled = true,
  });

  @override
  State<FacilitySearchWidget> createState() => _FacilitySearchWidgetState();
}

class _FacilitySearchWidgetState extends State<FacilitySearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isExpanded = false;
  List<Facility> _filteredFacilities = [];

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.selectedFacilityName ?? '';
    
    // Load facilities when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final facilityProvider = Provider.of<FacilityProvider>(context, listen: false);
      facilityProvider.loadFacilities();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _filterFacilities(String query, List<Facility> allFacilities) {
    setState(() {
      if (query.isEmpty) {
        _filteredFacilities = allFacilities.take(10).toList(); // Show first 10 facilities
      } else {
        _filteredFacilities = allFacilities
            .where((facility) =>
                facility.name.toLowerCase().contains(query.toLowerCase()) ||
                facility.address.toLowerCase().contains(query.toLowerCase()) ||
                facility.typeDisplayName.toLowerCase().contains(query.toLowerCase()))
            .take(10)
            .toList();
      }
    });
  }

  void _selectFacility(Facility facility) {
    setState(() {
      _searchController.text = facility.name;
      _isExpanded = false;
    });
    _focusNode.unfocus();
    widget.onFacilitySelected(facility.facilityId, facility.name);
  }

  void _clearSelection() {
    setState(() {
      _searchController.clear();
      _isExpanded = false;
    });
    widget.onFacilitySelected(null, null);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FacilityProvider>(
      builder: (context, facilityProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: CHWTheme.bodyStyle.copyWith(
                fontWeight: FontWeight.w500,
                color: CHWTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            FormField<String>(
              validator: widget.validator,
              builder: (FormFieldState<String> field) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: field.hasError
                              ? const Color(0xFFE57373)
                              : _focusNode.hasFocus
                                  ? const Color(0xFF00796B)
                                  : Colors.grey.shade300,
                          width: _focusNode.hasFocus || field.hasError ? 2 : 1,
                        ),
                        color: widget.enabled ? Colors.white : Colors.grey.shade100,
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _searchController,
                            focusNode: _focusNode,
                            enabled: widget.enabled,
                            decoration: InputDecoration(
                              hintText: 'Search facilities...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: widget.enabled ? _clearSelection : null,
                                    )
                                  : IconButton(
                                      icon: Icon(_isExpanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down),
                                      onPressed: widget.enabled
                                          ? () {
                                              setState(() {
                                                _isExpanded = !_isExpanded;
                                                if (_isExpanded) {
                                                  _filterFacilities(
                                                      _searchController.text,
                                                      facilityProvider.allFacilities);
                                                }
                                              });
                                            }
                                          : null,
                                    ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                            ),
                            onChanged: (value) {
                              field.didChange(value);
                              if (widget.enabled) {
                                _filterFacilities(value, facilityProvider.allFacilities);
                                if (!_isExpanded && value.isNotEmpty) {
                                  setState(() {
                                    _isExpanded = true;
                                  });
                                }
                              }
                            },
                            onTap: () {
                              if (widget.enabled && !_isExpanded) {
                                setState(() {
                                  _isExpanded = true;
                                  _filterFacilities(
                                      _searchController.text,
                                      facilityProvider.allFacilities);
                                });
                              }
                            },
                          ),
                          if (_isExpanded && widget.enabled) ...[
                            const Divider(height: 1),
                            Container(
                              constraints: const BoxConstraints(maxHeight: 200),
                              child: facilityProvider.isLoading
                                  ? const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  : _filteredFacilities.isEmpty
                                      ? const Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: Text(
                                            'No facilities found',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        )
                                      : ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: _filteredFacilities.length,
                                          itemBuilder: (context, index) {
                                            final facility = _filteredFacilities[index];
                                            return ListTile(
                                              title: Text(
                                                facility.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              subtitle: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(facility.typeDisplayName),
                                                  if (facility.address.isNotEmpty)
                                                    Text(
                                                      facility.address,
                                                      style: TextStyle(
                                                        color: Colors.grey.shade600,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              trailing: Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: facility.isActive
                                                      ? Colors.green.shade100
                                                      : Colors.red.shade100,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  facility.statusDisplayName,
                                                  style: TextStyle(
                                                    color: facility.isActive
                                                        ? Colors.green.shade700
                                                        : Colors.red.shade700,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              onTap: () => _selectFacility(facility),
                                            );
                                          },
                                        ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (field.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 12),
                        child: Text(
                          field.errorText!,
                          style: const TextStyle(
                            color: Color(0xFFE57373),
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}