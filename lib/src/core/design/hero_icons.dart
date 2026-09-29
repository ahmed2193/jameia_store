// GENERATED-BY-EXTRACTION — do not hand-edit codepoints.
//
// Real Hero icon glyphs resolved from the bundled `wm_c_iconfont.ttf`
// (cmap format 12 + post v2 glyph names) extracted from the decoded Hero APK.
// Family is registered as 'HeroIcon' in pubspec.yaml.
//
// Codepoints below are the ACTUAL glyph code points in the font — verified by
// parsing the font's cmap/post tables, not guessed. Glyphs whose semantics could
// not be resolved confidently (plus, minus, scan/QR) are intentionally OMITTED;
// see the note at the bottom of this file.
import 'package:flutter/widgets.dart';

/// Icon constants over the real Hero `wm_c_iconfont` ('HeroIcon' family).
///
/// Original glyph names (pinyin/english from the font's `post` table) are noted
/// in comments so feature code can trace each constant back to the source glyph.
///
/// Four glyphs of this font are not icons at all but the Chinese WORDS they
/// label — 0xe014 `賞` (in a ring), 0xe057 `地址`, 0xe058 `店铺`, 0xe05a
/// `商品` — so they are not declared here. An address uses [locationOutline],
/// and a reward / coupon has no glyph in this font at all: use Material's
/// `Icons.confirmation_number_outlined` / `Icons.card_giftcard`.
class HeroIcons {
  HeroIcons._();

  static const String fontFamily = 'HeroIcon';

  // ── Search ────────────────────────────────────────────────────────────────
  /// magnifier / search (`wm_c_iconfont_27fangdajing`)
  static const IconData search = IconData(0xe017, fontFamily: fontFamily);

  /// clear search field (`wm_c_iconfont_search_clear`)
  static const IconData searchClear = IconData(0xe05c, fontFamily: fontFamily);

  // ── Close ───────────────────────────────────────────────────────────────────
  /// close (`wm_c_iconfont_26guanbi`)
  static const IconData close = IconData(0xe016, fontFamily: fontFamily);

  // ── Location / address ────────────────────────────────────────────────────
  /// location pin (`wm_c_iconfont_14dingwei`)
  static const IconData location = IconData(0xe00b, fontFamily: fontFamily);

  /// location, outline (`wm_c_iconfont_location`)
  static const IconData locationOutline = IconData(
    0xe05b,
    fontFamily: fontFamily,
  );

  // ── Chat / contact ──────────────────────────────────────────────────────────
  /// chat / IM (`wm_c_iconfont_28im`)
  static const IconData chat = IconData(0xe018, fontFamily: fontFamily);

  /// phone (`wm_c_iconfont_15dianhua`)
  static const IconData phone = IconData(0xe00c, fontFamily: fontFamily);

  /// customer service (`wm_c_iconfont_68kefu`)
  static const IconData customerService = IconData(
    0xe02e,
    fontFamily: fontFamily,
  );

  // ── Navigation arrows ───────────────────────────────────────────────────────
  // Horizontal glyphs carry `matchTextDirection: true` so the `Icon` widget
  // mirrors them under RTL. Custom-font IconData does NOT auto-flip without this
  // flag (unlike the curated Material directional icons). Vertical arrows
  // (up/down) are direction-neutral and must NOT mirror.
  /// back / arrow-left (`wm_c_iconfont_jiantou_zuo`) — mirrors under RTL.
  static const IconData back = IconData(
    0xe036,
    fontFamily: fontFamily,
    matchTextDirection: true,
  );

  /// arrow-right (`wm_c_iconfont_jiantou_you`) — mirrors under RTL.
  static const IconData arrowRight = IconData(
    0xe035,
    fontFamily: fontFamily,
    matchTextDirection: true,
  );

  /// arrow-down (`wm_c_iconfont_jiantou_xia`)
  static const IconData arrowDown = IconData(0xe034, fontFamily: fontFamily);

  /// arrow-up (`wm_c_iconfont_arrow_up`)
  static const IconData arrowUp = IconData(0xe041, fontFamily: fontFamily);

  /// small arrow-down (`wm_c_iconfont_arrow_down_small`)
  static const IconData arrowDownSmall = IconData(
    0xe044,
    fontFamily: fontFamily,
  );

  // ── Rating / favorite ───────────────────────────────────────────────────────
  /// star selected (`wm_c_iconfont_star_select`)
  static const IconData star = IconData(0xe038, fontFamily: fontFamily);

  /// favorite / heart-collect (`wm_c_iconfont_2shoucang`)
  static const IconData favorite = IconData(0xe000, fontFamily: fontFamily);

  // ── Cart / commerce ─────────────────────────────────────────────────────────
  /// shopping cart (`wm_c_iconfont_3gouwuche`)
  static const IconData cart = IconData(0xe033, fontFamily: fontFamily);

  /// orders (`wm_c_iconfont_45dingdan`)
  static const IconData orders = IconData(0xe024, fontFamily: fontFamily);

  /// confirm receipt (`wm_c_iconfont_43querenshouhuo`)
  static const IconData confirmReceipt = IconData(
    0xe023,
    fontFamily: fontFamily,
  );

  // ── Time / delivery ─────────────────────────────────────────────────────────

  /// delivery (`wm_c_iconfont_delivery`)
  static const IconData delivery = IconData(0xe039, fontFamily: fontFamily);

  /// [delivery] where the van's heading means "on its way" (a status line,
  /// an order stage): mirrors under RTL so it drives along the reading
  /// direction.
  static const IconData deliveryDirectional = IconData(
    0xe039,
    fontFamily: fontFamily,
    matchTextDirection: true,
  );

  // ── Camera / media ──────────────────────────────────────────────────────────
  /// camera (`wm_c_iconfont_xiangji`)
  static const IconData camera = IconData(0xe04d, fontFamily: fontFamily);

  // ── Status / info ───────────────────────────────────────────────────────────
  /// info / warning (`wm_c_iconfont_31jingshi`)
  static const IconData info = IconData(0xe01b, fontFamily: fontFamily);

  /// question (`wm_c_iconfont_32wenhao`)
  static const IconData help = IconData(0xe01c, fontFamily: fontFamily);

  /// notice (`wm_c_iconfont_notice`)
  static const IconData notice = IconData(0xe03b, fontFamily: fontFamily);

  /// alert / reminder (`wm_c_iconfont_38tixing`)
  static const IconData alert = IconData(0xe01e, fontFamily: fontFamily);

  /// edit (`wm_c_iconfont_63bianji`)
  static const IconData edit = IconData(0xe02c, fontFamily: fontFamily);

  /// delete (`wm_c_iconfont_67shanchu`)
  static const IconData delete = IconData(0xe02d, fontFamily: fontFamily);

  /// flame / hot (`wm_c_iconfont_huomiao`)
  static const IconData flame = IconData(0xe055, fontFamily: fontFamily);

  // ───────────────────────────────────────────────────────────────────────────
  // OMITTED — no matching glyph found in wm_c_iconfont.ttf (would be a guess):
  //   • plus  / add   — no `jia`/`add` glyph in the font cmap.
  //   • minus / remove — no `jian`/`minus`/`remove` glyph in the font cmap.
  //   • scan / QR      — no `saoyisao`/`scan`/`qrcode` glyph (use `camera` for
  //                      capture flows; the Mine scan entry, which opens the
  //                      delivery code, uses [confirmReceipt]).
  // Use Material `Icons.add` / `Icons.remove` for stepper +/- controls.
}
