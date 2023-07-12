import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Generate a 128 char challenge using secure crypto
String generateChallenge() {
  final secureRandom = Random.secure();

  const chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890-._~';

  final challenge = StringBuffer();
  for (var i = 0; i < 128; i++) {
    final index = secureRandom.nextInt(chars.length);
    challenge.write(chars[index]);
  }

  return challenge.toString();
}

/// Use SHA256 to hash the challenge
Digest hashChallenge(String challenge) {
  // Hash the challenge with SHA256
  return sha256.convert(utf8.encode(challenge));
}

/// Base64 URL encode the digest
String base64UrlEncode(Digest digest) {
  return base64Url.encode(digest.bytes);
}
