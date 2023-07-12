import 'dart:async';
import 'dart:io';

/// Sets up a callback server at localhost:8080 and returns the code
Future<String> setupCallbackServer({int port = 8080}) async {
  // Launch a server at localhost:8080
  final address = InternetAddress.loopbackIPv4;

  final completer = Completer<String>();

  final server = await HttpServer.bind(address, port);

  await for (final HttpRequest request in server) {
    if (request.requestedUri.path == '/login-callback') {
      // Get the code
      final code = request.uri.queryParameters['code'];
      if (code != null) {
        completer.complete(code);
        // Close the server
        await server.close();
      }
    }
    request.response.write('Login complete. You can close this window.');

    await request.response.close();
  }

  return completer.future;
}
