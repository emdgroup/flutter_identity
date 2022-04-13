import 'package:json_annotation/json_annotation.dart';

part 'oauth_discovery_response.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class OAuthDiscoveryResponse {
  String authorizationEndpoint;
  List<String> idTokenSigningAlgValuesSupported;
  List<String> codeChallengeMethodsSupported;
  String issuer;
  String jwksUri;
  List<String> responseTypesSupported;
  List<String> grantTypesSupported;
  List<String> scopesSupported;
  List<String> claimsSupported;
  List<String> subjectTypesSupported;
  String tokenEndpoint;
  List<String> tokenEndpointAuthMethodsSupported;
  String userinfoEndpoint;

  OAuthDiscoveryResponse({
    required this.authorizationEndpoint,
    required this.idTokenSigningAlgValuesSupported,
    required this.codeChallengeMethodsSupported,
    required this.issuer,
    required this.jwksUri,
    required this.responseTypesSupported,
    required this.grantTypesSupported,
    required this.scopesSupported,
    required this.claimsSupported,
    required this.subjectTypesSupported,
    required this.tokenEndpoint,
    required this.tokenEndpointAuthMethodsSupported,
    required this.userinfoEndpoint,
  });

  factory OAuthDiscoveryResponse.fromJson(Map<String, dynamic> json) =>
      _$OAuthDiscoveryResponseFromJson(json);
}
