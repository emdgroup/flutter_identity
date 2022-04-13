import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:emd_flutter_boilerplate/services/desktop/auth_utils.dart';
import 'package:emd_flutter_boilerplate/services/oauth_handler.dart';
import 'package:http/http.dart';

import 'package:url_launcher/url_launcher.dart';

import 'callback_server.dart';
import 'oauth_requests.dart';
import 'oauth_token_result.dart';
// Needs to: open a web browser, get the code, and return it

class DesktopAuth with OAuthHandler {
  final String discoveryUrl;
  final String clientId;
  final List<String> scopes;
  final int port;

  DesktopAuth(
      {required this.discoveryUrl,
      required this.clientId,
      this.port = 8080,
      required this.scopes});

  @override
  Future<OAuthTokenResult> login() async {
    String rawChallenge = generateChallenge();

    String challengeHash = base64UrlEncode(hashChallenge(rawChallenge));

    // Fetch the authorization URL
    var discoveryResponse = await getOAuthDiscoveryResponse(
      discoveryUrl: discoveryUrl,
    );

    // Make sure the server supports the right code_challenge_methods_supported
    if (!discoveryResponse.codeChallengeMethodsSupported.contains("S256")) {
      throw Exception("Server does not support S256 code_cahllenge_method.");
    }

    // Request the authorization URL

    var authUrl = discoveryResponse.authorizationEndpoint;

    var tokenUrl = discoveryResponse.tokenEndpoint;

    var query = {
      "client_id": clientId,
      "response_type": "code",
      "redirect_uri": "http://localhost:8080/login-callback",
      "code_challenge": challengeHash,
      "code_challenge_method": "S256",
      "scope": "openid",
    };

    // Get the auth url
    var url = Uri.parse(authUrl);
    url = url.replace(queryParameters: query);

    // Open the browser
    await launch(url.toString());

    // Setup a local server to listen for the callback

    var code = await setupCallbackServer(port: port);

    // get the auth token
    return fetchTokens(
        authCode: code,
        rawChallenge: rawChallenge,
        clientId: clientId,
        tokenUrl: tokenUrl);
  }

  @override
  Future<OAuthTokenResult> refreshAccessToken(String refreshToken) async {
    var discoveryResponse = await getOAuthDiscoveryResponse(
      discoveryUrl: discoveryUrl,
    );

    var tokenUrl = discoveryResponse.tokenEndpoint;

    var query = {
      "client_id": clientId,
      "grant_type": "refresh_token",
      "refresh_token": refreshToken,
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
}
