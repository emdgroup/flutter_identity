import 'dart:convert';

/// [getTokenPayload] returns the payload of a JWT token
Map<String, dynamic>? getTokenPayload(String token) {
  final split = token.split('.');
  if (split.length != 3) {
    throw Exception('Invalid token');
  }
  final payload = split[1];
  final decoded = _decodeBase64(payload);
  final json = jsonDecode(decoded);
  return json as Map<String, dynamic>;
}

String _decodeBase64(String str) {
  var output = str.replaceAll('-', '+').replaceAll('_', '/');

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
