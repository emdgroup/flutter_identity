import 'dart:async';
import 'dart:convert';

import 'package:emd_flutter_identity/src/services/desktop/auth_utils.dart';
import 'package:emd_flutter_identity/src/services/oauth/oauth_requests.dart';
import 'package:emd_flutter_identity/src/services/oauth/oauth_token_result.dart';
import 'package:emd_flutter_identity/src/services/oauth_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import 'package:universal_html/html.dart';
import 'package:url_launcher/url_launcher.dart';

/// [WebAuth] is used to handle authentication for web apps
class WebAuth with OAuthHandler {
  /// Creates a new [WebAuth] instance
  WebAuth({
    required String logoutUrl,
    required String discoveryUrl,
    required String clientId,
    required List<String> scopes,
    String? redirectUrl,
  })  : _scopes = scopes,
        _redirectUrl = redirectUrl,
        _clientId = clientId,
        _logoutUrl = logoutUrl,
        _discoveryUrl = discoveryUrl;

  final String _logoutUrl;
  final String _discoveryUrl;
  final _storage = const FlutterSecureStorage();
  final String _clientId;
  final List<String> _scopes;
  final String? _redirectUrl;

  @override
  Future<OAuthTokenResult?> login() async {
    // Fetch the authorization URL
    final discoveryResponse = await getOAuthDiscoveryResponse(
      discoveryUrl: _discoveryUrl,
    );

    // Make sure the server supports the right code_challenge_methods_supported
    if (!discoveryResponse.codeChallengeMethodsSupported.contains('S256')) {
      throw Exception('Server does not support S256 code_challenge_method.');
    }
    final location = Uri.parse(window.location.href.replaceAll('/#', ''));

    if (location.queryParameters.containsKey('code')) {
      final rawChallenge = await _storage.read(key: 'web_auth_raw_challenge');
      if (rawChallenge == null) {
        throw Exception('No auth flow previously started');
      }

      return fetchTokens(
        authCode: location.queryParameters['code']!,
        rawChallenge: rawChallenge,
        clientId: _clientId,
        tokenUrl: discoveryResponse.tokenEndpoint,
      );
    }

    final rawChallenge = generateChallenge();
    await _storage.write(key: 'web_auth_raw_challenge', value: rawChallenge);

    final challengeHash = base64UrlEncode(hashChallenge(rawChallenge));

    // Request the authorization URL

    final authUrl = discoveryResponse.authorizationEndpoint;

    final query = {
      'client_id': _clientId,
      'response_type': 'code',
      'redirect_uri': _redirectUrl ??
          '${window.location.protocol}//${window.location.host}/#/login-callback',
      'code_challenge': challengeHash,
      'code_challenge_method': 'S256',
      'scope': _scopes.join(' '),
    };

    // Get the auth url
    var url = Uri.parse(authUrl);
    url = url.replace(queryParameters: query);

    // Open the browser
    await launchUrl(
      url,
      mode: LaunchMode.inAppWebView,
      webOnlyWindowName: '_self',
    );
    return null;

    // Setup a local server to listen for the callback
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
  Future<void> logout( String accessToken) async {
    await logoutIdp(logoutUrl: _logoutUrl, clientId: _clientId, accessToken: accessToken );
  }
}
