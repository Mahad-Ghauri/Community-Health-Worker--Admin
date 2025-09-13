import 'package:flutter/material.dart';

class FacilityDetailsScreen extends StatelessWidget {
  final String facilityId;

  const FacilityDetailsScreen({super.key, required this.facilityId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Facility Details',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Center(
            child: Text(
              'Facility details for facility: $facilityId',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}