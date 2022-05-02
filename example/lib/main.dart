import 'dart:convert';

import 'package:emd_flutter_boilerplate/env.dart';
import 'package:emd_flutter_identity/emd_flutter_identity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'EMD Boilerplate',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Scaffold(
            appBar: AppBar(
              title: const Text('EMD Identity Boilerplate'),
            ),
            body: const AuthStatus()));
  }
}

class AuthStatus extends StatefulWidget {
  const AuthStatus({Key? key}) : super(key: key);

  @override
  State<AuthStatus> createState() => _AuthStatusState();
}

class _AuthStatusState extends State<AuthStatus> {
  final AuthService _auth = AuthService(
    redirectUrl: redirectUrl,
    discoveryUrl: discoveryUrl,
    scopes: ["openid", "email"],
    clientId: clientId,
  );

  String? _accesToken;
  String? _idToken;
  String? _refreshToken;
  DateTime? _expiresAt;
  Map<String, dynamic>? _idClaims;

  @override
  void initState() {
    _auth.addListener(_authChange);
    super.initState();
  }

  @override
  void dispose() {
    _auth.removeListener(_authChange);
    super.dispose();
  }

  void _authChange() async {
    // Plain re-render

    _accesToken = await _auth.accessToken;
    _idToken = await _auth.idToken;
    _expiresAt = await _auth.accessTokenExpiresAt;
    _refreshToken = await _auth.refreshToken;
    _idClaims = await _auth.idClaims;

    setState(() {});
  }

  String get _authStatusString {
    switch (_auth.status) {
      case AuthServiceStatus.loading:
        return "Loading";
      case AuthServiceStatus.loggedIn:
        return "Logged in";
      case AuthServiceStatus.loggedOut:
        return "Logged out";
      default:
        return "Unknown";
    }
  }

  Widget get _authAction {
    switch (_auth.status) {
      case AuthServiceStatus.loading:
        return const CircularProgressIndicator();
      case AuthServiceStatus.loggedIn:
        return ListTile(
          title: const Text('Logout'),
          trailing: const Icon(Icons.logout),
          onTap: _auth.logout,
        );
      case AuthServiceStatus.loggedOut:
        return ListTile(
          title: const Text('Login'),
          trailing: const Icon(Icons.login),
          onTap: _auth.login,
        );
      default:
        return const Text('Unknown');
    }
  }

  void _copy(String text, BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    const snackBar = SnackBar(content: Text('Copied to clipboard'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    if (_auth.status == AuthServiceStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(children: [
      ListTile(
        title: const Text('Auth status'),
        subtitle: Text(_authStatusString),
      ),
      AnimatedSwitcher(
          child: _authAction,
          duration: const Duration(
            milliseconds: 500,
          )),
      const Divider(),
      ListTile(
        title: const Text("Access token expires"),
        subtitle: Text(_expiresAt?.toIso8601String() ?? "Unknown"),
      ),
      ListTile(
        title: const Text("Force refresh"),
        trailing: const Icon(Icons.refresh),
        onTap: _auth.forceRefresh,
      ),
      const Divider(),
      ListTile(
          title: const Text("Access Token"),
          subtitle: Text(_accesToken?.substring(0, 16) ?? "null"),
          onTap: () => _copy(_accesToken ?? "null", context),
          trailing: const Icon(Icons.copy)),
      ListTile(
          title: const Text("Refresh Token"),
          subtitle: Text(_refreshToken?.substring(0, 16) ?? "null"),
          onTap: () => _copy(_refreshToken ?? "null", context),
          trailing: const Icon(Icons.copy)),
      ListTile(
          title: const Text("ID Token"),
          subtitle: Text(_idToken?.substring(0, 16) ?? "null"),
          onTap: () => _copy(_idToken ?? "null", context),
          trailing: const Icon(Icons.copy)),
      const Divider(),
      ListTile(
        title: const Text("Claims"),
        subtitle: Text(_idClaims != null ? jsonEncode(_idClaims) : "null"),
      ),
    ]);
  }
}
