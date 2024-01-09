import 'package:emd_flutter_identity/src/services/oauth/oauth_token_result.dart';
import 'package:emd_flutter_identity/src/services/oauth_handler.dart';
import 'package:flutter_appauth/flutter_appauth.dart';

/// [MobileAuth] is used to handle authentication for desktop apps
class MobileAuth with OAuthHandler {
  /// Initialize mobile auth with the required parameters
  MobileAuth({
    required String discoveryUrl,
    required String clientId,
    required String redirectUrl,
    required List<String> scopes,
  })  : _scopes = scopes,
        _redirectUrl = redirectUrl,
        _clientId = clientId,
        _discoveryUrl = discoveryUrl;
  final String _discoveryUrl;
  final String _clientId;
  final String _redirectUrl;

  final List<String> _scopes;

  final FlutterAppAuth _appAuth = const FlutterAppAuth();

  @override
  Future<OAuthTokenResult> login() async {
    final result = await _appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        _clientId,
        _redirectUrl,
        discoveryUrl: _discoveryUrl,
        scopes: _scopes,
      ),
    );
    if (result == null) {
      throw Exception('Failed to login. No result was returned');
    }
    return OAuthTokenResult(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
      idToken: result.idToken,
      expiresIn: result.accessTokenExpirationDateTime!
          .difference(DateTime.now())
          .inSeconds,
    );
  }

  @override
  Future<OAuthTokenResult> refreshAccessToken(
    String refreshToken,
  ) async {
    final result = await _appAuth.token(
      TokenRequest(
        _clientId,
        _redirectUrl,
        discoveryUrl: _discoveryUrl,
        refreshToken: refreshToken,
        scopes: _scopes,
      ),
    );

    if (result == null) {
      throw Exception('Failed to refresh access token. No result was returned');
    }

    return OAuthTokenResult(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
      expiresIn: result.accessTokenExpirationDateTime!
          .difference(DateTime.now())
          .inSeconds,
      idToken: result.idToken,
    );
  }
}
