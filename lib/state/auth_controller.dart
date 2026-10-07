import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../services/auth_api.dart';

const _kAccess = 'access_token';
const _kRefresh = 'refresh_token';
const _kExpiry = 'token_expiry_ms';
const _kUser = 'user_data_json';
const _kGuest = 'alworki_guest_session';

class AuthController extends ChangeNotifier {
  AuthController(this._api);

  final AuthApi _api;

  AppUser? user;
  String? accessToken;
  String? refreshToken;
  int? tokenExpiryMs;
  bool isLoading = false;
  String? lastError;

  bool get isGuest => user?.isGuest == true;

  bool get isLoggedIn =>
      user != null &&
      (isGuest || (accessToken != null && tokenExpiryMs != null && DateTime.now().millisecondsSinceEpoch < tokenExpiryMs!));

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final guest = prefs.getString(_kGuest);
    if (guest == '1') {
      user = AppUser.guest;
      accessToken = null;
      refreshToken = null;
      tokenExpiryMs = null;
      notifyListeners();
      return;
    }

    accessToken = prefs.getString(_kAccess);
    refreshToken = prefs.getString(_kRefresh);
    tokenExpiryMs = prefs.getInt(_kExpiry);
    final u = prefs.getString(_kUser);
    if (u != null && u.isNotEmpty) {
      try {
        user = AppUser.fromJson(jsonDecode(u) as Map<String, dynamic>);
      } catch (_) {
        user = null;
      }
    }

    if (accessToken != null && user != null && !isGuest) {
      final ok = await _api.verifyToken(accessToken!);
      if (!ok) {
        final refreshed = refreshToken != null ? await _api.refreshAccessToken(refreshToken!) : null;
        if (refreshed != null && refreshed['access_token'] != null) {
          accessToken = refreshed['access_token'] as String;
          final expSec = (refreshed['expires_in'] as num?)?.toInt() ?? 3600;
          tokenExpiryMs = DateTime.now().millisecondsSinceEpoch + expSec * 1000;
          await _persistTokens(prefs);
        } else {
          await clearSession();
          return;
        }
      }
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    isLoading = true;
    lastError = null;
    notifyListeners();
    try {
      final data = await _api.login(email, password);
      await _applyAuthResponse(data, clearGuest: true);
    } on AuthApiException catch (e) {
      lastError = e.message;
    } catch (e) {
      lastError = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstname,
    required String lastname,
  }) async {
    isLoading = true;
    lastError = null;
    notifyListeners();
    try {
      await _api.register(
        email: email,
        password: password,
        firstname: firstname,
        lastname: lastname,
      );
    } on AuthApiException catch (e) {
      lastError = e.message;
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> continueAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kGuest, '1');
    await prefs.remove(_kAccess);
    await prefs.remove(_kRefresh);
    await prefs.remove(_kExpiry);
    await prefs.setString(_kUser, jsonEncode(AppUser.guest.toJson()));
    user = AppUser.guest;
    accessToken = null;
    refreshToken = null;
    tokenExpiryMs = null;
    notifyListeners();
  }

  Future<void> logout() async {
    if (accessToken != null && !isGuest) {
      await _api.logout(accessToken!);
    }
    await clearSession();
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccess);
    await prefs.remove(_kRefresh);
    await prefs.remove(_kExpiry);
    await prefs.remove(_kUser);
    await prefs.remove(_kGuest);
    user = null;
    accessToken = null;
    refreshToken = null;
    tokenExpiryMs = null;
    notifyListeners();
  }

  Future<void> _applyAuthResponse(Map<String, dynamic> data, {required bool clearGuest}) async {
    final prefs = await SharedPreferences.getInstance();
    if (clearGuest) await prefs.remove(_kGuest);

    final at = data['access_token'] as String?;
    final rt = data['refresh_token'] as String?;
    final expSec = (data['expires_in'] as num?)?.toInt() ?? 3600;
    if (at == null) throw AuthApiException('Respuesta sin token');

    accessToken = at;
    refreshToken = rt;
    tokenExpiryMs = DateTime.now().millisecondsSinceEpoch + expSec * 1000;

    final u = data['user'];
    if (u is Map<String, dynamic>) {
      user = AppUser.fromJson(u);
      await prefs.setString(_kUser, jsonEncode(user!.toJson()));
    }

    await prefs.setString(_kAccess, at);
    if (rt != null) await prefs.setString(_kRefresh, rt);
    await prefs.setInt(_kExpiry, tokenExpiryMs!);
  }

  Future<void> _persistTokens(SharedPreferences prefs) async {
    if (accessToken != null) await prefs.setString(_kAccess, accessToken!);
    if (refreshToken != null) await prefs.setString(_kRefresh, refreshToken!);
    if (tokenExpiryMs != null) await prefs.setInt(_kExpiry, tokenExpiryMs!);
  }
}
