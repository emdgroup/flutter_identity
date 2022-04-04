import 'dart:convert';

Map<String, dynamic>? getTokenPayload(String token) {
  var split = token.split(".");
  if (split.length != 3) {
    throw Exception("Invalid token");
  }
  var payload = split[1];
  var decoded = _decodeBase64(payload);
  var json = jsonDecode(decoded);
  return json;
}

String _decodeBase64(String str) {
  String output = str.replaceAll('-', '+').replaceAll('_', '/');

  switch (output.length % 4) {
    case 0:
      break;
    case 2:
      output += '==';
      break;
    case 3:
      output += '=';
      break;
    default:
      throw Exception('Illegal base64url string!"');
  }

  return utf8.decode(base64Url.decode(output));
}
