/// Pulse Message Model for in-app messaging
/// Copy this file to: lib/data/models/pulse_message_model.dart

import 'dart:ui';

enum PulseMessageType {
  modal,
  banner,
  bottomSheet,
  fullScreen;

  static PulseMessageType fromString(String value) {
    switch (value) {
      case 'modal':
        return PulseMessageType.modal;
      case 'banner':
        return PulseMessageType.banner;
      case 'bottom_sheet':
        return PulseMessageType.bottomSheet;
      case 'full_screen':
        return PulseMessageType.fullScreen;
      default:
        return PulseMessageType.modal;
    }
  }

  String toApiString() {
    switch (this) {
      case PulseMessageType.modal:
        return 'modal';
      case PulseMessageType.banner:
        return 'banner';
      case PulseMessageType.bottomSheet:
        return 'bottom_sheet';
      case PulseMessageType.fullScreen:
        return 'full_screen';
    }
  }
}

enum BannerPosition {
  top,
  bottom;

  static BannerPosition fromString(String value) {
    return value == 'bottom' ? BannerPosition.bottom : BannerPosition.top;
  }
}

class PulseMessage {
  final int id;
  final String title;
  final String body;
  final String? imageUrl;
  final String? ctaText;
  final String? ctaAction;
  final PulseMessageType messageType;
  final BannerPosition bannerPosition;
  final int priority;
  final bool isDismissible;
  final String? backgroundColor;
  final String? titleColor;
  final String? bodyColor;
  final String? buttonColor;
  final List<String> targetAppIds;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isCurrentlyActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  PulseMessage({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.ctaText,
    this.ctaAction,
    required this.messageType,
    required this.bannerPosition,
    required this.priority,
    required this.isDismissible,
    this.backgroundColor,
    this.titleColor,
    this.bodyColor,
    this.buttonColor,
    required this.targetAppIds,
    required this.startDate,
    this.endDate,
    required this.isCurrentlyActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PulseMessage.fromJson(Map<String, dynamic> json) {
    return PulseMessage(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      imageUrl: json['image_url'],
      ctaText: json['cta_text'],
      ctaAction: json['cta_action'],
      messageType: PulseMessageType.fromString(json['message_type'] ?? 'modal'),
      bannerPosition: BannerPosition.fromString(json['banner_position'] ?? 'top'),
      priority: json['priority'] ?? 3,
      isDismissible: json['is_dismissible'] ?? true,
      backgroundColor: _parseColorString(json['background_color']),
      titleColor: _parseColorString(json['title_color']),
      bodyColor: _parseColorString(json['body_color']),
      buttonColor: _parseColorString(json['button_color']),
      targetAppIds: List<String>.from(json['target_app_ids'] ?? []),
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      isCurrentlyActive: json['is_currently_active'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  /// Convert empty string to null for color fields
  static String? _parseColorString(dynamic value) {
    if (value == null || value == '') return null;
    return value.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'image_url': imageUrl,
      'cta_text': ctaText,
      'cta_action': ctaAction,
      'message_type': messageType.toApiString(),
      'banner_position': bannerPosition.name,
      'priority': priority,
      'is_dismissible': isDismissible,
      'background_color': backgroundColor ?? '',
      'title_color': titleColor ?? '',
      'body_color': bodyColor ?? '',
      'button_color': buttonColor ?? '',
      'target_app_ids': targetAppIds,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_currently_active': isCurrentlyActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get hasCta => ctaText != null && ctaText!.isNotEmpty;

  /// Parse hex color string to Flutter Color
  /// Returns null if the string is null, empty, or invalid
  Color? parseHexColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return null;

    // Remove # prefix if present
    String hex = hexColor.replaceFirst('#', '');

    // Handle 3-digit hex (e.g., #FFF -> #FFFFFF)
    if (hex.length == 3) {
      hex = hex.split('').map((c) => '$c$c').join('');
    }

    if (hex.length != 6) return null;

    try {
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return null;
    }
  }

  /// Get parsed background color or null for default
  Color? get backgroundColorParsed => parseHexColor(backgroundColor);

  /// Get parsed title color or null for default
  Color? get titleColorParsed => parseHexColor(titleColor);

  /// Get parsed body color or null for default
  Color? get bodyColorParsed => parseHexColor(bodyColor);

  /// Get parsed button color or null for default
  Color? get buttonColorParsed => parseHexColor(buttonColor);
}
