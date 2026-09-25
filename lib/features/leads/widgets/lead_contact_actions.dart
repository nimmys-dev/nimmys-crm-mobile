// ignore_for_file: unrelated_type_equality_checks

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:nimmys_crm/core/theme/app_colors.dart';
import 'package:nimmys_crm/core/theme/app_theme.dart';
import 'package:nimmys_crm/core/utils/phone_dialer.dart';
import 'package:nimmys_crm/core/utils/whatsapp_launcher.dart';
import 'package:nimmys_crm/enum/status.dart';
import 'package:nimmys_crm/features/leads/cubit/leads/leads_cubit.dart';
import 'package:nimmys_crm/utils/toast_messages.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
  bool _isDownloading = false;

  void _sendQuotation() {
    if (_isLoading || _isDownloading) return;
    setState(() => _isLoading = true);
    context.read<LeadsCubit>().getQuotationPdf(widget.leadId);
  }

  Future<void> _downloadAndSharePdf(String pdfUrl) async {
    setState(() {
      _isDownloading = true;
      _isLoading = false;
    });

    try {
      final String fileName = _buildFileName(pdfUrl);
      final Directory tempDir = await getTemporaryDirectory();
      final String savePath = '${tempDir.path}/$fileName';

      // Clean stale file so we always share the fresh one.
      final File existing = File(savePath);
      if (await existing.exists()) {
        await existing.delete();
      }

      await Dio().download(pdfUrl, savePath);

      final File pdfFile = File(savePath);
      if (!await pdfFile.exists()) {
        throw Exception('PDF file not found after download');
      }

      // Compute share sheet origin — required on iPad and on iOS 26+.
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      final Rect? shareOrigin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null;

      // Open the native share sheet. WhatsApp (and WhatsApp Business)
      // appear as share targets. The PDF is attached as a real file.
      await Share.shareXFiles(
        <XFile>[
          XFile(pdfFile.path, mimeType: 'application/pdf', name: fileName),
        ],
        text: 'Quotation for ${widget.name}',
        subject: 'Quotation - ${widget.name}',
        sharePositionOrigin: shareOrigin,
      );
    } catch (e) {
      if (mounted) {
        ToastMessages.error(message: 'Failed to download PDF: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _isLoading = false;
        });
      }
    }
  }

  String _buildFileName(String url) {
    try {
      final uri = Uri.parse(url);
      final segment = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
      if (segment.toLowerCase().endsWith('.pdf')) return segment;
    } catch (_) {
      // ignore and fallback
    }
    return 'quotation_${widget.leadId}.pdf';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LeadsCubit, LeadsState>(
      listener: (context, state) {
        final pdfState = state.quotationPdfUIState;

        if (pdfState?.status == Status.SUCCESS) {
          final pdfUrl = pdfState?.data?.data?.pdfUrl;
          debugPrint('-----------PDF URL: $pdfUrl');
          debugPrint(
            '-----------Filename: ${_buildFileName(pdfUrl.toString())}',
          );
          // Reset so we don't react again
          context.read<LeadsCubit>().resetQuotationPdfState();

          if (pdfUrl != null && pdfUrl.isNotEmpty) {
            _downloadAndSharePdf(pdfUrl);
          } else {
            if (mounted) setState(() => _isLoading = false);
            ToastMessages.error(message: 'PDF URL not found');
          }
        } else if (pdfState?.status == Status.ERROR) {
          if (mounted) setState(() => _isLoading = false);
          final error =
              pdfState?.errorType?.getText(context) ?? 'Failed to generate PDF';
          ToastMessages.error(message: error);
          context.read<LeadsCubit>().resetQuotationPdfState();
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (widget.hasQuotation == true) ...[
            LeadActionButton(
              icon: (_isLoading || _isDownloading)
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
              tooltip: _isDownloading
                  ? 'Downloading PDF…'
                  : 'Share quotation PDF',
              onPressed: (_isLoading || _isDownloading) ? null : _sendQuotation,
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
                () => WhatsAppLauncher.openChat(context, widget.mobile),
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
