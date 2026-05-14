import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _kPinHash = 'pin_hash';
  static const _kPinSalt = 'pin_salt';
  static const _kBiometricEnabled = 'biometric_enabled';
  static const _kLockEnabled = 'lock_enabled';

  Future<bool> isLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kLockEnabled) ?? false;
  }

  Future<void> setLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLockEnabled, enabled);
    if (!enabled) {
      // 取消鎖時把 PIN/biometric 也清掉
      await prefs.remove(_kPinHash);
      await prefs.remove(_kPinSalt);
      await prefs.setBool(_kBiometricEnabled, false);
    }
  }

  Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kPinHash) != null;
  }

  Future<void> setPin(String pin) async {
    final salt = _randomSalt();
    final hash = _hash(pin, salt);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPinSalt, salt);
    await prefs.setString(_kPinHash, hash);
    await prefs.setBool(_kLockEnabled, true);
  }

  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final salt = prefs.getString(_kPinSalt);
    final hash = prefs.getString(_kPinHash);
    if (salt == null || hash == null) return false;
    return _hash(pin, salt) == hash;
  }

  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kBiometricEnabled) ?? false;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBiometricEnabled, enabled);
  }

  Future<bool> canCheckBiometric() async {
    final auth = LocalAuthentication();
    try {
      final supported = await auth.isDeviceSupported();
      if (!supported) return false;
      return await auth.canCheckBiometrics;
    } catch (e) {
      debugPrint('canCheckBiometric: $e');
      return false;
    }
  }

  Future<bool> authenticateBiometric({String reason = '請驗證身分以解鎖記帳本'}) async {
    final auth = LocalAuthentication();
    try {
      return await auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      debugPrint('authenticateBiometric: $e');
      return false;
    }
  }

  String _hash(String pin, String salt) {
    return sha256.convert(utf8.encode('$salt:$pin')).toString();
  }

  String _randomSalt() {
    final now = DateTime.now().microsecondsSinceEpoch;
    return base64Url.encode(utf8.encode('$now-${now * 7}'));
  }
}
