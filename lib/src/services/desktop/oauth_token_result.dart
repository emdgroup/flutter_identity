// Used to return the tokens to the caller

import 'package:json_annotation/json_annotation.dart';

part 'oauth_token_result.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)

/// The result from the OAuth token endpoint
class OAuthTokenResult {
  /// Creates a new [OAuthTokenResult]
  OAuthTokenResult({
    required this.expiresIn,
    this.accessToken,
    this.refreshToken,
    this.idToken,
  });

  /// Creates a new [OAuthTokenResult] from a JSON map
  factory OAuthTokenResult.fromJson(Map<String, dynamic> json) =>
      _$OAuthTokenResultFromJson(json);

  /// Access token
  String? accessToken;

  /// Refresh token used to refresh the access token
  String? refreshToken;

  /// ID token (contains user info)
  String? idToken;

  /// The number of seconds until the access token expires
  int expiresIn;
}
