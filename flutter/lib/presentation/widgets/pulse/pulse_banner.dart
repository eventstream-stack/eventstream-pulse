/// Pulse Banner Widget - animated banner at top/bottom of screen
/// Copy this file to: lib/presentation/widgets/pulse/pulse_banner.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/pulse_message_model.dart';
import '../../riverpod/pulse_providers.dart';

class PulseBanner extends ConsumerStatefulWidget {
  final PulseMessage message;
  final VoidCallback? onDismiss;
  final VoidCallback? onCtaTap;

  const PulseBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.onCtaTap,
  });

  @override
  ConsumerState<PulseBanner> createState() => _PulseBannerState();
}

class _PulseBannerState extends ConsumerState<PulseBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    final isTop = widget.message.bannerPosition == BannerPosition.top;
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, isTop ? -1 : 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();

    // Record impression
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pulseMessagesProvider.notifier).recordImpression(widget.message.id);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      ref.read(pulseMessagesProvider.notifier).dismissMessage(widget.message.id);
      widget.onDismiss?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Parse custom colors from message, with fallbacks
    final bgColor = widget.message.backgroundColorParsed ?? Theme.of(context).cardColor;
    final titleTextColor = widget.message.titleColorParsed;
    final bodyTextColor = widget.message.bodyColorParsed ?? Colors.grey[600];

    return SlideTransition(
      position: _slideAnimation,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.message.ctaAction != null
                  ? () {
                      ref
                          .read(pulseMessagesProvider.notifier)
                          .recordTap(widget.message.id);
                      widget.onCtaTap?.call();
                      _handleCtaAction(context, widget.message.ctaAction);
                    }
                  : null,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.message.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: titleTextColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.message.body,
                            style: TextStyle(
                              fontSize: 13,
                              color: bodyTextColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (widget.message.isDismissible)
                      IconButton(
                        onPressed: _dismiss,
                        icon: Icon(
                          Icons.close,
                          size: 20,
                          color: bodyTextColor,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleCtaAction(BuildContext context, String? action) {
    if (action == null) return;
    // TODO: Implement URL/deep link handling
  }
}

/// Overlay entry for showing banner
class PulseBannerOverlay {
  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context,
    PulseMessage message, {
    VoidCallback? onDismiss,
    VoidCallback? onCtaTap,
  }) {
    dismiss();

    _currentEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: message.bannerPosition == BannerPosition.top ? 0 : null,
        bottom: message.bannerPosition == BannerPosition.bottom ? 0 : null,
        left: 0,
        right: 0,
        child: PulseBanner(
          message: message,
          onDismiss: () {
            dismiss();
            onDismiss?.call();
          },
          onCtaTap: onCtaTap,
        ),
      ),
    );

    Overlay.of(context).insert(_currentEntry!);
  }

  static void dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}
