import 'dart:async';
import 'dart:io';

import 'package:emd_flutter_boilerplate/services/desktop/desktop_auth.dart';
import 'package:emd_flutter_boilerplate/services/desktop/oauth_token_result.dart';
import 'package:emd_flutter_boilerplate/services/oauth_handler.dart';
import 'package:emd_flutter_boilerplate/services/token_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../env.dart';
import 'mobile/mobile_auth.dart';

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

  AuthService() {
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

  void _startRefreshTimer() {
    // Cancel any existing timer
    _refreshTimer?.cancel();

    // Start a new timer
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      // Check if the access token will expire (or has expired) in 1 minute
      var expiry = await accessTokenExpiresAt;

      if (expiry != null &&
          expiry
              .isBefore(DateTime.now().subtract(const Duration(minutes: 1)))) {
        // The access token has expired. Refresh it.
        try {
          _refreshAccessToken();
          notifyListeners();
        } catch (e) {
          // If refreshing fails, signal to the application that the user might not be logged in anymore
          _status = AuthServiceStatus.loggedOut;
        }
      }
    });
  }

  void forceRefresh() {
    _refreshAccessToken();
  }

  _refreshAccessToken() async {
    if (refreshToken == null) {
      throw Exception("No refresh token");
    }

    var result = await _handler.refreshAccessToken((await refreshToken)!);

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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove(prefsAccessToken);
    prefs.remove(prefsRefreshToken);
    prefs.remove(prefsIdToken);
    prefs.remove(prefsAccessTokenExpiry);
    _status = AuthServiceStatus.loggedOut;
    notifyListeners();
  }
}
