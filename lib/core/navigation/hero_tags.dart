/// Centralized Hero tags for shared element transitions across screens.
abstract final class HeroTags {
  /// Hero tag for a generator card or detail view.
  static String generatorCard(String generatorId) => 'generator-card-$generatorId';

  /// Hero tag for a generator status badge or avatar/icon.
  static String generatorAvatar(String generatorId) => 'generator-avatar-$generatorId';

  /// Hero tag for a vendor card or detail.
  static String vendorCard(String vendorId) => 'vendor-card-$vendorId';

  /// Hero tag for a vendor avatar or status icon.
  static String vendorAvatar(String vendorId) => 'vendor-avatar-$vendorId';

  /// Hero tag for a booking card.
  static String bookingCard(String bookingId) => 'booking-card-$bookingId';
}
