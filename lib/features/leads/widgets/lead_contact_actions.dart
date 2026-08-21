// ignore_for_file: unrelated_type_equality_checks

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:nimmys_crm/core/theme/app_colors.dart';
import 'package:nimmys_crm/core/theme/app_theme.dart';
import 'package:nimmys_crm/core/utils/phone_dialer.dart';
import 'package:nimmys_crm/core/utils/whatsapp_launcher.dart';
import 'package:nimmys_crm/enum/status.dart'; // ✅ correct import
import 'package:nimmys_crm/features/leads/cubit/leads/leads_cubit.dart';
import 'package:nimmys_crm/features/leads/model/quotation_pdf_model.dart';
import 'package:nimmys_crm/utils/toast_messages.dart';
import '../domain/entities/lead.dart';

const Color kWhatsAppGreen = Color(0xFF25D366);

class LeadContactActions extends StatefulWidget {
  const LeadContactActions({
    super.key,
    required this.name,
    required this.mobile,
    required this.leadId,
    this.enquiry,
    this.hasQuotation,
    this.onCall,
    this.onWhatsApp,
    this.onSendQuotation,
    this.spacing = 6,
  });

  final String name;
  final String mobile;
  final int leadId;
  final String? enquiry;
  final bool? hasQuotation;
  final VoidCallback? onCall;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onSendQuotation;
  final double spacing;



  @override
  State<LeadContactActions> createState() => _LeadContactActionsState();
}

class _LeadContactActionsState extends State<LeadContactActions> {
  bool _isLoading = false;

  String get _enquiryText =>
      (widget.enquiry ?? '').trim().replaceAll(RegExp(r'\.+$'), '');

  String get _greeting => _enquiryText.isEmpty
      ? 'Hi ${widget.name}, following up on your enquiry.'
      : 'Hi ${widget.name}, following up on your enquiry for $_enquiryText.';

  void _sendQuotation() {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    context.read<LeadsCubit>().getQuotationPdf(widget.leadId);
  }

  void _sharePdfViaWhatsApp(String pdfUrl) {
    final message =
        'Here is your quotation PDF: $pdfUrl\n\nThank you for choosing Nimmy\'s!';
    WhatsAppLauncher.openChat(context, widget.mobile, message: message);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LeadsCubit, LeadsState>(
      listener: (context, state) {
        final pdfState = state.quotationPdfUIState;

        // Use status comparisons – safe and works with your UIState
        if (pdfState?.status == Status.SUCCESS) {
          setState(() => _isLoading = false);
          final pdfUrl = pdfState?.data?.data?.pdfUrl;
          if (pdfUrl != null && pdfUrl.isNotEmpty) {
            _sharePdfViaWhatsApp(pdfUrl);
          } else {
            ToastMessages.error(message: 'PDF URL not found');
          }
          // Reset so we don't react again
          context.read<LeadsCubit>().resetQuotationPdfState();
        } else if (pdfState?.status == Status.ERROR) {
          setState(() => _isLoading = false);
          final error =
              pdfState?.errorType?.getText(context) ?? 'Failed to generate PDF';
          ToastMessages.error(message: error);
          // Reset on error too
          context.read<LeadsCubit>().resetQuotationPdfState();
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (widget.hasQuotation == true) ...[
            LeadActionButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.red,
                      ),
                    )
                  : const Icon(
                      Icons.picture_as_pdf_rounded,
                      size: 18,
                      color: AppColors.red,
                    ),
              badge: const LeadActionBadge(icon: Icons.share_rounded),
              semanticLabel: 'Send quotation PDF to ${widget.name}',
              tooltip: 'Share quotation PDF',
              onPressed: _isLoading ? null : _sendQuotation,
            ),
            SizedBox(width: widget.spacing),
          ],
          LeadActionButton(
            icon: const FaIcon(
              FontAwesomeIcons.whatsapp,
              size: 20,
              color: kWhatsAppGreen,
            ),
            fill: kWhatsAppGreen.withOpacity(0.12),
            border: kWhatsAppGreen.withOpacity(0.32),
            semanticLabel: 'WhatsApp ${widget.name}',
            tooltip: 'WhatsApp message',
            onPressed:
                widget.onWhatsApp ??
                () => WhatsAppLauncher.openChat(
                  context,
                  widget.mobile,
                  message: _greeting,
                ),
          ),
          SizedBox(width: widget.spacing),
          LeadCallButton(
            name: widget.name,
            mobile: widget.mobile,
            onPressed: widget.onCall,
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// The rest (LeadActionButton, LeadActionBadge, LeadCallButton)
// remain exactly as in your original file – keep them unchanged.
// ------------------------------------------------------------

// ============================================================
// Helper widgets (unchanged)
// ============================================================

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

  final Widget icon;
  final String semanticLabel;
  final Color? fill;
  final Color? border;
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
          Positioned(right: -2, bottom: -2, child: badge!),
        ],
      );
    }

    button = Semantics(button: true, label: semanticLabel, child: button);

    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

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
        border: Border.all(color: context.palette.surface, width: 1.5),
      ),
      child: Icon(icon, size: size * 0.56, color: AppColors.white),
    );
  }
}

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

