import 'dart:async';
import 'dart:convert';

import 'package:emd_flutter_identity/src/services/desktop/auth_utils.dart';
import 'package:emd_flutter_identity/src/services/desktop/callback_server.dart';
import 'package:emd_flutter_identity/src/services/oauth/oauth_requests.dart';
import 'package:emd_flutter_identity/src/services/oauth/oauth_token_result.dart';
import 'package:emd_flutter_identity/src/services/oauth_handler.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher.dart';
// Needs to: open a web browser, get the code, and return it

/// [DesktopAuth] is used to handle authentication for desktop apps
class DesktopAuth with OAuthHandler {
  /// Creates a new [DesktopAuth] instance
  DesktopAuth({
    required String logoutUrl,
    required String discoveryUrl,
    required String clientId,
    required List<String> scopes,
    int port = 8080,
  })  : _port = port,
        _discoveryUrl = discoveryUrl,
        _logoutUrl = logoutUrl,
        _scopes = scopes,
        _clientId = clientId;

  final String _logoutUrl;
  final String _discoveryUrl;
  final String _clientId;
  final List<String> _scopes;
  final int _port;

  @override
  Future<OAuthTokenResult> login() async {
    final rawChallenge = generateChallenge();

    final challengeHash = base64UrlEncode(hashChallenge(rawChallenge));

    // Fetch the authorization URL
    final discoveryResponse = await getOAuthDiscoveryResponse(
      discoveryUrl: _discoveryUrl,
    );

    // Make sure the server supports the right code_challenge_methods_supported
    if (!discoveryResponse.codeChallengeMethodsSupported.contains('S256')) {
      throw Exception('Server does not support S256 code_challenge_method.');
    }

    // Request the authorization URL

    final authUrl = discoveryResponse.authorizationEndpoint;

    final tokenUrl = discoveryResponse.tokenEndpoint;

    final query = {
      'client_id': _clientId,
      'response_type': 'code',
      'redirect_uri': 'http://localhost:8080/login-callback',
      'code_challenge': challengeHash,
      'code_challenge_method': 'S256',
      'prompt': 'login',
      'scope': _scopes.join(' '),
    };

    // Get the auth url
    var url = Uri.parse(authUrl);
    url = url.replace(queryParameters: query);

    // Open the browser
    await launchUrl(url);

    // Setup a local server to listen for the callback

    final code = await setupCallbackServer(port: _port);

    // get the auth token
    return fetchTokens(
      authCode: code,
      rawChallenge: rawChallenge,
      clientId: _clientId,
      tokenUrl: tokenUrl,
    );
  }

  @override
  Future<OAuthTokenResult> refreshAccessToken(String refreshToken) async {
    final discoveryResponse = await getOAuthDiscoveryResponse(
      discoveryUrl: _discoveryUrl,
    );

    final tokenUrl = discoveryResponse.tokenEndpoint;

    final query = {
      'client_id': _clientId,
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken,
    };

    final url = Uri.parse(tokenUrl);

    final res = await post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: query,
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to fetch tokens.');
    }

    return OAuthTokenResult.fromJson(
      json.decode(res.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> logout(String accessToken) async {
    await logoutIdp(
      logoutUrl: _logoutUrl,
      clientId: _clientId,
      accessToken: accessToken,
    );
  }
}
