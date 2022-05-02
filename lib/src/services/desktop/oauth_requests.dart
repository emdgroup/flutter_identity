import 'dart:convert';

import 'package:http/http.dart';

import 'oauth_discovery_response.dart';
import 'oauth_token_result.dart';

Future<OAuthDiscoveryResponse> getOAuthDiscoveryResponse(
    {required String discoveryUrl}) async {
  var res = await get(Uri.parse(discoveryUrl));
  if (res.statusCode != 200) {
    throw Exception("Failed to fetch discovery document.");
  }
  return OAuthDiscoveryResponse.fromJson(json.decode(res.body));
}

Future<OAuthTokenResult> fetchTokens(
    {required String authCode,
    required String rawChallenge,
    required String clientId,
    required String tokenUrl}) async {
  var query = {
    "client_id": clientId,
    "code": authCode,
    "redirect_uri": "http://localhost:8080/login-callback",
    "code_verifier": rawChallenge,
    "grant_type": "authorization_code",
  };

  var url = Uri.parse(tokenUrl);

  var res = await post(url,
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: query);

  if (res.statusCode != 200) {
    throw Exception("Failed to fetch tokens.");
  }

  return OAuthTokenResult.fromJson(json.decode(res.body));
}
