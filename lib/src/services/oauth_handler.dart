import 'desktop/oauth_token_result.dart';

abstract class OAuthHandler {
  Future<OAuthTokenResult?> login();
  Future<OAuthTokenResult> refreshAccessToken(String refreshToken);
}
