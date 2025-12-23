/// Pulse Full Screen Widget - full screen takeover
/// Copy this file to: lib/presentation/widgets/pulse/pulse_full_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/pulse_message_model.dart';
import '../../riverpod/pulse_providers.dart';

class PulseFullScreen extends ConsumerStatefulWidget {
  final PulseMessage message;
  final VoidCallback? onDismiss;
  final VoidCallback? onCtaTap;

  const PulseFullScreen({
    super.key,
    required this.message,
    this.onDismiss,
    this.onCtaTap,
  });

  @override
  ConsumerState<PulseFullScreen> createState() => _PulseFullScreenState();
}

class _PulseFullScreenState extends ConsumerState<PulseFullScreen> {
  @override
  void initState() {
    super.initState();
    // Record impression
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pulseMessagesProvider.notifier).recordImpression(widget.message.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Parse custom colors from message, with full-screen appropriate defaults
    final bgColor = widget.message.backgroundColorParsed ?? Theme.of(context).primaryColor;
    final titleTextColor = widget.message.titleColorParsed ?? Colors.white;
    final bodyTextColor = widget.message.bodyColorParsed ?? Colors.white;
    final btnColor = widget.message.buttonColorParsed ?? Colors.white;

    // Calculate button text color for contrast
    final btnTextColor = btnColor.computeLuminance() > 0.5
        ? Colors.black87
        : Colors.white;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image or gradient
          if (widget.message.imageUrl != null)
            CachedNetworkImage(
              imageUrl: widget.message.imageUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: bgColor,
              ),
              errorWidget: (context, url, error) => Container(
                color: bgColor,
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    bgColor,
                    bgColor.withOpacity(0.8),
                  ],
                ),
              ),
            ),

          // Gradient overlay for text readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),

          // Close button
          if (widget.message.isDismissible)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 8,
              child: IconButton(
                onPressed: () {
                  ref
                      .read(pulseMessagesProvider.notifier)
                      .dismissMessage(widget.message.id);
                  Navigator.of(context).pop();
                  widget.onDismiss?.call();
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: titleTextColor,
                    size: 24,
                  ),
                ),
              ),
            ),

          // Content
          Positioned(
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).padding.bottom + 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.message.title,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: titleTextColor,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.message.body,
                  style: TextStyle(
                    fontSize: 18,
                    color: bodyTextColor,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // CTA Button
                if (widget.message.hasCta)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ref
                            .read(pulseMessagesProvider.notifier)
                            .recordTap(widget.message.id);
                        Navigator.of(context).pop();
                        widget.onCtaTap?.call();
                        _handleCtaAction(context, widget.message.ctaAction);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: btnColor,
                        foregroundColor: btnTextColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        widget.message.ctaText!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                // Dismiss text button
                if (widget.message.isDismissible) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        ref
                            .read(pulseMessagesProvider.notifier)
                            .dismissMessage(widget.message.id);
                        Navigator.of(context).pop();
                        widget.onDismiss?.call();
                      },
                      child: Text(
                        'Maybe later',
                        style: TextStyle(
                          color: bodyTextColor.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleCtaAction(BuildContext context, String? action) {
    if (action == null) return;
    // TODO: Implement URL/deep link handling
  }
}

/// Show the pulse full screen page
Future<void> showPulseFullScreen(
  BuildContext context,
  PulseMessage message, {
  VoidCallback? onDismiss,
  VoidCallback? onCtaTap,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => PulseFullScreen(
        message: message,
        onDismiss: onDismiss,
        onCtaTap: onCtaTap,
      ),
    ),
  );
}
