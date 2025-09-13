import 'package:flutter/material.dart';

class EditFacilityScreen extends StatelessWidget {
  final String facilityId;

  const EditFacilityScreen({super.key, required this.facilityId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Edit Facility',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Center(
            child: Text(
              'Edit facility form for facility: $facilityId',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}