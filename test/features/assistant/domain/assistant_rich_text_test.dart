import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_conversation_entity.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_rich_text.dart';

void main() {
  AssistantRichText parse(String text) => AssistantRichText.parse(text);

  group('AssistantRichText.parse', () {
    test('empty and blank text has no blocks', () {
      expect(parse('').isEmpty, isTrue);
      expect(parse('  \n\n ').isEmpty, isTrue);
    });

    test('blank lines split paragraphs; single line breaks stay inside', () {
      final rich = parse('Hello there.\nSecond line.\n\nNew paragraph.');
      expect(rich.blocks, hasLength(2));
      expect(rich.blocks[0].kind, AssistantRichBlockKind.paragraph);
      expect(rich.blocks[0].text, 'Hello there.\nSecond line.');
      expect(rich.blocks[1].text, 'New paragraph.');
    });

    test('bullets with -, * and •', () {
      final rich = parse('Offers:\n- Free delivery\n* 10% off\n• 2 KWD off');
      expect(rich.blocks.map((b) => b.kind), [
        AssistantRichBlockKind.paragraph,
        AssistantRichBlockKind.bullet,
        AssistantRichBlockKind.bullet,
        AssistantRichBlockKind.bullet,
      ]);
      expect(rich.blocks.skip(1).map((b) => b.text), [
        'Free delivery',
        '10% off',
        '2 KWD off',
      ]);
    });

    test('numbered items keep the number the model wrote', () {
      final rich = parse('1. Eggs\n2) Bread\n10. Butter');
      expect(rich.blocks.map((b) => b.marker), ['1.', '2.', '10.']);
      expect(
        rich.blocks.every((b) => b.kind == AssistantRichBlockKind.numbered),
        isTrue,
      );
    });

    test('an indented line continues the list item; a flush one does not', () {
      final rich = parse('- Milk\n  full fat\nThat is all.');
      expect(rich.blocks, hasLength(2));
      expect(rich.blocks[0].text, 'Milk full fat');
      expect(rich.blocks[1].kind, AssistantRichBlockKind.paragraph);
    });

    test('**bold** runs', () {
      final runs = parse('Try **Kuwaiti Eggs** today').blocks.single.runs;
      expect(runs, const [
        AssistantTextRun('Try '),
        AssistantTextRun('Kuwaiti Eggs', bold: true),
        AssistantTextRun(' today'),
      ]);
    });

    test('an unclosed ** (mid-stream) is bold to the end, never printed', () {
      final runs = parse('Try **Kuwa').blocks.single.runs;
      expect(runs, const [
        AssistantTextRun('Try '),
        AssistantTextRun('Kuwa', bold: true),
      ]);
    });

    test('a line starting with **bold** is a paragraph, not a bullet', () {
      final block = parse('**Tip:** keep it cold').blocks.single;
      expect(block.kind, AssistantRichBlockKind.paragraph);
      expect(block.runs.first, const AssistantTextRun('Tip:', bold: true));
    });

    test('headings render as their own block', () {
      final rich = parse('## Breakfast\nEggs and bread');
      expect(rich.blocks[0].kind, AssistantRichBlockKind.heading);
      expect(rich.blocks[0].text, 'Breakfast');
      expect(rich.blocks[1].text, 'Eggs and bread');
    });

    test('links keep their label; inline code and *emphasis* lose markers', () {
      final text = parse(
        'See [our offers](https://jm3eia.store/offers), use `SAVE10`, '
        'it is *great*. 2*3=6',
      ).blocks.single.text;
      expect(text, 'See our offers, use SAVE10, it is great. 2*3=6');
    });

    test('a dangling list marker mid-stream is hidden until its text', () {
      expect(parse('Offers:\n-').blocks, hasLength(1));
      expect(parse('Offers:\n- ').blocks, hasLength(1));
      expect(parse('Offers:\n- Free').blocks.last.text, 'Free');
    });

    test('horizontal rules are dropped; CRLF is accepted', () {
      final rich = parse('Top\r\n\r\n---\r\n\r\nBottom');
      expect(rich.blocks.map((b) => b.text), ['Top', 'Bottom']);
    });

    test('Arabic text passes through untouched', () {
      final rich = parse('أهلاً! إليك العروض:\n- توصيل مجاني فوق **5 د.ك**');
      expect(
        rich.blocks[1].runs.last,
        const AssistantTextRun('5 د.ك', bold: true),
      );
    });

    test("direction comes from each block's first strong character", () {
      final rich = parse('123 أهلاً\n\nLurpak butter\n\n42%');
      expect(rich.blocks.map((b) => b.isRtl), [true, false, null]);
      expect(rich.isRtl, isTrue);
      expect(parse('**Lurpak** زبدة طازجة').isRtl, isTrue);
      expect(parse('Try **Lurpak** زبدة today').isRtl, isFalse);
      expect(parse('').isRtl, isNull);
    });

    test('plainText is what Copy puts on the clipboard', () {
      final rich = parse('Hi **there**\n\n- one\n- two\n\n1. first\n\nBye');
      expect(rich.plainText, 'Hi there\n\n• one\n• two\n1. first\n\nBye');
    });

    test('streamed prefixes grow without reordering blocks (L6 swap)', () {
      const full = 'For breakfast:\n- Eggs\n- Bread\n\nEnjoy!';
      final finalBlocks = parse(full).blocks;
      for (var end = 1; end <= full.length; end++) {
        final partial = parse(full.substring(0, end)).blocks;
        expect(partial.length, lessThanOrEqualTo(finalBlocks.length));
        for (var i = 0; i < partial.length - 1; i++) {
          expect(partial[i], finalBlocks[i], reason: 'prefix $end block $i');
        }
      }
    });
  });

  group('AssistantConversationEntity.previewText', () {
    AssistantConversationEntity withPreview(String preview) =>
        AssistantConversationEntity(id: 'c1', lastMessagePreview: preview);

    test('drops the markdown the server keeps in the preview', () {
      expect(
        withPreview(
          "I've prepared 2 × Butter. Nothing is added yet — tap "
          '**Add to cart** to confirm.',
        ).previewText,
        "I've prepared 2 × Butter. Nothing is added yet — tap Add to cart "
        'to confirm.',
      );
    });

    test('one line: headings, lists and breaks collapse to spaces', () {
      expect(
        withPreview('## Offers\n\n- **SAVE10**\n- Free delivery').previewText,
        'Offers • SAVE10 • Free delivery',
      );
    });

    test('empty stays empty', () {
      expect(withPreview('').previewText, isEmpty);
      expect(withPreview('  \n ').previewText, isEmpty);
    });
  });
}
