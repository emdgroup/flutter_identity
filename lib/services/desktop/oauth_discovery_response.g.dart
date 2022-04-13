// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'oauth_discovery_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OAuthDiscoveryResponse _$OAuthDiscoveryResponseFromJson(
        Map<String, dynamic> json) =>
    OAuthDiscoveryResponse(
      authorizationEndpoint: json['authorization_endpoint'] as String,
      idTokenSigningAlgValuesSupported:
          (json['id_token_signing_alg_values_supported'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
      codeChallengeMethodsSupported:
          (json['code_challenge_methods_supported'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
      issuer: json['issuer'] as String,
      jwksUri: json['jwks_uri'] as String,
      responseTypesSupported:
          (json['response_types_supported'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
      grantTypesSupported: (json['grant_types_supported'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      scopesSupported: (json['scopes_supported'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      claimsSupported: (json['claims_supported'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      subjectTypesSupported: (json['subject_types_supported'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      tokenEndpoint: json['token_endpoint'] as String,
      tokenEndpointAuthMethodsSupported:
          (json['token_endpoint_auth_methods_supported'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
      userinfoEndpoint: json['userinfo_endpoint'] as String,
    );

Map<String, dynamic> _$OAuthDiscoveryResponseToJson(
        OAuthDiscoveryResponse instance) =>
    <String, dynamic>{
      'authorization_endpoint': instance.authorizationEndpoint,
      'id_token_signing_alg_values_supported':
          instance.idTokenSigningAlgValuesSupported,
      'code_challenge_methods_supported':
          instance.codeChallengeMethodsSupported,
      'issuer': instance.issuer,
      'jwks_uri': instance.jwksUri,
      'response_types_supported': instance.responseTypesSupported,
      'grant_types_supported': instance.grantTypesSupported,
      'scopes_supported': instance.scopesSupported,
      'claims_supported': instance.claimsSupported,
      'subject_types_supported': instance.subjectTypesSupported,
      'token_endpoint': instance.tokenEndpoint,
      'token_endpoint_auth_methods_supported':
          instance.tokenEndpointAuthMethodsSupported,
      'userinfo_endpoint': instance.userinfoEndpoint,
    };
