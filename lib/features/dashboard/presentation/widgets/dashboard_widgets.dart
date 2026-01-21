import 'package:flutter/material.dart';
import 'package:cementdeliverytracker/core/constants/app_constants.dart';

/// Reusable card widget for dashboard items
class DashboardCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double borderRadius;

  const DashboardCard({
    required this.child,
    this.onTap,
    this.backgroundColor,
    this.borderRadius = AppConstants.defaultBorderRadius,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: backgroundColor ?? const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      elevation: AppConstants.defaultElevation,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: child,
        ),
      ),
    );
  }
}

/// Reusable bottom fixed button widget
class FixedBottomButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;

  const FixedBottomButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 56,
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor ?? const Color(0xFFFF6F00),
              foregroundColor: textColor ?? Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: Icon(icon, size: 20),
            label: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable user avatar widget
class UserAvatar extends StatelessWidget {
  final String name;
  final double radius;
  final Color? backgroundColor;
  final Color textColor;

  const UserAvatar({
    required this.name,
    this.radius = 24,
    this.backgroundColor,
    this.textColor = Colors.white,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? const Color(0xFFFF6F00),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}

/// Reusable loading state
class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

/// Reusable error state
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({required this.message, this.onRetry, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}

/// Reusable empty state
class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final Widget? action;

  const EmptyState({
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          if (action != null) ...[const SizedBox(height: 24), action!],
        ],
      ),
    );
  }
}

/// Reusable detail row widget for displaying key-value pairs
class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final double labelWidth;

  const DetailRow({
    required this.label,
    required this.value,
    this.labelWidth = 110,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

/// Reusable action buttons row
class ActionButtonsRow extends StatelessWidget {
  final String rejectLabel;
  final String approveLabel;
  final VoidCallback onReject;
  final VoidCallback onApprove;

  const ActionButtonsRow({
    required this.onReject,
    required this.onApprove,
    this.rejectLabel = 'Reject',
    this.approveLabel = 'Approve',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: onReject,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
          ),
          icon: const Icon(Icons.close, size: 18),
          label: Text(rejectLabel),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: onApprove,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6F00),
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.check_circle, size: 18),
          label: Text(approveLabel),
        ),
      ],
    );
  }
}

/// Navigation menu item configuration
class NavigationMenuItem {
  final IconData icon;
  final String label;
  final int index;

  const NavigationMenuItem({
    required this.icon,
    required this.label,
    required this.index,
  });
}

/// Reusable navigation menu configuration
class NavigationMenuConfig {
  static const List<NavigationMenuItem> items = [
    NavigationMenuItem(icon: Icons.dashboard, label: 'Dashboard', index: 0),
    NavigationMenuItem(icon: Icons.list, label: 'Orders', index: 1),
    NavigationMenuItem(icon: Icons.people, label: 'Employees', index: 2),
    NavigationMenuItem(icon: Icons.report, label: 'Reports', index: 3),
    NavigationMenuItem(icon: Icons.settings, label: 'Settings', index: 4),
  ];
}
