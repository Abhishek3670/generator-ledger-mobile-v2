/// Enum representing booking reminder notification offsets.
enum ReminderOffset {
  none,
  thirtyMin,
  oneHour,
  threeHours,
  oneDay,
  twoDays,
  oneWeek;

  /// Duration before the booking start date that the reminder should fire.
  Duration get duration {
    switch (this) {
      case ReminderOffset.none:
        return Duration.zero;
      case ReminderOffset.thirtyMin:
        return const Duration(minutes: 30);
      case ReminderOffset.oneHour:
        return const Duration(hours: 1);
      case ReminderOffset.threeHours:
        return const Duration(hours: 3);
      case ReminderOffset.oneDay:
        return const Duration(days: 1);
      case ReminderOffset.twoDays:
        return const Duration(days: 2);
      case ReminderOffset.oneWeek:
        return const Duration(days: 7);
    }
  }

  /// User-facing display label for dropdowns, chips, and previews.
  String get displayLabel {
    switch (this) {
      case ReminderOffset.none:
        return 'None';
      case ReminderOffset.thirtyMin:
        return '30 minutes before';
      case ReminderOffset.oneHour:
        return '1 hour before';
      case ReminderOffset.threeHours:
        return '3 hours before';
      case ReminderOffset.oneDay:
        return '1 day before';
      case ReminderOffset.twoDays:
        return '2 days before';
      case ReminderOffset.oneWeek:
        return '1 week before';
    }
  }

  /// Parses a string representation to [ReminderOffset], defaulting to [ReminderOffset.none].
  static ReminderOffset fromString(String? value) {
    if (value == null || value.isEmpty) return ReminderOffset.none;
    return ReminderOffset.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ReminderOffset.none,
    );
  }
}

/// Configuration model for global booking reminder notification settings.
class GlobalReminderSettings {
  final bool enabled;
  final Set<ReminderOffset> selectedOffsets;

  const GlobalReminderSettings({
    this.enabled = true,
    this.selectedOffsets = const {ReminderOffset.oneDay},
  });

  GlobalReminderSettings copyWith({
    bool? enabled,
    Set<ReminderOffset>? selectedOffsets,
  }) {
    return GlobalReminderSettings(
      enabled: enabled ?? this.enabled,
      selectedOffsets: selectedOffsets ?? this.selectedOffsets,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'selected_offsets': selectedOffsets.map((o) => o.name).toList(),
    };
  }

  factory GlobalReminderSettings.fromMap(Map<String, dynamic> map) {
    final enabled = map['enabled'] as bool? ?? true;
    final offsetsRaw = map['selected_offsets'] ?? map['selectedOffsets'];
    Set<ReminderOffset> offsets = {ReminderOffset.oneDay};
    if (offsetsRaw is List) {
      offsets = offsetsRaw
          .map((e) => ReminderOffset.fromString(e?.toString()))
          .where((o) => o != ReminderOffset.none)
          .toSet();
      if (offsets.isEmpty && enabled) {
        offsets = {ReminderOffset.oneDay};
      }
    }
    return GlobalReminderSettings(
      enabled: enabled,
      selectedOffsets: offsets,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GlobalReminderSettings &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          selectedOffsets.length == other.selectedOffsets.length &&
          selectedOffsets.containsAll(other.selectedOffsets);

  @override
  int get hashCode => Object.hash(enabled, Object.hashAllUnordered(selectedOffsets));
}
