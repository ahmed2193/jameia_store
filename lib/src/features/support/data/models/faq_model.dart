/// One scripted FAQ entry: the i18n keys of its question and answer.
class FaqModel {
  const FaqModel({required this.questionKey, required this.answerKey});

  final String questionKey;
  final String answerKey;
}
