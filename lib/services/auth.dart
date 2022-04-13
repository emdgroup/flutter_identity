import 'dart:async';
import 'dart:io';

import 'package:emd_flutter_boilerplate/services/desktop/desktop_auth.dart';
import 'package:emd_flutter_boilerplate/services/desktop/oauth_token_result.dart';
import 'package:emd_flutter_boilerplate/services/oauth_handler.dart';
import 'package:emd_flutter_boilerplate/services/token_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
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

  late SharedPreferences prefs;

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
    prefs = await SharedPreferences.getInstance();

    if (hasRefreshToken) {
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

  bool get hasRefreshToken => prefs.containsKey(prefsRefreshToken);
  bool get isLoggedIn => _status == AuthServiceStatus.loggedIn;

  // Token getters
  String? get refreshToken => prefs.getString(prefsRefreshToken);
  String? get accessToken => prefs.getString(prefsAccessToken);
  String? get idToken => prefs.getString(prefsIdToken);

  // Return a map  of claims in the id token
  Map<String, dynamic>? get idClaims =>
      idToken != null ? getTokenPayload(idToken!) : null;

  // Return the DateTime when the access token expires
  DateTime? get accessTokenExpiresAt {
    var expiry = prefs.getString(prefsAccessTokenExpiry);
    if (expiry != null) {
      return DateTime.parse(expiry);
    }
    return null;
  }

  void _startRefreshTimer() {
    // Cancel any existing timer
    _refreshTimer?.cancel();

    // Start a new timer
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      // Check if the access token will expire (or has expired) in 1 minute
      if (accessTokenExpiresAt != null &&
          accessTokenExpiresAt!
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

    var result = await _handler.refreshAccessToken(refreshToken!);

    // Store the new tokens
    _saveTokens(result);
    _status = AuthServiceStatus.loggedIn;
    notifyListeners();
  }

  // Persist all tokens in a TokenResponse
  void _saveTokens(OAuthTokenResult response) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    prefs.setString(prefsAccessToken, response.accessToken!);
    prefs.setString(
        prefsAccessTokenExpiry,
        DateTime.now()
            .add(Duration(seconds: response.expiresIn))
            .toIso8601String());

    if (response.refreshToken != null) {
      prefs.setString(prefsRefreshToken, response.refreshToken!);
    }

    if (response.idToken != null) {
      prefs.setString(prefsIdToken, response.idToken!);
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
