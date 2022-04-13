import 'package:emd_flutter_boilerplate/services/desktop/oauth_token_result.dart';

abstract class OAuthHandler {
  Future<OAuthTokenResult> login();
  Future<OAuthTokenResult> refreshAccessToken(String refreshToken);
}
