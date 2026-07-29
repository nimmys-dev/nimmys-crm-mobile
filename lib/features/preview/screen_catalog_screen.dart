import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/app_section_card.dart';
import '../../shared/widgets/theme_toggle_button.dart';
import '../auth/login_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../duties/add_duty_screen.dart';
import '../duties/create_task_screen.dart';
import '../leads/lead_details_screen.dart';
import '../leads/new_lead_screen.dart';
import '../leads/todays_follow_up_screen.dart';
import '../splash/splash_screen.dart';
import '../staff/staff_creation_screen.dart';

/// Development-only index of every screen in the UI kit.
///
/// The brief asked for screens without an app navigation layer, so this exists
/// purely so each one can be opened and reviewed. Delete this file — and point
/// `main.dart` at whichever screen you want — once real routing lands.
class ScreenCatalogScreen extends StatelessWidget {
  const ScreenCatalogScreen({super.key});

  static final List<CatalogEntry> _entries = <CatalogEntry>[
    CatalogEntry(
      title: 'Splash',
      subtitle: 'Animated brand intro',
      icon: Icons.auto_awesome_rounded,
      builder: () => const SplashScreen(),
    ),
    CatalogEntry(
      title: 'Login',
      subtitle: 'Email and password sign-in',
      icon: Icons.lock_outline_rounded,
      builder: () => const LoginScreen(),
    ),
    CatalogEntry(
      title: 'Dashboard',
      subtitle: 'Duties, leads, totals and report',
      icon: Icons.dashboard_outlined,
      builder: () => const DashboardScreen(),
    ),
    CatalogEntry(
      title: "Today's Follow Up",
      subtitle: 'Searchable follow-up list',
      icon: Icons.list_alt_rounded,
      builder: () => const TodaysFollowUpScreen(),
    ),
    CatalogEntry(
      title: 'New Lead',
      subtitle: 'Capture a fresh enquiry',
      icon: Icons.person_add_alt_1_outlined,
      builder: () => const NewLeadScreen(),
    ),
    CatalogEntry(
      title: 'Lead Details',
      subtitle: 'Customer, items and call log',
      icon: Icons.contact_page_outlined,
      builder: () => const LeadDetailsScreen(),
    ),
    CatalogEntry(
      title: 'Create Task',
      subtitle: 'One-off task assignment',
      icon: Icons.add_task_rounded,
      builder: () => const CreateTaskScreen(),
    ),
    CatalogEntry(
      title: 'Add New Duty',
      subtitle: 'Recurring duty with frequency',
      icon: Icons.event_repeat_rounded,
      builder: () => const AddDutyScreen(),
    ),
    CatalogEntry(
      title: 'Staff Creation',
      subtitle: 'Personal and employment details',
      icon: Icons.badge_outlined,
      builder: () => const StaffCreationScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: context.palette.canvas,
        body: Column(
          children: <Widget>[
            const CatalogHeader(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  left: AppSpacing.gutter,
                  right: AppSpacing.gutter,
                  top: AppSpacing.md,
                  bottom: AppSpacing.xl,
                ),
                itemCount: _entries.length,
                itemBuilder: (BuildContext context, int index) {
                  return CatalogTile(entry: _entries[index], index: index + 1);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Screen entry shown in the catalog.
class CatalogEntry {
  const CatalogEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.builder,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget Function() builder;
}

/// Black header of the catalog with the brand lockup.
class CatalogHeader extends StatelessWidget {
  const CatalogHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: topInset + AppSpacing.lg,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: AppSpacing.lg,
      ),
      decoration: const BoxDecoration(gradient: AppColors.splashGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(child: AppLogo(height: 40)),
              const ThemeToggleButton(),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'UI SCREENS',
            style: context.type.splashTagline.copyWith(fontSize: 10.5),
          ),
          const SizedBox(height: 3),
          Text(
            'Tap any screen to preview',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: context.palette.faint,
            ),
          ),
        ],
      ),
    );
  }
}

/// A row in the catalog list.
class CatalogTile extends StatelessWidget {
  const CatalogTile({super.key, required this.entry, required this.index});

  final CatalogEntry entry;
  final int index;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => entry.builder(),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: <Widget>[
              AppIconChip(icon: entry.icon, size: 42),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(entry.title, style: context.type.cardTitle),
                    const SizedBox(height: 2),
                    Text(entry.subtitle, style: context.type.caption),
                  ],
                ),
              ),
              Text(
                index.toString().padLeft(2, '0'),
                style: context.type.caption.copyWith(
                  fontWeight: FontWeight.w800,
                  color: context.palette.faint,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.red,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
