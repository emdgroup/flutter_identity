import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

// Generate a 128 char challenge using secure crypto
String generateChallenge() {
  var secureRandom = Random.secure();

  var chars =
      "AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890-._~";

  var challenge = "";
  for (var i = 0; i < 128; i++) {
    var index = secureRandom.nextInt(chars.length);
    challenge += chars[index];
  }

  return challenge;
}

// Use SHA256 to hash the challenge
Digest hashChallenge(String challenge) {
  // Hash the challenge with SHA256
  return sha256.convert(utf8.encode(challenge));
}

String base64UrlEncode(Digest digest) {
  return base64Url.encode(digest.bytes);
}
