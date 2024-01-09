import 'package:emd_flutter_identity/src/services/oauth/oauth_token_result.dart';

/// [OAuthHandler] is used to handle authentication for the different platforms
abstract class OAuthHandler {
  /// Login with the OAuth provider
  Future<OAuthTokenResult?> login();

  /// Refresh the access token
  Future<OAuthTokenResult> refreshAccessToken(String refreshToken);
}
