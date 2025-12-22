/// Pulse Bottom Sheet Widget - slides up from bottom
/// Copy this file to: lib/presentation/widgets/pulse/pulse_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/pulse_message_model.dart';
import '../../riverpod/pulse_providers.dart';

class PulseBottomSheet extends ConsumerWidget {
  final PulseMessage message;
  final VoidCallback? onDismiss;
  final VoidCallback? onCtaTap;

  const PulseBottomSheet({
    super.key,
    required this.message,
    this.onDismiss,
    this.onCtaTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Record impression when shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pulseMessagesProvider.notifier).recordImpression(message.id);
    });

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Image (if present)
            if (message.imageUrl != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: message.imageUrl!,
                    height: 160,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 160,
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 160,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported),
                    ),
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
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message.body,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (message.hasCta)
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        message.ctaText!,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  if (message.isDismissible) ...[
                    const SizedBox(height: 8),
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
                        style: TextStyle(color: Colors.grey[600]),
                      ),
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
  }
}

/// Show the pulse bottom sheet
Future<void> showPulseBottomSheet(
  BuildContext context,
  PulseMessage message, {
  VoidCallback? onDismiss,
  VoidCallback? onCtaTap,
}) {
  return showModalBottomSheet(
    context: context,
    isDismissible: message.isDismissible,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => PulseBottomSheet(
      message: message,
      onDismiss: onDismiss,
      onCtaTap: onCtaTap,
    ),
  );
}
