/// Pulse Handler - unified message display handler
/// Copy this file to: lib/presentation/widgets/pulse/pulse_handler.dart
///
/// Use this to easily show pulse messages based on their type.

import 'package:flutter/material.dart';
import '../../../data/models/pulse_message_model.dart';
import 'pulse_modal.dart';
import 'pulse_banner.dart';
import 'pulse_bottom_sheet.dart';
import 'pulse_full_screen.dart';

/// Handles displaying pulse messages based on their type
class PulseHandler {
  /// Show a pulse message using the appropriate UI based on message type
  static Future<void> showMessage(
    BuildContext context,
    PulseMessage message, {
    VoidCallback? onDismiss,
    VoidCallback? onCtaTap,
  }) async {
    switch (message.messageType) {
      case PulseMessageType.modal:
        await showPulseModal(
          context,
          message,
          onDismiss: onDismiss,
          onCtaTap: onCtaTap,
        );
        break;

      case PulseMessageType.banner:
        PulseBannerOverlay.show(
          context,
          message,
          onDismiss: onDismiss,
          onCtaTap: onCtaTap,
        );
        break;

      case PulseMessageType.bottomSheet:
        await showPulseBottomSheet(
          context,
          message,
          onDismiss: onDismiss,
          onCtaTap: onCtaTap,
        );
        break;

      case PulseMessageType.fullScreen:
        await showPulseFullScreen(
          context,
          message,
          onDismiss: onDismiss,
          onCtaTap: onCtaTap,
        );
        break;
    }
  }

  /// Dismiss any currently showing banner
  static void dismissBanner() {
    PulseBannerOverlay.dismiss();
  }
}
