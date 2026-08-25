import 'package:flutter/material.dart';
import 'package:nimmys_crm/core/theme/app_dimens.dart';
import 'package:nimmys_crm/core/theme/app_theme.dart';
import 'package:nimmys_crm/shared/widgets/app_buttons.dart';
import 'package:nimmys_crm/shared/widgets/app_gradient_header.dart';
import 'package:shimmer/shimmer.dart';

class TaskDetailsLoadingView extends StatelessWidget {
  const TaskDetailsLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        AppGradientHeader(
          eyebrow: 'TASK DETAILS',
          leading: const AppBackButton(),
        ),
        Expanded(
          child: Shimmer.fromColors(
            baseColor: context.palette.surfaceAlt,
            highlightColor: context.palette.surface,
            child: _TaskDetailsShimmer(),
          ),
        ),
      ],
    );
  }
}

// Skeleton that mimics the real content cards
class _TaskDetailsShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(
        left: AppSpacing.gutter,
        right: AppSpacing.gutter,
        top: AppSpacing.md,
        bottom: AppSpacing.xl,
      ),
      children: <Widget>[
        _shimmerCard(
          context,
          children: <Widget>[
            _shimmerLine(width: 120, height: 14),
            const SizedBox(height: AppSpacing.sm),
            _shimmerLine(width: 80, height: 22),
            const SizedBox(height: AppSpacing.md),
            _shimmerLine(width: double.infinity, height: 14),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _shimmerCard(
          context,
          children: <Widget>[
            _shimmerLine(width: 100, height: 14),
            const SizedBox(height: AppSpacing.md),
            _personRowShimmer(context),
            const SizedBox(height: AppSpacing.md),
            _personRowShimmer(context),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _shimmerCard(
          context,
          children: <Widget>[
            _shimmerLine(width: 100, height: 14),
            const SizedBox(height: AppSpacing.md),
            _shimmerLine(width: 160, height: 16),
            const SizedBox(height: 8),
            _shimmerLine(width: 200, height: 12),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _shimmerCard(
          context,
          children: <Widget>[
            _shimmerLine(width: 100, height: 14),
            const SizedBox(height: AppSpacing.sm),
            _shimmerLine(width: double.infinity, height: 14),
            const SizedBox(height: 6),
            _shimmerLine(width: double.infinity, height: 14),
            const SizedBox(height: 6),
            _shimmerLine(width: 200, height: 14),
          ],
        ),
      ],
    );
  }

  Widget _shimmerCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _personRowShimmer(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _shimmerLine(width: 140, height: 16),
              const SizedBox(height: 6),
              _shimmerLine(width: 80, height: 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _shimmerLine({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
