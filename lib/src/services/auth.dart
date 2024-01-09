import 'dart:async';

import 'package:emd_flutter_identity/src/services/oauth/oauth_token_result.dart';
import 'package:emd_flutter_identity/src/services/oauth_handler.dart';
import 'package:emd_flutter_identity/src/services/token_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The current status of the [AuthService]
enum AuthServiceStatus {
  /// Initial state of the service
  loading,

  /// Logged in
  loggedIn,

  /// Logged out
  loggedOut,
}

// Preference keys for storing the tokens.
String _prefsAccessToken = 'auth_service_access_token';
String _prefsRefreshToken = 'auth_service_refresh_token';
String _prefsIdToken = 'auth_service_id_token';
String _prefsAccessTokenExpiry = 'auth_service_access_token_expiry';

/// [AuthService] is used to handle authentication it automatically
///  refreshes tokens when needed.
class AuthService extends ChangeNotifier {
  // Service status
  AuthServiceStatus _status = AuthServiceStatus.loading;

  /// The current status of the [AuthService]
  AuthServiceStatus get status => _status;

  final _storage = const FlutterSecureStorage();

  late OAuthHandler _handler;

  /// Initialize the service with the platform specific handler
  Future<void> init({required OAuthHandler handler}) async {
    _handler = handler;
    await _init();
  }

  Future<void> _init() async {
    _status = AuthServiceStatus.loading;
    notifyListeners();

    if (await hasRefreshToken) {
      // Theres a refresh token. Since we are starting.
      // Fetch a new access token.
      await _refreshAccessToken();
    } else {
      // No refresh token. We are logged out.
      _status = AuthServiceStatus.loggedOut;
      notifyListeners();
    }
  }

  /// Whether there is a refresh token stored
  Future<bool> get hasRefreshToken async {
    return (await _storage.read(key: _prefsRefreshToken)) != null;
  }

  /// Whether the user is logged in
  bool get isLoggedIn => _status == AuthServiceStatus.loggedIn;

  /// Get the current refresh token
  Future<String?> get refreshToken => _storage.read(key: _prefsRefreshToken);

  /// Get the current access token, refreshes is if needed
  Future<String?> get accessToken async {
    if (await _shouldRefresh) {
      await _refreshAccessToken();
    }

    return _storage.read(key: _prefsAccessToken);
  }

  /// Get the current id token
  Future<String?> get idToken => _storage.read(key: _prefsIdToken);

  /// Return a map  of claims in the id token
  Future<Map<String, dynamic>?> get idClaims async {
    final token = await idToken;

    return token != null ? getTokenPayload(token) : null;
  }

  /// Return the DateTime when the access token expires
  Future<DateTime?> get accessTokenExpiresAt async {
    final expiry = await _storage.read(key: _prefsAccessTokenExpiry);
    if (expiry != null) {
      return DateTime.parse(expiry);
    }
    return null;
  }

  Future<bool> get _shouldRefresh async {
    // Refresh 1 minute early to compensate timing differences.
    const buffer = Duration(minutes: 1);
    final expiry = await accessTokenExpiresAt;
    return expiry != null && expiry.isBefore(DateTime.now().subtract(buffer));
  }

  /// Forces a refresh independent of the expiry time
  Future<void> forceRefresh() async {
    await _refreshAccessToken();
  }

  Future<void> _refreshAccessToken() async {
    final refreshToken = await this.refreshToken;
    if (refreshToken == null) {
      throw Exception('No refresh token');
    }

    final result = await _handler.refreshAccessToken(refreshToken);

    // Store the new tokens
    await _saveTokens(result);
    _status = AuthServiceStatus.loggedIn;
    notifyListeners();
  }

  // Persist all tokens in a TokenResponse
  Future<void> _saveTokens(OAuthTokenResult response) async {
    await _storage.write(key: _prefsAccessToken, value: response.accessToken);
    await _storage.write(
      key: _prefsAccessTokenExpiry,
      value: DateTime.now()
          .add(Duration(seconds: response.expiresIn))
          .toIso8601String(),
    );

    if (response.refreshToken != null) {
      await _storage.write(
        key: _prefsRefreshToken,
        value: response.refreshToken,
      );
    }

    if (response.idToken != null) {
      await _storage.write(key: _prefsIdToken, value: response.idToken);
    }
  }

  /// Try to log the user in. Returns a
  /// future bool whether the attempt was successful.
  Future<bool> login() async {
    final result = await _handler.login();
    if (result != null) {
      await _saveTokens(result);
      _status = AuthServiceStatus.loggedIn;
      notifyListeners();
      return true;
    } else {
      _status = AuthServiceStatus.loggedOut;

      notifyListeners();
    }
    return false;
  }

  /// Log the user out, deletes all tokens
  Future<void> logout() async {
    final accessToken = await this.accessToken;
    if (accessToken == null) {
      throw Exception('No access token to logout');
    }
    await _storage.delete(key: _prefsAccessToken);
    await _storage.delete(key: _prefsRefreshToken);
    await _storage.delete(key: _prefsIdToken);
    await _storage.delete(key: _prefsAccessTokenExpiry);
    _status = AuthServiceStatus.loggedOut;

    notifyListeners();
  }
}
