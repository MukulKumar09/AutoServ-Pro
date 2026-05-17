import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class WizardStepBar extends StatelessWidget {
  final int currentStep; // 0-indexed: 0=Customer, 1=Vehicle, 2=Inventory, 3=Visual, 4=Mechanical, 5=Jobs
  const WizardStepBar({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    const steps = [
      'Customer',
      'Vehicle',
      'Inventory',
      'Visual',
      'Mechanical',
      'Jobs',
    ];

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            final stepIndex = index ~/ 2;
            final isActive = currentStep > stepIndex;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(top: 15),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      isActive ? AppColors.accent : AppColors.border,
                      isActive ? AppColors.accent : AppColors.border,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          } else {
            final stepIndex = index ~/ 2;
            final isActive = currentStep == stepIndex;
            final isDone = currentStep > stepIndex;
            return _StepCircle(
              number: stepIndex + 1,
              label: steps[stepIndex],
              isActive: isActive,
              isDone: isDone,
            );
          }
        }),
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  final int number;
  final String label;
  final bool isActive, isDone;
  const _StepCircle({
    required this.number,
    required this.label,
    required this.isActive,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isActive || isDone ? AppColors.accent : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isActive || isDone ? AppColors.accent : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check_rounded, color: Colors.black, size: 16)
                : Text('$number',
                    style: TextStyle(
                      color: isActive ? Colors.black : AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    )),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 46, // Constrain width so text wraps instead of pushing flex
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              fontSize: 9,
              height: 1.1,
              fontWeight: FontWeight.w600,
              color: isActive ? AppColors.accent : AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}
