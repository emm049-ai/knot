import '../models/contact_model.dart';

class RelationshipHealthCalculator {
  static const double decayRate = 1.0; // 1% per day

  static int calculateHealth(Contact contact) {
    if (contact.lastContactedAt == null) {
      return 100; // New contact starts at 100%
    }

    final daysSinceContact = DateTime.now()
        .difference(contact.lastContactedAt!)
        .inDays;

    final health = 100 - (daysSinceContact * decayRate);
    return health.clamp(0, 100).toInt();
  }

  static String getHealthStatus(int health) {
    if (health >= 80) return 'blooming';
    if (health >= 50) return 'healthy';
    if (health >= 25) return 'wilting';
    return 'dead';
  }

  static String getHealthEmoji(int health) {
    final status = getHealthStatus(health);
    switch (status) {
      case 'blooming':
        return '🌺';
      case 'healthy':
        return '🌿';
      case 'wilting':
        return '🍂';
      case 'dead':
        return '💀';
      default:
        return '🌱';
    }
  }
}
