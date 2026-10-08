import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The text size choices from the style guide, by body text size in px.
enum AppTextSize {
  normal(18),
  large(22),
  extraLarge(27);

  const AppTextSize(this.bodySize);

  final double bodySize;

  /// How much bigger than Normal all text becomes.
  double get factor => bodySize / 18;
}

/// Holds the text size the person chose, remembers it between runs and
/// applies it app-wide at once.
class TextSizeController extends ChangeNotifier {
  TextSizeController._();

  static final instance = TextSizeController._();

  static const _key = 'app_text_size';

  /// Phone text size and this setting together never go past 200%.
  static const maxScale = 2.0;

  AppTextSize _size = AppTextSize.normal;
  AppTextSize get size => _size;

  Future<void> load() async {
    try {
      final saved = (await SharedPreferences.getInstance()).getString(_key);
      _size = AppTextSize.values.firstWhere(
        (s) => s.name == saved,
        orElse: () => AppTextSize.normal,
      );
    } catch (_) {
      _size = AppTextSize.normal;
    }
    notifyListeners();
  }

  Future<void> setSize(AppTextSize size) async {
    if (size == _size) return;
    _size = size;
    notifyListeners();
    try {
      await (await SharedPreferences.getInstance()).setString(_key, size.name);
    } catch (_) {
      // The size still changed for this session.
    }
  }

  /// The phone's own text scale times this setting, kept between 100% and
  /// 200% so layouts grow instead of cutting text.
  TextScaler scalerFor(TextScaler phone) {
    final phoneScale = phone.scale(100) / 100;
    return TextScaler.linear((phoneScale * _size.factor).clamp(1.0, maxScale));
  }
}
