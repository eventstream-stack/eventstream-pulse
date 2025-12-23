/// Pulse Modal Widget - centered popup dialog
/// Copy this file to: lib/presentation/widgets/pulse/pulse_modal.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/pulse_message_model.dart';
import '../../riverpod/pulse_providers.dart';

class PulseModal extends ConsumerWidget {
  final PulseMessage message;
  final VoidCallback? onDismiss;
  final VoidCallback? onCtaTap;

  const PulseModal({
    super.key,
    required this.message,
    this.onDismiss,
    this.onCtaTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Parse custom colors from message, with fallbacks
    final bgColor = message.backgroundColorParsed;
    final titleTextColor = message.titleColorParsed;
    final bodyTextColor = message.bodyColorParsed ?? Colors.grey[700];
    final btnColor = message.buttonColorParsed;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: bgColor,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image header (if present)
            if (message.imageUrl != null)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl: message.imageUrl!,
                  height: 180,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 180,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 180,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: titleTextColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message.body,
                    style: TextStyle(
                      fontSize: 15,
                      color: bodyTextColor,
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (message.isDismissible)
                    TextButton(
                      onPressed: () {
                        ref
                            .read(pulseMessagesProvider.notifier)
                            .dismissMessage(message.id);
                        Navigator.of(context).pop();
                        onDismiss?.call();
                      },
                      child: Text(
                        'Dismiss',
                        style: TextStyle(color: bodyTextColor?.withOpacity(0.7)),
                      ),
                    ),
                  if (message.hasCta) ...[
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        ref
                            .read(pulseMessagesProvider.notifier)
                            .recordTap(message.id);
                        Navigator.of(context).pop();
                        onCtaTap?.call();
                        _handleCtaAction(context, message.ctaAction);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: btnColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(message.ctaText!),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCtaAction(BuildContext context, String? action) {
    if (action == null) return;
    // TODO: Implement URL/deep link handling
    // This could use url_launcher or your app's navigation system
    // Example:
    // if (action.startsWith('app://')) {
    //   // Handle deep link
    // } else if (action.startsWith('http')) {
    //   launchUrl(Uri.parse(action));
    // }
  }
}

/// Show the pulse modal dialog
Future<void> showPulseModal(
  BuildContext context,
  PulseMessage message, {
  VoidCallback? onDismiss,
  VoidCallback? onCtaTap,
}) {
  return showDialog(
    context: context,
    barrierDismissible: message.isDismissible,
    builder: (context) => PulseModal(
      message: message,
      onDismiss: onDismiss,
      onCtaTap: onCtaTap,
    ),
  );
}
