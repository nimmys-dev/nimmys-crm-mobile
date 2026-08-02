import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/theme/app_theme.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/phone_dialer.dart';
import '../../../core/utils/whatsapp_launcher.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../domain/entities/lead.dart';
import '../utils/quotation_pdf.dart';

/// WhatsApp's own green. Kept here rather than on [AppColors], which is for
/// NIMMYS' brand anchors — this is another company's mark, used only so the
/// action is recognisable on sight.
const Color kWhatsAppGreen = Color(0xFF25D366);

/// One row of the follow-up list.
class FollowUpEntry {
  const FollowUpEntry({
    required this.name,
    required this.mobile,
    required this.requiredItems,
    required this.nextFollowUp,
    this.quotation,
    this.isPriority = false,
  });

  final String name;
  final String mobile;
  final String requiredItems;
  final String nextFollowUp;

  /// The quotation saved with the lead, if there is one. Null hides the
  /// send-quotation action on the row — there would be nothing to attach.
  final LeadQuotation? quotation;

  /// Priority rows get the red treatment on their initial bubble and date.
  final bool isPriority;

  /// True when this lead has a quotation worth sending.
  bool get hasQuotation => quotation?.hasContent ?? false;
}

/// Card-wrapped list of today's follow-ups.
///
/// This was a four-column table. On a 360dp phone those columns left the date
/// about 50dp of width, so every `12-05-2024` came out clipped — and the
/// columns only got narrower as text scale went up. The row is now two zones:
/// a stacked customer block that takes the remaining width, and a fixed call
/// button. Nothing competes for horizontal space, so nothing truncates.
class FollowUpTable extends StatelessWidget {
  const FollowUpTable({
    super.key,
    required this.entries,
    this.onEntryTap,
    this.onCall,
    this.onWhatsApp,
    this.onSendQuotation,
  });

  final List<FollowUpEntry> entries;
  final ValueChanged<FollowUpEntry>? onEntryTap;

  /// Overrides what the call button does — useful once calls need logging
  /// against the lead. Left null, the button opens the platform dialer.
  final ValueChanged<FollowUpEntry>? onCall;

  /// Overrides the WhatsApp button. Left null, it opens a chat on the
  /// customer's saved number.
  final ValueChanged<FollowUpEntry>? onWhatsApp;

  /// Overrides the send-quotation button. Left null, it renders the lead's
  /// quotation as a PDF and opens the share sheet on it.
  final ValueChanged<FollowUpEntry>? onSendQuotation;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.palette.line),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          const FollowUpTableHeader(),
          for (int index = 0; index < entries.length; index++)
            FollowUpTableRow(
              entry: entries[index],
              isLast: index == entries.length - 1,
              onTap: onEntryTap == null
                  ? null
                  : () => onEntryTap!(entries[index]),
              onCall: onCall == null ? null : () => onCall!(entries[index]),
              onWhatsApp: onWhatsApp == null
                  ? null
                  : () => onWhatsApp!(entries[index]),
              onSendQuotation: onSendQuotation == null
                  ? null
                  : () => onSendQuotation!(entries[index]),
            ),
          if (entries.isEmpty) const FollowUpEmptyState(),
        ],
      ),
    );
  }
}

/// Gradient heading strip above the rows.
class FollowUpTableHeader extends StatelessWidget {
  const FollowUpTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 11,
      ),
      child: Row(
        children: const <Widget>[
          Expanded(
            child: FollowUpHeaderCell(
              label: 'CUSTOMER',
              icon: Icons.person_outline_rounded,
            ),
          ),
          FollowUpHeaderCell(label: 'ACTIONS', icon: Icons.bolt_rounded),
        ],
      ),
    );
  }
}

/// A single heading cell with its icon.
class FollowUpHeaderCell extends StatelessWidget {
  const FollowUpHeaderCell({
    super.key,
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 12, color: AppColors.white.withValues(alpha: 0.75)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: context.type.tableHeader,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// One data row of [FollowUpTable].
class FollowUpTableRow extends StatelessWidget {
  const FollowUpTableRow({
    super.key,
    required this.entry,
    required this.isLast,
    this.onTap,
    this.onCall,
    this.onWhatsApp,
    this.onSendQuotation,
  });

  final FollowUpEntry entry;
  final bool isLast;
  final VoidCallback? onTap;

  /// Null means "just open the dialer" — see [FollowUpTable.onCall].
  final VoidCallback? onCall;

  /// Null means "just open the chat" — see [FollowUpTable.onWhatsApp].
  final VoidCallback? onWhatsApp;

  /// Null means "render and share the PDF" — see
  /// [FollowUpTable.onSendQuotation].
  final VoidCallback? onSendQuotation;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: palette.line)),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AppInitialBubble(
              letter: entry.name,
              size: 34,
              isAccent: entry.isPriority,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    entry.name,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: palette.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    entry.requiredItems,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: palette.slate,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Wrap, not Row: at large text scales the number and the
                  // date drop onto separate lines instead of being clipped.
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: 4,
                    children: <Widget>[
                      FollowUpMetaChip(
                        icon: Icons.call_outlined,
                        label: entry.mobile,
                      ),
                      FollowUpMetaChip(
                        icon: Icons.event_rounded,
                        label: entry.nextFollowUp,
                        isAccent: entry.isPriority,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            FollowUpRowActions(
              entry: entry,
              onCall: onCall,
              onWhatsApp: onWhatsApp,
              onSendQuotation: onSendQuotation,
            ),
          ],
        ),
      ),
    );
  }
}

/// Icon + value pair used for the mobile number and the next follow-up date.
class FollowUpMetaChip extends StatelessWidget {
  const FollowUpMetaChip({
    super.key,
    required this.icon,
    required this.label,
    this.isAccent = false,
  });

  final IconData icon;
  final String label;

  /// Accent meta is red — the treatment priority rows used to get on the date.
  final bool isAccent;

  @override
  Widget build(BuildContext context) {
    final Color tint = isAccent ? AppColors.red : context.palette.muted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 13, color: tint),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isAccent ? AppColors.red : context.palette.slate,
          ),
        ),
      ],
    );
  }
}

/// The action cluster at the end of a follow-up row.
///
/// WhatsApp, then Send Quotation, then Call — the two new actions sit to the
/// left of the call button, which keeps its red treatment and its behaviour.
/// Send Quotation is absent, not disabled, on a lead with no quotation: a
/// dead button on every second row is noise, and the row already tells the
/// user nothing was quoted.
class FollowUpRowActions extends StatelessWidget {
  const FollowUpRowActions({
    super.key,
    required this.entry,
    this.onCall,
    this.onWhatsApp,
    this.onSendQuotation,
    this.spacing = 6,
  });

  final FollowUpEntry entry;
  final VoidCallback? onCall;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onSendQuotation;
  final double spacing;

  /// "Sigma 85mm Lens." reads badly mid-sentence, so the trailing stop goes.
  String get _enquiry =>
      entry.requiredItems.trim().replaceAll(RegExp(r'\.+$'), '');

  String get _greeting => _enquiry.isEmpty
      ? 'Hi ${entry.name}, following up on your enquiry.'
      : 'Hi ${entry.name}, following up on your enquiry for $_enquiry.';

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (entry.hasQuotation) ...<Widget>[
          FollowUpActionButton(
            // Neutral fill so the red glyph reads as "PDF" without competing
            // with the red-filled call button beside it.
            icon: const Icon(
              Icons.picture_as_pdf_rounded,
              size: 18,
              color: AppColors.red,
            ),
            badge: const FollowUpActionBadge(icon: Icons.share_rounded),
            semanticLabel: 'Send quotation PDF to ${entry.name}',
            tooltip: 'Share quotation PDF',
            onPressed:
                onSendQuotation ??
                () => QuotationPdf.share(
                  context,
                  customerName: entry.name,
                  mobile: entry.mobile,
                  quotation: entry.quotation!,
                ),
          ),
          SizedBox(width: spacing),
        ],
        FollowUpActionButton(
          // A shade larger than the Material glyphs beside it: the brand mark
          // is drawn tighter, so it needs the extra to match their weight.
          icon: const FaIcon(
            FontAwesomeIcons.whatsapp,
            size: 20,
            color: kWhatsAppGreen,
          ),
          fill: kWhatsAppGreen.withValues(alpha: 0.12),
          border: kWhatsAppGreen.withValues(alpha: 0.32),
          semanticLabel: 'WhatsApp ${entry.name}',
          tooltip: 'WhatsApp message',
          onPressed:
              onWhatsApp ??
              () => WhatsAppLauncher.openChat(
                context,
                entry.mobile,
                message: _greeting,
              ),
        ),
        SizedBox(width: spacing),

        FollowUpCallButton(
          name: entry.name,
          mobile: entry.mobile,
          onPressed: onCall,
        ),
      ],
    );
  }
}

/// Round button used by the secondary row actions.
///
/// Same circle and size as [FollowUpCallButton] so the three actions read as
/// one set, but each carries its own tint: WhatsApp green for the chat, brand
/// red for the quotation PDF. The call button stays the only *filled* red
/// one, so the row's primary action is still obvious at a glance.
class FollowUpActionButton extends StatelessWidget {
  const FollowUpActionButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.fill,
    this.border,
    this.badge,
    this.tooltip,
    this.onPressed,
    this.size = 38,
  });

  /// The glyph, already sized and tinted. A widget rather than an `IconData`
  /// because the WhatsApp mark comes from Font Awesome, whose icons are not
  /// square and so ship their own `FaIcon` renderer.
  final Widget icon;

  final String semanticLabel;
  final Color? fill;
  final Color? border;

  /// Small overlay in the bottom-right corner — the share mark on the PDF
  /// button. Sits outside the clipped circle, so it is not cut off.
  final Widget? badge;

  final String? tooltip;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    Widget button = Material(
      color: fill ?? context.palette.inkWash,
      shape: CircleBorder(
        side: BorderSide(color: border ?? context.palette.inkBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(child: icon),
        ),
      ),
    );

    if (badge != null) {
      button = Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          button,
          // Pushed just past the circle's edge so it sits in the corner the
          // glyph does not use, rather than on top of it.
          Positioned(right: -2, bottom: -2, child: badge!),
        ],
      );
    }

    button = Semantics(button: true, label: semanticLabel, child: button);

    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// The little share mark that rides on the corner of the quotation button.
class FollowUpActionBadge extends StatelessWidget {
  const FollowUpActionBadge({super.key, required this.icon, this.size = 14});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.red,
        shape: BoxShape.circle,
        // Ringed in the card colour so the badge separates from the button
        // underneath it in both themes.
        border: Border.all(color: context.palette.surface, width: 1.5),
      ),
      child: Icon(icon, size: size * 0.56, color: AppColors.white),
    );
  }
}

/// Round red call button at the end of a follow-up row.
class FollowUpCallButton extends StatelessWidget {
  const FollowUpCallButton({
    super.key,
    required this.name,
    required this.mobile,
    this.onPressed,
    this.size = 38,
  });

  final String name;
  final String mobile;

  /// Null falls back to [PhoneDialer.call] with [mobile].
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Call $name',
      child: Material(
        color: context.palette.redWash,
        shape: CircleBorder(side: BorderSide(color: context.palette.redBorder)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed ?? () => PhoneDialer.call(context, mobile),
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              Icons.call_rounded,
              size: size * 0.47,
              color: AppColors.red,
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown when there is nothing to follow up on.
class FollowUpEmptyState extends StatelessWidget {
  const FollowUpEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.event_available_outlined,
            size: 34,
            color: context.palette.faint,
          ),
          SizedBox(height: AppSpacing.xs),
          Text('No follow ups for this day', style: context.type.bodyMuted),
        ],
      ),
    );
  }
}
