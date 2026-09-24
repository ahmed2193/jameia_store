import '../../../../core/data/models/category_model.dart';
import '../../../../core/data/models/json_read.dart';
import 'home_announcement_model.dart';
import 'home_section_model.dart';
import 'home_slide_model.dart';

/// `results` of `GET /v1/home`:
/// `{ slides[], sections[], categories[], announcement }` — the whole home
/// screen in one reply (never one request per section).
class HomeFeedModel {
  const HomeFeedModel({
    this.slides = const <HomeSlideModel>[],
    this.sections = const <HomeSectionModel>[],
    this.categories = const <CategoryModel>[],
    this.announcement = const HomeAnnouncementModel(),
  });

  static const String slidesKey = 'slides';
  static const String sectionsKey = 'sections';
  static const String categoriesKey = 'categories';
  static const String announcementKey = 'announcement';
  static const String _logName = 'HomeFeedModel';

  /// Every list is optional and row-tolerant: a block the app cannot parse is
  /// skipped, the rest of the screen still renders.
  factory HomeFeedModel.fromJson(Map<String, dynamic> json) => HomeFeedModel(
    slides: JsonRead.rows(
      json[slidesKey],
      HomeSlideModel.fromJson,
      logName: _logName,
    ),
    sections: JsonRead.rows(
      json[sectionsKey],
      HomeSectionModel.fromJson,
      logName: _logName,
    ),
    categories: JsonRead.rows(
      json[categoriesKey],
      CategoryModel.fromJson,
      logName: _logName,
    ),
    announcement: HomeAnnouncementModel.fromJson(json[announcementKey]),
  );

  final List<HomeSlideModel> slides;
  final List<HomeSectionModel> sections;

  /// The full category tree, flat (same rows as `GET /v1/categories`).
  final List<CategoryModel> categories;
  final HomeAnnouncementModel announcement;
}
