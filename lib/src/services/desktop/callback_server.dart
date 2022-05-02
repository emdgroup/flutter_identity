import 'dart:async';
import 'dart:io';

Future<String> setupCallbackServer({int port = 8080}) async {
  // Launch a server at localhost:8080
  final address = InternetAddress.loopbackIPv4;

  var completer = Completer<String>();

  var server = await HttpServer.bind(address, port);

  await for (HttpRequest request in server) {
    if (request.requestedUri.path == "/login-callback") {
      // Get the code
      var code = request.uri.queryParameters["code"];
      if (code != null) {
        completer.complete(code);
        // Close the server
        server.close();
      }
    }
    request.response.write('Login complete. You can close this window.');

    await request.response.close();
  }

  return completer.future;
}
