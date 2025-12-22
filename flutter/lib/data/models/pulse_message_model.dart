/// Pulse Message Model for in-app messaging
/// Copy this file to: lib/data/models/pulse_message_model.dart

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
      targetAppIds: List<String>.from(json['target_app_ids'] ?? []),
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      isCurrentlyActive: json['is_currently_active'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
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
      'target_app_ids': targetAppIds,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_currently_active': isCurrentlyActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get hasCta => ctaText != null && ctaText!.isNotEmpty;
}
