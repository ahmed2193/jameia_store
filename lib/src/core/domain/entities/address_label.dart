/// The tag of a saved address. On the wire `label` is free text (1–64 chars):
/// the app writes the canonical English token ([wireValue]), other clients may
/// write anything.
///
/// Reading is tolerant: a known token maps to its tag (case-insensitive, the
/// legacy `Hangout` → [gathering]); anything else is [other], and the raw text
/// stays on the entity so a custom label can still be shown.
enum AddressLabel {
  home('Home'),
  work('Work'),
  gathering('Gathering'),
  other('Other');

  const AddressLabel(this.wireValue);

  /// The text the app sends as `label`.
  final String wireValue;

  static const String _legacyGathering = 'hangout';

  static AddressLabel fromWire(String raw) {
    final value = raw.trim().toLowerCase();
    for (final label in values) {
      if (label.wireValue.toLowerCase() == value) return label;
    }
    return value == _legacyGathering ? gathering : other;
  }
}
