// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'oauth_token_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OAuthTokenResult _$OAuthTokenResultFromJson(Map<String, dynamic> json) =>
    OAuthTokenResult(
      accessToken: json['access_token'] as String?,
      refreshToken: json['refresh_token'] as String?,
      idToken: json['id_token'] as String?,
      expiresIn: json['expires_in'] as int,
    );

Map<String, dynamic> _$OAuthTokenResultToJson(OAuthTokenResult instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
      'id_token': instance.idToken,
      'expires_in': instance.expiresIn,
    };
