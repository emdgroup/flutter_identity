// Used to return the tokens to the caller

import 'package:json_annotation/json_annotation.dart';

part 'oauth_token_result.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class OAuthTokenResult {
  String? accessToken;
  String? refreshToken;
  String? idToken;
  int expiresIn;
  OAuthTokenResult({
    this.accessToken,
    this.refreshToken,
    this.idToken,
    required this.expiresIn,
  });

  factory OAuthTokenResult.fromJson(Map<String, dynamic> json) =>
      _$OAuthTokenResultFromJson(json);
}
