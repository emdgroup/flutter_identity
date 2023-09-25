import 'package:json_annotation/json_annotation.dart';

part 'oauth_discovery_response.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)

/// The response from the OAuth discovery endpoint
class OAuthDiscoveryResponse {
  /// Creates a new [OAuthDiscoveryResponse]
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

  /// Creates a new [OAuthDiscoveryResponse] from a JSON map
  factory OAuthDiscoveryResponse.fromJson(Map<String, dynamic> json) =>
      _$OAuthDiscoveryResponseFromJson(json);

  /// The authorization endpoint
  String authorizationEndpoint;

  /// The supported signing algorithms
  List<String> idTokenSigningAlgValuesSupported;

  /// The supported code challenge methods
  List<String> codeChallengeMethodsSupported;

  /// The issuer
  String issuer;

  /// The JWKS URI
  String jwksUri;

  /// The supported response types
  List<String> responseTypesSupported;

  /// The supported grant types
  List<String> grantTypesSupported;

  /// The supported scopes
  List<String> scopesSupported;

  /// The supported claims
  List<String> claimsSupported;

  /// The supported subject types
  List<String> subjectTypesSupported;

  /// The token endpoint
  String tokenEndpoint;

  /// The supported token endpoint auth methods
  List<String> tokenEndpointAuthMethodsSupported;

  /// The userinfo endpoint
  String userinfoEndpoint;
}
