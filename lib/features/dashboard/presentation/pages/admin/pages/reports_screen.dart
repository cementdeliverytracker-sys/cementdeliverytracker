import 'package:flutter/material.dart';
import 'package:cementdeliverytracker/core/theme/app_colors.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Reports Screen',
        style: TextStyle(fontSize: 24, color: AppColors.textPrimary),
      ),
    );
  }
}
