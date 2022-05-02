import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:emd_flutter_identity/src/services/token_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'desktop/desktop_auth.dart';
import 'desktop/oauth_token_result.dart';
import 'mobile/mobile_auth.dart';
import 'oauth_handler.dart';

enum AuthServiceStatus {
  loading, // Initial state of the service
  loggedIn, // Logged in
  loggedOut, // Logged out

}

// Preference keys for storing the tokens.
String prefsAccessToken = "auth_service_access_token";
String prefsRefreshToken = "auth_service_refresh_token";
String prefsIdToken = "auth_service_id_token";
String prefsAccessTokenExpiry = "auth_service_access_token_expiry";

class AuthService extends ChangeNotifier {
  // Service status
  AuthServiceStatus _status = AuthServiceStatus.loading;
  AuthServiceStatus get status => _status;

  // Scopes requested
  List<String> scopes = ["openid", "email"];

  //  Timer that refreshes the access token
  Timer? _refreshTimer;

  final _storage = const FlutterSecureStorage();

  late OAuthHandler _handler;

  AuthService({
    required String discoveryUrl,
    required String clientId,
    required String redirectUrl,
    required List<String> scopes,
  }) {
    if (Platform.isAndroid || Platform.isIOS) {
      _handler = MobileAuth(
        discoveryUrl: discoveryUrl,
        clientId: clientId,
        redirectUrl: redirectUrl,
        scopes: scopes,
      );
    }

    if (Platform.isMacOS || Platform.isWindows) {
      _handler = DesktopAuth(
        discoveryUrl: discoveryUrl,
        clientId: clientId,
        scopes: scopes,
      );
    }

    // ignore: unnecessary_null_comparison
    if (_handler == null) {
      throw Exception("Unsupported platform");
    }

    _init();
  }

  Future<void> _init() async {
    _status = AuthServiceStatus.loading;
    notifyListeners();

    if (await hasRefreshToken) {
      // Theres a refresh token. Since we are starting. Fetch a new access token.
      await _refreshAccessToken();
    } else {
      // No refresh token. We are logged out.
      _status = AuthServiceStatus.loggedOut;
      notifyListeners();
    }

    // Start the refresh timer
    _startRefreshTimer();

    SystemChannels.lifecycle.setMessageHandler((msg) async {
      if (msg == AppLifecycleState.resumed.toString()) {
        resurrect();
      }
      return null;
    });
  }

  void resurrect() {
    // Restart timer

    _startRefreshTimer();
  }

  Future<bool> get hasRefreshToken async {
    return (await _storage.read(key: prefsRefreshToken)) != null;
  }

  bool get isLoggedIn => _status == AuthServiceStatus.loggedIn;

  // Token getters
  Future<String?> get refreshToken => _storage.read(key: prefsRefreshToken);
  Future<String?> get accessToken => _storage.read(key: prefsAccessToken);
  Future<String?> get idToken => _storage.read(key: prefsIdToken);

  // Return a map  of claims in the id token
  Future<Map<String, dynamic>?> get idClaims async {
    return await idToken != null ? getTokenPayload((await idToken)!) : null;
  }

  // Return the DateTime when the access token expires
  Future<DateTime?> get accessTokenExpiresAt async {
    var expiry = await _storage.read(key: prefsAccessTokenExpiry);
    if (expiry != null) {
      return DateTime.parse(expiry);
    }
    return null;
  }

  Future<bool> get _shouldRefresh async {
    // Refresh 1 minute early to compensate timing differences.
    var buffer = const Duration(minutes: 1);
    var expiry = await accessTokenExpiresAt;
    return expiry != null && expiry.isBefore(DateTime.now().subtract(buffer));
  }

  Future<void> _refreshTimerTick() async {
    if (await _shouldRefresh) {
      // The access token has expired. Refresh it.
      try {
        await _refreshAccessToken();
      } catch (e) {
        // If refreshing fails, signal to the application that the user might not be logged in anymore
        _status = AuthServiceStatus.loggedOut;
      }
    }
    notifyListeners();
  }

  void _startRefreshTimer() async {
    // Cancel any existing timer
    _refreshTimer?.cancel();
    await _refreshTimerTick();
    // Start a new timer
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      await _refreshTimerTick();
    });
  }

  /// Forces a refresh independent of the expiry time
  void forceRefresh() {
    _refreshAccessToken();
  }

  Future<void> _refreshAccessToken() async {
    var refreshToken = await this.refreshToken;
    if (refreshToken == null) {
      throw Exception("No refresh token");
    }

    var result = await _handler.refreshAccessToken(refreshToken);

    // Store the new tokens
    _saveTokens(result);
    _status = AuthServiceStatus.loggedIn;
    notifyListeners();
  }
  
  // Persist all tokens in a TokenResponse
  void _saveTokens(OAuthTokenResult response) async {
    _storage.write(key: prefsAccessToken, value: response.accessToken!);
    _storage.write(
        key: prefsAccessTokenExpiry,
        value: DateTime.now()
            .add(Duration(seconds: response.expiresIn))
            .toIso8601String());

    if (response.refreshToken != null) {
      _storage.write(key: prefsRefreshToken, value: response.refreshToken!);
    }

    if (response.idToken != null) {
      _storage.write(key: prefsIdToken, value: response.idToken!);
    }
  }

  // Try to log the user in. Returns a future bool whether the attempt was successful.
  Future<void> login() async {
    var result = await _handler.login();
    _saveTokens(result);
    _status = AuthServiceStatus.loggedIn;
    notifyListeners();
  }

  Future<void> logout() async {
    _storage.delete(key: prefsAccessToken);
    _storage.delete(key: prefsRefreshToken);
    _storage.delete(key: prefsIdToken);
    _storage.delete(key: prefsAccessTokenExpiry);
    _status = AuthServiceStatus.loggedOut;
    notifyListeners();
  }
}
