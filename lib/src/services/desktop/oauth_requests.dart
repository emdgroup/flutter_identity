import 'dart:convert';

import 'package:http/http.dart';

import 'oauth_discovery_response.dart';
import 'oauth_token_result.dart';

Future<OAuthDiscoveryResponse> getOAuthDiscoveryResponse({required String discoveryUrl}) async {
  /*var res = await get(Uri.parse(discoveryUrl));
  if (res.statusCode != 200) {
    throw Exception("Failed to fetch discovery document.");
  }*/

  var res =
      '{"authorization_endpoint":"https://login.emddigital.com/oauth2/authorize","id_token_signing_alg_values_supported":["RS256"],"code_challenge_methods_supported":["S256"],"issuer":"https://login.emddigital.com/","jwks_uri":"https://login.emddigital.com/.well-known/jwks.json","response_types_supported":["code"],"grant_types_supported":["authorization_code"],"scopes_supported":["openid","email","profile"],"claims_supported":["sub","iss","email"],"subject_types_supported":["pairwise"],"token_endpoint":"https://login.emddigital.com/oauth2/token","token_endpoint_auth_methods_supported":["client_secret_basic"],"userinfo_endpoint":"https://login.emddigital.com/oauth2/userinfo"}';

  return OAuthDiscoveryResponse.fromJson(json.decode(res));
}

Future<OAuthTokenResult> fetchTokens(
    {required String authCode,
    required String rawChallenge,
    required String clientId,
    required String tokenUrl}) async {
  var query = {
    "client_id": clientId,
    "code": authCode,
    "redirect_uri": "http://localhost:8000/#/login-callback",
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
