import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../domain/models/content_channel_finance_models.dart';
import '../../domain/models/vyron_enums.dart';

/// Pure Dart synchronous SHA-256 (UTF-8 -> lowercase hex).
/// Produces identical output to src/utils/vyronRules.ts -> sha256Hex.
String sha256Hex(String input) {
  final bytes = utf8.encode(input);
  return sha256.convert(bytes).toString();
}

String bytesToHex(List<int> bytes) {
  final buf = StringBuffer();
  for (final b in bytes) {
    buf.write(b.toRadixString(16).padLeft(2, '0'));
  }
  return buf.toString();
}

Uint8List hexToBytes(String hex) {
  final clean = hex.trim();
  if (clean.length.isOdd) {
    throw ArgumentError.value(hex, 'hex', 'Hex string must have even length');
  }
  final out = Uint8List(clean.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(clean.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return out;
}

/// Constant-time string comparison to avoid timing side channels during local credential check.
bool constantTimeEquals(String a, String b) {
  final aBytes = utf8.encode(a);
  final bBytes = utf8.encode(b);
  if (aBytes.length != bBytes.length) return false;
  var diff = 0;
  for (var i = 0; i < aBytes.length; i++) {
    diff |= aBytes[i] ^ bBytes[i];
  }
  return diff == 0;
}

/// Generates cryptographically secure random salt encoded as lowercase hex.
String generateSecureSaltHex([int byteLength = 16]) {
  final rng = Random.secure();
  final bytes = List<int>.generate(byteLength, (_) => rng.nextInt(256));
  return bytesToHex(bytes);
}

/// Synchronous RFC 8018 PBKDF2-HMAC-SHA256 derivation (returns lowercase hex).
/// Intended for tests or short derivation; prefer [pbkdf2HmacSha256Async] in UI flows.
String pbkdf2HmacSha256Sync({
  required String password,
  required List<int> saltBytes,
  int iterations = 210000,
  int keyLengthBytes = 32,
}) {
  if (iterations <= 0) {
    throw ArgumentError.value(iterations, 'iterations', 'Must be positive');
  }
  if (keyLengthBytes <= 0) {
    throw ArgumentError.value(
      keyLengthBytes,
      'keyLengthBytes',
      'Must be positive',
    );
  }

  final passwordBytes = utf8.encode(password);
  final hmac = Hmac(sha256, passwordBytes);
  const hashLen = 32; // SHA-256 digest length
  final blockCount = (keyLengthBytes + hashLen - 1) ~/ hashLen;
  final derived = Uint8List(blockCount * hashLen);

  for (var blockIndex = 1; blockIndex <= blockCount; blockIndex++) {
    final blockInput = Uint8List(saltBytes.length + 4);
    blockInput.setRange(0, saltBytes.length, saltBytes);
    blockInput[saltBytes.length] = (blockIndex >> 24) & 0xff;
    blockInput[saltBytes.length + 1] = (blockIndex >> 16) & 0xff;
    blockInput[saltBytes.length + 2] = (blockIndex >> 8) & 0xff;
    blockInput[saltBytes.length + 3] = blockIndex & 0xff;

    var u = hmac.convert(blockInput).bytes;
    final t = Uint8List.fromList(u);

    for (var iter = 1; iter < iterations; iter++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < hashLen; j++) {
        t[j] ^= u[j];
      }
    }

    derived.setRange((blockIndex - 1) * hashLen, blockIndex * hashLen, t);
  }

  return bytesToHex(derived.sublist(0, keyLengthBytes));
}

/// Offloads PBKDF2-HMAC-SHA256 to a background Dart Isolate (Android/iOS native)
/// so UI animations stay at 60/120fps.
Future<String> pbkdf2HmacSha256Async({
  required String password,
  required List<int> saltBytes,
  int iterations = 210000,
  int keyLengthBytes = 32,
}) {
  final saltCopy = Uint8List.fromList(saltBytes);
  return Isolate.run(
    () => pbkdf2HmacSha256Sync(
      password: password,
      saltBytes: saltCopy,
      iterations: iterations,
      keyLengthBytes: keyLengthBytes,
    ),
  );
}

const List<String> manifestFieldKeys = [
  'brandId',
  'channelId',
  'productId',
  'title',
  'description',
  'format',
  'category',
  'visibility',
  'analysisMethod',
  'sensitiveTopic',
  'script',
  'affiliateLinkUrl',
  'affiliateDisclosure',
  'aiDisclosureRequired',
  'aiDisclosureText',
];

class ManifestFields {
  const ManifestFields({
    required this.brandId,
    required this.channelId,
    this.productId,
    required this.title,
    required this.description,
    required this.format,
    required this.category,
    required this.visibility,
    required this.analysisMethod,
    required this.sensitiveTopic,
    required this.script,
    required this.affiliateLinkUrl,
    required this.affiliateDisclosure,
    required this.aiDisclosureRequired,
    required this.aiDisclosureText,
  });

  factory ManifestFields.fromContent(ContentItem item) => ManifestFields(
    brandId: item.brandId,
    channelId: item.channelId,
    productId: item.productId,
    title: item.title,
    description: item.description,
    format: item.format,
    category: item.category,
    visibility: item.visibility,
    analysisMethod: item.analysisMethod,
    sensitiveTopic: item.sensitiveTopic,
    script: item.script,
    affiliateLinkUrl: item.affiliateLinkUrl,
    affiliateDisclosure: item.affiliateDisclosure,
    aiDisclosureRequired: item.aiDisclosureRequired,
    aiDisclosureText: item.aiDisclosureText,
  );

  final String brandId;
  final String channelId;
  final String? productId;
  final String title;
  final String description;
  final ContentFormat format;
  final ContentCategory category;
  final ContentVisibility visibility;
  final AnalysisMethod analysisMethod;
  final SensitiveTopic sensitiveTopic;
  final String script;
  final String affiliateLinkUrl;
  final String affiliateDisclosure;
  final bool aiDisclosureRequired;
  final String aiDisclosureText;
}

/// Computes deterministic SHA-256 hash over the immutable 15-field release manifest.
/// Key order matches src/utils/vyronRules.ts -> computeContentManifestHash literally.
String computeContentManifestHash(ManifestFields item) {
  final canonical = <String, dynamic>{
    'affiliateDisclosure': item.affiliateDisclosure.trim(),
    'affiliateLinkUrl': item.affiliateLinkUrl.trim(),
    'aiDisclosureRequired': item.aiDisclosureRequired,
    'aiDisclosureText': item.aiDisclosureText.trim(),
    'analysisMethod': item.analysisMethod.wire,
    'brandId': item.brandId,
    'category': item.category.wire,
    'channelId': item.channelId,
    'description': item.description.trim(),
    'format': item.format.wire,
    'productId': item.productId,
    'script': item.script.trim(),
    'sensitiveTopic': item.sensitiveTopic.wire,
    'title': item.title.trim(),
    'visibility': item.visibility.wire,
  };
  return sha256Hex(jsonEncode(canonical));
}

String computeContentItemManifestHash(ContentItem item) =>
    computeContentManifestHash(ManifestFields.fromContent(item));
