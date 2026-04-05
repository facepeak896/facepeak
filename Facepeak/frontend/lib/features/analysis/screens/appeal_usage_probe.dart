class AppealUsageProbe {
  static void debug({
    required int used,
    required DateTime? cooldownEndsAt,
    required dynamic activeChoice,
  }) {
    print('');
    print('🧪🧪🧪 APPEAL DEBUG PROBE 🧪🧪🧪');
    print('used = $used');
    print('cooldownEndsAt = $cooldownEndsAt');
    print('activeChoice = $activeChoice');
    print('hardLocked = ${cooldownEndsAt != null && used >= 2}');
    print('cooldownActive = ${cooldownEndsAt != null}');
    print('🧪🧪🧪🧪🧪🧪🧪🧪🧪');
    print('');
  }
}