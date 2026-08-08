import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/phone_dialer.dart';
import '../../../core/utils/whatsapp_launcher.dart';
import '../domain/entities/lead.dart';
import '../utils/quotation_pdf.dart';

/// WhatsApp's own green. Kept here rather than on [AppColors], which is for
/// NIMMYS' brand anchors — this is another company's mark, used only so the
/// action is recognisable on sight.
const Color kWhatsAppGreen = Color(0xFF25D366);

/// Call, WhatsApp and share-quotation for one customer.
///
/// Takes the three things it needs rather than a row model, so every list that
/// shows a customer can offer the same actions: the follow-up table and My
/// Leads both use this, and neither owns a private copy of the message
/// wording, the PDF call or the button treatment.
///
/// WhatsApp, then Send Quotation, then Call — the two secondary actions sit to
/// the left of the call button, which keeps its red treatment and its
/// behaviour. Send Quotation is absent, not disabled, on a lead with no
/// quotation: a dead button on every second row is noise, and the row already
/// tells the user nothing was quoted.
class LeadContactActions extends StatelessWidget {
  const LeadContactActions({
    super.key,
    required this.name,
    required this.mobile,
    this.enquiry,
    this.quotation,
    this.onCall,
    this.onWhatsApp,
    this.onSendQuotation,
    this.spacing = 6,
  });

  final String name;
  final String mobile;

  /// What the customer asked about, used to open the WhatsApp message. Null or
  /// empty falls back to a generic greeting.
  final String? enquiry;

  /// The quotation saved with the lead, if there is one. Null hides the
  /// send-quotation action — there would be nothing to attach.
  final LeadQuotation? quotation;

  /// Overrides what the call button does — useful once calls need logging
  /// against the lead. Left null, the button opens the platform dialer.
  final VoidCallback? onCall;

  /// Overrides the WhatsApp button. Left null, it opens a chat on the
  /// customer's saved number.
  final VoidCallback? onWhatsApp;

  /// Overrides the send-quotation button. Left null, it renders the lead's
  /// quotation as a PDF and opens the share sheet on it.
  final VoidCallback? onSendQuotation;

  final double spacing;

  bool get _hasQuotation => quotation?.hasContent ?? false;

  /// "Sigma 85mm Lens." reads badly mid-sentence, so the trailing stop goes.
  String get _enquiryText =>
      (enquiry ?? '').trim().replaceAll(RegExp(r'\.+$'), '');

  String get _greeting => _enquiryText.isEmpty
      ? 'Hi $name, following up on your enquiry.'
      : 'Hi $name, following up on your enquiry for $_enquiryText.';

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (_hasQuotation) ...<Widget>[
          LeadActionButton(
            // Neutral fill so the red glyph reads as "PDF" without competing
            // with the red-filled call button beside it.
            icon: const Icon(
              Icons.picture_as_pdf_rounded,
              size: 18,
              color: AppColors.red,
            ),
            badge: const LeadActionBadge(icon: Icons.share_rounded),
            semanticLabel: 'Send quotation PDF to $name',
            tooltip: 'Share quotation PDF',
            onPressed:
                onSendQuotation ??
                () => QuotationPdf.share(
                  context,
                  customerName: name,
                  mobile: mobile,
                  quotation: quotation!,
                ),
          ),
          SizedBox(width: spacing),
        ],
        LeadActionButton(
          // A shade larger than the Material glyphs beside it: the brand mark
          // is drawn tighter, so it needs the extra to match their weight.
          icon: const FaIcon(
            FontAwesomeIcons.whatsapp,
            size: 20,
            color: kWhatsAppGreen,
          ),
          fill: kWhatsAppGreen.withValues(alpha: 0.12),
          border: kWhatsAppGreen.withValues(alpha: 0.32),
          semanticLabel: 'WhatsApp $name',
          tooltip: 'WhatsApp message',
          onPressed:
              onWhatsApp ??
              () => WhatsAppLauncher.openChat(
                context,
                mobile,
                message: _greeting,
              ),
        ),
        SizedBox(width: spacing),
        LeadCallButton(name: name, mobile: mobile, onPressed: onCall),
      ],
    );
  }
}

/// Round button used by the secondary row actions.
///
/// Same circle and size as [LeadCallButton] so the three actions read as one
/// set, but each carries its own tint: WhatsApp green for the chat, brand red
/// for the quotation PDF. The call button stays the only *filled* red one, so
/// the row's primary action is still obvious at a glance.
class LeadActionButton extends StatelessWidget {
  const LeadActionButton({
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
class LeadActionBadge extends StatelessWidget {
  const LeadActionBadge({super.key, required this.icon, this.size = 14});

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

/// Round red call button at the end of a customer row.
class LeadCallButton extends StatelessWidget {
  const LeadCallButton({
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
