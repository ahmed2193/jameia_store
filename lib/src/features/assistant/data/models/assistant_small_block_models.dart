import '../../../../core/data/models/json_read.dart';
import '../../../../core/error/exceptions.dart';

/// A row of a `faq` block: `{ id, question, answer }`.
class AssistantFaqItemModel {
  const AssistantFaqItemModel({
    required this.question,
    this.id = '',
    this.answer = '',
  });

  static const String idKey = 'id';
  static const String questionKey = 'question';
  static const String answerKey = 'answer';

  final String id;
  final String question;
  final String answer;

  factory AssistantFaqItemModel.fromJson(Map<String, dynamic> json) {
    final question = JsonRead.string(json[questionKey]);
    if (question == null) {
      throw const ParsingException('faq item: question missing');
    }
    return AssistantFaqItemModel(
      id: JsonRead.string(json[idKey]) ?? question,
      question: question,
      answer: JsonRead.string(json[answerKey]) ?? '',
    );
  }
}

/// A row of a `locations` block: `{ label, address?, phone?, lat, lng }`.
class AssistantLocationModel {
  const AssistantLocationModel({
    required this.lat,
    required this.lng,
    this.label = '',
    this.address,
    this.phone,
  });

  static const String labelKey = 'label';
  static const String addressKey = 'address';
  static const String phoneKey = 'phone';
  static const String latKey = 'lat';
  static const String lngKey = 'lng';

  final String label;
  final String? address;
  final String? phone;
  final double lat;
  final double lng;

  factory AssistantLocationModel.fromJson(Map<String, dynamic> json) {
    final lat = JsonRead.decimal(json[latKey]);
    final lng = JsonRead.decimal(json[lngKey]);
    if (lat == null || lng == null) {
      throw const ParsingException('location: lat / lng missing');
    }
    return AssistantLocationModel(
      label: JsonRead.string(json[labelKey]) ?? '',
      address: JsonRead.string(json[addressKey]),
      phone: JsonRead.string(json[phoneKey]),
      lat: lat,
      lng: lng,
    );
  }
}

/// A chip of an `actions` block: `{ label, prompt }` — both required.
class AssistantSuggestionModel {
  const AssistantSuggestionModel({required this.label, required this.prompt});

  static const String labelKey = 'label';
  static const String promptKey = 'prompt';

  final String label;
  final String prompt;

  factory AssistantSuggestionModel.fromJson(Map<String, dynamic> json) {
    final label = JsonRead.string(json[labelKey]);
    final prompt = JsonRead.string(json[promptKey]);
    if (label == null || prompt == null) {
      throw const ParsingException('suggestion: label / prompt missing');
    }
    return AssistantSuggestionModel(label: label, prompt: prompt);
  }
}
