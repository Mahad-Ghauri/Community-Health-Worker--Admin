import 'package:flutter/material.dart';

class CreateUserScreen extends StatelessWidget {
  const CreateUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create User',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        const Expanded(
          child: Center(
            child: Text(
              'Create user form will be here',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}