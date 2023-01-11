import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher.dart';

import '../desktop/auth_utils.dart';
import '../desktop/oauth_requests.dart';
import '../desktop/oauth_token_result.dart';
import '../oauth_handler.dart';

// Needs to: open a web browser, get the code, and return it

class WebAuth with OAuthHandler {
  final String discoveryUrl;
  final _storage = const FlutterSecureStorage();
  final String clientId;
  final List<String> scopes;
  final String? redirectUrl;
  final int port;

  WebAuth(
      {required this.discoveryUrl,
      this.redirectUrl,
      required this.clientId,
      this.port = 80,
      required this.scopes});

  @override
  Future<OAuthTokenResult?> login() async {
    // Fetch the authorization URL
    var discoveryResponse = await getOAuthDiscoveryResponse(
      discoveryUrl: discoveryUrl,
    );

    // Make sure the server supports the right code_challenge_methods_supported
    if (!discoveryResponse.codeChallengeMethodsSupported.contains("S256")) {
      throw Exception("Server does not support S256 code_challenge_method.");
    }
    var location = Uri.parse(window.location.href.replaceAll("/#", ""));

    if (location.queryParameters.containsKey("code")) {
      var rawChallenge = await _storage.read(key: "web_auth_raw_challenge");
      if (rawChallenge == null) {
        throw Exception("No auth flow previously started");
      }

      return await fetchTokens(
          authCode: location.queryParameters["code"]!,
          rawChallenge: rawChallenge,
          clientId: clientId,
          tokenUrl: discoveryResponse.tokenEndpoint);
    }

    String rawChallenge = generateChallenge();
    _storage.write(key: "web_auth_raw_challenge", value: rawChallenge);

    String challengeHash = base64UrlEncode(hashChallenge(rawChallenge));

    // Request the authorization URL

    var authUrl = discoveryResponse.authorizationEndpoint;

    var query = {
      "client_id": clientId,
      "response_type": "code",
      "redirect_uri": redirectUrl ??
          window.location.protocol + "//" + window.location.host + "/#/login-callback",
      "code_challenge": challengeHash,
      "code_challenge_method": "S256",
      "scope": "openid",
    };

    // Get the auth url
    var url = Uri.parse(authUrl);
    url = url.replace(queryParameters: query);

    // Open the browser
    await launchUrl(url, mode: LaunchMode.inAppWebView, webOnlyWindowName: "_self");
    return null;

    // Setup a local server to listen for the callback
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
