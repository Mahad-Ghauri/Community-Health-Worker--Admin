import 'package:flutter/material.dart';

class EditUserScreen extends StatelessWidget {
  final String userId;

  const EditUserScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Edit User',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Center(
            child: Text(
              'Edit user form for user: $userId',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}