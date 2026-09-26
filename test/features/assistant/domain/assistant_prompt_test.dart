import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/features/assistant/domain/entities/assistant_prompt.dart';

void main() {
  group('AssistantPrompt', () {
    test('empty and whitespace-only drafts are not sendable', () {
      for (final raw in ['', ' ', '\n\t  ']) {
        expect(AssistantPrompt.statusOf(raw), AssistantPromptStatus.empty);
        expect(AssistantPrompt.validate(raw), isNull);
      }
    });

    test('1 character is the minimum', () {
      expect(AssistantPrompt.validate('a')?.text, 'a');
    });

    test('trims before sending and before measuring', () {
      final prompt = AssistantPrompt.validate('  milk please \n');
      expect(prompt?.text, 'milk please');
      // 2000 characters surrounded by spaces is still valid.
      final padded = '  ${'x' * AssistantPrompt.maxLength}  ';
      expect(AssistantPrompt.statusOf(padded), AssistantPromptStatus.valid);
    });

    test('2000 is valid, 2001 is too long', () {
      expect(
        AssistantPrompt.statusOf('x' * AssistantPrompt.maxLength),
        AssistantPromptStatus.valid,
      );
      expect(
        AssistantPrompt.statusOf('x' * (AssistantPrompt.maxLength + 1)),
        AssistantPromptStatus.tooLong,
      );
      expect(AssistantPrompt.validate('x' * 2001), isNull);
    });

    test('lengths count code points, like the backend (AJV maxLength)', () {
      // An emoji is ONE code point (two UTF-16 units): 2000 of them fit.
      expect(
        AssistantPrompt.statusOf('😀' * 2000),
        AssistantPromptStatus.valid,
      );
      expect(
        AssistantPrompt.statusOf('😀' * 2001),
        AssistantPromptStatus.tooLong,
      );
      expect(AssistantPrompt.lengthOf('😀a'), 2);
    });

    test('the counter shows from 1800 characters', () {
      expect(AssistantPrompt.showsCounter('x' * 1799), isFalse);
      expect(AssistantPrompt.showsCounter('x' * 1800), isTrue);
    });
  });
}
