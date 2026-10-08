import 'package:flutter/widgets.dart';

import '../models/booking.dart';
import '../models/service_category.dart';
import 'app_localizations.dart';
import 'app_localizations_en.dart';

final _english = AppLocalizationsEn();

extension L10nContext on BuildContext {
  /// The text for the current language. Screens shown without the app's
  /// localization delegates (for example in isolated widget tests) get English.
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ?? _english;
}

extension ServiceCategoryL10n on ServiceCategory {
  /// The category name in the current language (falls back to [label]).
  String localizedLabel(AppLocalizations l10n) => switch (id) {
    'plumbing' => l10n.categoryPlumbing,
    'electrical' => l10n.categoryElectrical,
    'ac' => l10n.categoryAc,
    'cleaning' => l10n.categoryCleaning,
    'painting' => l10n.categoryPainting,
    'carpentry' => l10n.categoryCarpentry,
    'appliance' => l10n.categoryAppliances,
    'gardening' => l10n.categoryGardening,
    _ => label,
  };
}

extension BookingStatusL10n on BookingStatus {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    BookingStatus.pending => l10n.statusPending,
    BookingStatus.confirmed => l10n.statusConfirmed,
    BookingStatus.onTheWay => l10n.statusOnTheWay,
    BookingStatus.inProgress => l10n.statusInProgress,
    BookingStatus.declined => l10n.statusDeclined,
    BookingStatus.completed => l10n.statusCompleted,
    BookingStatus.cancelled => l10n.statusCancelled,
    BookingStatus.unknown => l10n.statusUnknown,
  };
}

/// A rupee amount with Western digits, like `Rs. 2,500` (or `Rs. 2,500.50`).
String rupees(double value) {
  final parts = value
      .toStringAsFixed(value == value.roundToDouble() ? 0 : 2)
      .split('.');
  final digits = parts.first.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
  return 'Rs. $digits${parts.length > 1 ? '.${parts.last}' : ''}';
}
