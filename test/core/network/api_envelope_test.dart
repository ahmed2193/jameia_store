import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/network/api_envelope.dart';

void main() {
  group('ApiEnvelope.tryParse', () {
    test('parses a success envelope and exposes results', () {
      final envelope = ApiEnvelope.tryParse({
        'success': true,
        'statusCode': 200,
        'statusMessage': 'DATA_LOADED',
        'results': {'id': 'abc'},
        'error': null,
      });

      expect(envelope, isNotNull);
      expect(envelope!.success, isTrue);
      expect(envelope.statusCode, 200);
      expect(envelope.statusMessage, 'DATA_LOADED');
      expect(envelope.results, {'id': 'abc'});
      expect(envelope.error, isNull);
      expect(envelope.displayMessage, 'DATA_LOADED');
    });

    test('parses an error envelope with localized message + details', () {
      final envelope = ApiEnvelope.tryParse({
        'success': false,
        'statusCode': 400,
        'statusMessage': 'VALIDATION_ERROR',
        'results': null,
        'error': {
          'message': 'خطأ في التحقق',
          'data': [
            {'field': 'phone', 'message': 'required'},
          ],
        },
      });

      expect(envelope!.success, isFalse);
      expect(envelope.error!.message, 'خطأ في التحقق');
      expect(envelope.error!.details, hasLength(1));
      expect(envelope.displayMessage, 'خطأ في التحقق');
    });

    test('falls back to statusMessage when error.message is empty', () {
      final envelope = ApiEnvelope.tryParse({
        'success': false,
        'statusCode': 500,
        'statusMessage': 'INTERNAL_ERROR',
        'error': {'message': ''},
      });

      expect(envelope!.displayMessage, 'INTERNAL_ERROR');
    });

    test('returns null for non-envelope bodies', () {
      expect(ApiEnvelope.tryParse(null), isNull);
      expect(ApiEnvelope.tryParse('event: notification'), isNull);
      expect(ApiEnvelope.tryParse([1, 2]), isNull);
      expect(ApiEnvelope.tryParse({'data': []}), isNull);
      expect(
        ApiEnvelope.tryParse({'success': 'yes', 'statusMessage': 'X'}),
        isNull,
      );
    });
  });
}
