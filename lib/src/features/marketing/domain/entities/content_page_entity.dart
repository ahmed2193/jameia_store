import 'package:equatable/equatable.dart';

/// The CMS pages the backend serves (`GET /v1/pages/:slug`). The slug is an
/// enum on the backend: any other value is refused with `400`.
enum ContentPageKind {
  about('about'),
  contact('contact'),
  faq('faq'),
  privacy('privacy'),
  terms('terms');

  const ContentPageKind(this.slug);

  final String slug;

  /// The kind of [slug], or `null` for a slug the backend does not serve.
  static ContentPageKind? ofSlug(String slug) {
    for (final kind in values) {
      if (kind.slug == slug) return kind;
    }
    return null;
  }
}

/// One CMS page. [title] and [body] arrive already resolved for the request
/// language.
class ContentPageEntity extends Equatable {
  const ContentPageEntity({
    required this.kind,
    required this.title,
    required this.body,
  });

  final ContentPageKind kind;
  final String title;
  final String body;

  bool get isEmpty => title.isEmpty && body.isEmpty;

  @override
  List<Object?> get props => [kind, title, body];
}
