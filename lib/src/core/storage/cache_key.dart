import 'dart:convert';

import 'cache_namespace.dart';
import 'cache_owner.dart';

/// Where one response is cached: its [namespace] (and so its policy), the
/// [language] it was fetched in (names arrive resolved by `Accept-Language`,
/// which the server does not list in `Vary`), the [owner] identity, and the
/// [id] telling entries of one namespace apart (a slug, a normalised query;
/// empty for a single-screen namespace).
class CacheKey {
  const CacheKey({
    required this.namespace,
    required this.language,
    required this.owner,
    this.id = '',
  });

  /// The owner of [CacheScope.public] entries.
  static const String publicOwner = 'public';

  final CacheNamespace namespace;
  final String language;
  final String owner;
  final String id;

  /// Everything that identifies the entry; stored in it and checked on read,
  /// so a hash collision or a schema bump reads as a miss.
  String get full =>
      '${namespace.name}|${namespace.version}|$language|$owner|$id';

  /// The folder the entry lives in: `customer` entries are wiped together
  /// on sign-out; `public` and `guest` ones stay.
  String get bucket => switch (owner) {
    publicOwner => publicOwner,
    CacheOwner.guest => CacheOwner.guest,
    _ => customerBucket,
  };

  static const String customerBucket = 'customer';

  /// A stable 64-bit FNV-1a hash of [full] (16 hex digits) — the file name.
  String get fileName => fnv1a64(full);

  static const int _fnvOffset = 0xcbf29ce484222325;
  static const int _fnvPrime = 0x100000001b3;
  static const int _halfBits = 32;
  static const int _halfMask = 0xffffffff;
  static const int _halfHexWidth = 8;
  static const int _hexRadix = 16;

  /// 64-bit FNV-1a over the UTF-8 bytes of [text]; Dart's 64-bit integers
  /// wrap on overflow, which is the arithmetic FNV expects. Printed as two
  /// 32-bit halves: a 64-bit value with the top bit set is negative in Dart.
  static String fnv1a64(String text) {
    var hash = _fnvOffset;
    for (final byte in utf8.encode(text)) {
      hash ^= byte;
      hash *= _fnvPrime;
    }
    String half(int bits) =>
        (bits & _halfMask).toRadixString(_hexRadix).padLeft(_halfHexWidth, '0');
    return half(hash >> _halfBits) + half(hash);
  }
}
