// lib/services/lockout_service.dart
// Brute-force protection: tracks failed PIN attempts and enforces time-based lockouts.

import 'secure_storage.dart';

enum LockoutState { allowed, locked }

class LockoutStatus {
  final LockoutState state;

  /// Remaining lockout duration. Null when [state] == [LockoutState.allowed].
  final Duration? remainingDuration;

  /// Total lifetime failed attempts (used for escalating lockout tiers).
  final int totalFailures;

  const LockoutStatus._({
    required this.state,
    this.remainingDuration,
    required this.totalFailures,
  });

  factory LockoutStatus.allowed(int totalFailures) =>
      LockoutStatus._(state: LockoutState.allowed, totalFailures: totalFailures);

  factory LockoutStatus.locked(Duration remaining, int totalFailures) =>
      LockoutStatus._(
        state: LockoutState.locked,
        remainingDuration: remaining,
        totalFailures: totalFailures,
      );

  bool get isLocked => state == LockoutState.locked;

  /// Human-readable remaining time (e.g., "14m 32s").
  String get remainingLabel {
    final r = remainingDuration;
    if (r == null || r.inSeconds <= 0) return '';
    final m = r.inMinutes;
    final s = r.inSeconds % 60;
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}

class LockoutService {
  static final _storage = SecureStorage.instance;

  // Storage keys
  static const _keyFailedAttempts = 'lockout_failed_attempts';
  static const _keyLockoutUntil = 'lockout_until_epoch_ms';
  static const _keyTotalFailures = 'lockout_total_failures';

  // After this many total lifetime failures, require full Firebase re-auth
  static const int fullReauthThreshold = 20;

  /// Check current lockout status. Always returns allowed (Lockout timer disabled).
  Future<LockoutStatus> checkStatus() async {
    try {
      await _storage.delete(key: _keyLockoutUntil);
      await _storage.delete(key: _keyFailedAttempts);
    } catch (_) {}
    return LockoutStatus.allowed(0);
  }

  /// Record a failed attempt. Always returns allowed (Lockout timer disabled).
  Future<LockoutStatus> recordFailedAttempt() async {
    try {
      await _storage.delete(key: _keyLockoutUntil);
      await _storage.delete(key: _keyFailedAttempts);
    } catch (_) {}
    return LockoutStatus.allowed(0);
  }

  /// Call on successful authentication — resets consecutive attempt counter.
  /// Does NOT reset total lifetime failures (used for escalating tiers).
  Future<void> recordSuccess() async {
    await _storage.delete(key: _keyFailedAttempts);
    await _storage.delete(key: _keyLockoutUntil);
  }

  /// Full reset — only call on full logout / account reset.
  Future<void> resetAll() async {
    await _storage.delete(key: _keyFailedAttempts);
    await _storage.delete(key: _keyLockoutUntil);
    await _storage.delete(key: _keyTotalFailures);
  }

  /// Whether the account requires full Firebase re-authentication
  /// due to excessive total failures.
  Future<bool> requiresFullReauth() async {
    final totalStr = await _storage.read(key: _keyTotalFailures) ?? '0';
    final total = int.tryParse(totalStr) ?? 0;
    return total >= fullReauthThreshold;
  }
}
