import 'package:flutter_appauth/flutter_appauth.dart';

import '../desktop/oauth_token_result.dart';
import '../oauth_handler.dart';

class MobileAuth with OAuthHandler {
  final String discoveryUrl;
  final String clientId;
  final String redirectUrl;
  final List<String> scopes;

  final FlutterAppAuth appAuth = FlutterAppAuth();

  MobileAuth({
    required this.discoveryUrl,
    required this.clientId,
    required this.redirectUrl,
    required this.scopes,
  });

  @override
  Future<OAuthTokenResult> login() async {
    final AuthorizationTokenResponse? result =
        await appAuth.authorizeAndExchangeCode(AuthorizationTokenRequest(
      clientId,
      redirectUrl,
      discoveryUrl: discoveryUrl,
      scopes: scopes,
    ));
    if (result == null) {
      throw Exception("Failed to login. No result was returned");
    }
    return OAuthTokenResult(
      accessToken: result.accessToken!,
      refreshToken: result.refreshToken!,
      expiresIn: result.accessTokenExpirationDateTime!
          .difference(DateTime.now())
          .inSeconds,
      idToken: result.idToken!,
    );
  }

  @override
  Future<OAuthTokenResult> refreshAccessToken(
    String refreshToken,
  ) async {
    final TokenResponse? result = await appAuth.token(TokenRequest(
        clientId, redirectUrl,
        discoveryUrl: discoveryUrl,
        refreshToken: refreshToken,
        scopes: scopes));

    if (result == null) {
      throw Exception("Failed to refresh access token. No result was returned");
    }

    return OAuthTokenResult(
      accessToken: result.accessToken!,
      refreshToken: result.refreshToken,
      expiresIn: result.accessTokenExpirationDateTime!
          .difference(DateTime.now())
          .inSeconds,
      idToken: result.idToken,
    );
  }
}
