import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_form_field.dart';
import '../../shared/widgets/app_gradient_header.dart';
import '../../shared/widgets/app_search_field.dart';
import '../../shared/widgets/app_section_card.dart';
import 'domain/entities/lead.dart';
import 'widgets/follow_up_table.dart';

/// Today's Follow Up — date-scoped list of customers to call back.
class TodaysFollowUpScreen extends StatefulWidget {
  const TodaysFollowUpScreen({super.key});

  @override
  State<TodaysFollowUpScreen> createState() => _TodaysFollowUpScreenState();
}

class _TodaysFollowUpScreenState extends State<TodaysFollowUpScreen> {
  static const List<FollowUpEntry> _allEntries = <FollowUpEntry>[
    FollowUpEntry(
      name: 'Sejun',
      mobile: '9961210000',
      requiredItems: 'Sigma 85mm Lens.',
      nextFollowUp: '12-05-2024',
      isPriority: true,
      quotation: LeadQuotation(
        customerAddress: 'Marine Drive, Kochi, Ernakulam 682031',
        items: <QuotationItem>[
          QuotationItem(item: 'Sigma 85mm 1:4 Lens', quantity: 2, rate: 74500),
          QuotationItem(item: 'Lens Cleaning Kit', quantity: 3, rate: 1250),
        ],
      ),
    ),
    // No quotation saved — this row shows only WhatsApp and Call.
    FollowUpEntry(
      name: 'Abin',
      mobile: '8086140010',
      requiredItems: 'Sony Camera.',
      nextFollowUp: '12-05-2024',
    ),
    FollowUpEntry(
      name: 'Sajeesh',
      mobile: '9842610235',
      requiredItems: 'Lens Sony.',
      nextFollowUp: '12-05-2024',
    ),
    FollowUpEntry(
      name: 'Madhu',
      mobile: '8081616161',
      requiredItems: 'Mac Mini',
      nextFollowUp: '12-05-2024',
      isPriority: true,
      quotation: LeadQuotation(
        customerAddress: 'Kanjikuzhi, Kottayam 686004',
        items: <QuotationItem>[
          QuotationItem(
            item: 'Mac Mini M4 (16GB / 512GB)',
            quantity: 1,
            rate: 89900,
          ),
        ],
      ),
    ),
  ];

  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  List<FollowUpEntry> get _visibleEntries {
    if (_query.trim().isEmpty) {
      return _allEntries;
    }
    final String needle = _query.toLowerCase();
    return _allEntries.where((FollowUpEntry entry) {
      return entry.name.toLowerCase().contains(needle) ||
          entry.mobile.contains(needle) ||
          entry.requiredItems.toLowerCase().contains(needle);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<FollowUpEntry> entries = _visibleEntries;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: context.palette.canvas,
        body: Column(
          children: <Widget>[
            const AppGradientHeader(
              title: "Today's Followup",
              eyebrow: 'LEAD MANAGEMENT',
              leading: AppBackButton(),
              actions: <Widget>[
                AppHeaderIconButton(icon: Icons.sync_rounded),
                SizedBox(width: AppSpacing.xs),
           
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(
                  left: AppSpacing.gutter,
                  right: AppSpacing.gutter,
                  top: AppSpacing.md,
                  bottom: AppSpacing.xl,
                ),
                children: <Widget>[
                  FollowUpListToolbar(
                    count: entries.length,
                    dateLabel: '12 May, 2024',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppSearchField(
                    hint: 'Search by name, mobile or item…',
                    controller: _searchController,
                    onChanged: (String value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FollowUpTable(entries: entries),
                  const SizedBox(height: AppSpacing.md),
                  const AppHintBanner(
                    icon: Icons.alarm_on_rounded,
                    title: 'Stay on top of your followups!',
                    message:
                        'Timely followups help you build stronger customer '
                        'relationships and close more deals.',
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: const FollowUpFab(),
      ),
    );
  }
}

/// Title row above the table: record count on the left, date picker on right.
class FollowUpListToolbar extends StatelessWidget {
  const FollowUpListToolbar({
    super.key,
    required this.count,
    required this.dateLabel,
    this.onDateTap,
  });

  final int count;
  final String dateLabel;
  final VoidCallback? onDateTap;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: <Widget>[
          const AppIconChip(
            icon: Icons.fact_check_outlined,
            size: 38,
            tone: AppIconChipTone.red,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('Followup List', style: context.type.cardTitle),
                const SizedBox(height: 2),
                Text(
                  '$count customer${count == 1 ? '' : 's'} to reach today',
                  style: context.type.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          AppDateChip(label: dateLabel, onTap: onDateTap),
        ],
      ),
    );
  }
}

/// Red compose button floating over the follow-up list.
class FollowUpFab extends StatelessWidget {
  const FollowUpFab({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.red.withValues(alpha: 0.42),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: AppColors.red,
        foregroundColor: AppColors.white,
        elevation: 0,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}
