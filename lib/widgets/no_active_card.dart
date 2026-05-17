// lib/widgets/no_active_card.dart
// This file re-exports the _NoActiveCard widget used in multiple view files.
// Each screen file imports this directly.
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'app_widgets.dart';

class NoActiveCard extends StatelessWidget {
  final VoidCallback onNewCard;

  const NoActiveCard({super.key, required this.onNewCard});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_outlined,
              size: 56,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          const Text('No Active Job Card',
              style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          const Text(
            'Please create or select a job card to continue.',
            style: AppTextStyles.bodySecondary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            label: 'Create New Job Card',
            icon: Icons.add_card,
            onPressed: onNewCard,
          ),
        ],
      ),
    );
  }
}
