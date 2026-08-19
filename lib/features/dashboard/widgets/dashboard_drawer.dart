// dashboard_drawer.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nimmys_crm/core/theme/app_colors.dart';
import 'package:nimmys_crm/core/theme/app_dimens.dart';
import 'package:nimmys_crm/routing/app_route_name.dart';
import 'package:nimmys_crm/shared/widgets/theme_toggle_button.dart'; // if you want it inside

class DashboardDrawer extends StatelessWidget {
  const DashboardDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // ---- Drawer Header (optional) ----
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: AppColors.headerGradient, // same gradient as header
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nimmy\'s CRM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ---- Drawer Items ----
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    context,
                    icon: Icons.person_rounded,
                    title: 'Profile',
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to profile screen
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.business_rounded,
                    title: 'Company Profile',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRouteName.companyDetails);
                      // Navigate to company profile screen
                    },
                  ),
                  const Divider(),
                  _buildDrawerItem(
                    context,
                    icon: Icons.settings_rounded,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to settings screen
                    },
                  ),
                  const Divider(),
                  // ---- Theme Toggle inside drawer ----
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.dark_mode_rounded),
                        const SizedBox(width: AppSpacing.md),
                        const Text('Dark Theme'),
                        const Spacer(),
                        const ThemeToggleButton(), // your existing widget
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ---- Footer (e.g., Logout) ----
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: AppColors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: AppColors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Handle logout
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).iconTheme.color),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      onTap: onTap,
      trailing: const Icon(Icons.chevron_right_rounded, size: 18),
    );
  }
}
