// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Sinhala Sinhalese (`si`).
class AppLocalizationsSi extends AppLocalizations {
  AppLocalizationsSi([String locale = 'si']) : super(locale);

  @override
  String get languageSwitchLabel => 'භාෂාව';

  @override
  String customerHomeGreeting(String name) {
    return 'ආයුබෝවන්, $name 👋';
  }

  @override
  String get customerHomeTitle => 'ඔබේ නිවස,\nඅපේ රැකවරණය';

  @override
  String get customerHomeSubtitle =>
      'නිවසේ සියලු අවශ්‍යතා සඳහා විශ්වාසවන්ත වෘත්තිකයන් එකම තැනකින් වෙන්කරවා ගන්න.';

  @override
  String get searchHint => 'සේවා සපයන්නන් හෝ සේවා සොයන්න...';

  @override
  String get clearSearch => 'සෙවුම මකන්න';

  @override
  String get servicesForYourHome => 'ඔබේ නිවසට අවශ්‍ය සේවා';

  @override
  String get verifiedProviders => 'තහවුරු කළ සේවා සපයන්නන්';

  @override
  String get seeAll => 'සියල්ල බලන්න';

  @override
  String providerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'සේවා සපයන්නන් $count',
      one: 'සේවා සපයන්නෙක් $count',
    );
    return '$_temp0';
  }

  @override
  String get providersLoadError => 'සේවා සපයන්නන් දැන් පූරණය කළ නොහැකි විය.';

  @override
  String get tryAgain => 'නැවත උත්සාහ කරන්න';

  @override
  String get noVerifiedProviders =>
      'තවමත් තහවුරු කළ සේවා සපයන්නන් නැත. අපගේ කණ්ඩායම තහවුරු කළ විගස ඔවුන් මෙහි පෙනේ.';

  @override
  String noProvidersMatch(String query) {
    return '\'\'$query\'\' ට ගැලපෙන සේවා සපයන්නන් නැත. වෙනත් වචනයක් උත්සාහ කරන්න, නැතහොත් සෙවුම මකන්න.';
  }

  @override
  String get noProvidersInCategory =>
      'මෙම ප්‍රවර්ගයේ තවමත් සේවා සපයන්නන් නැත. වෙනත් ප්‍රවර්ගයක් උත්සාහ කරන්න.';

  @override
  String get categoryAll => 'සියල්ල';

  @override
  String get categoryPlumbing => 'ජල නළ වැඩ';

  @override
  String get categoryElectrical => 'විදුලි වැඩ';

  @override
  String get categoryAc => 'වායු සමීකරණ සහ සිසිලනය';

  @override
  String get categoryCleaning => 'පිරිසිදු කිරීම';

  @override
  String get categoryPainting => 'තීන්ත ගෑම';

  @override
  String get categoryCarpentry => 'වඩු වැඩ';

  @override
  String get categoryAppliances => 'ගෘහ උපකරණ';

  @override
  String get categoryGardening => 'උද්‍යාන වගාව';

  @override
  String categoryTileSemantics(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'සේවා සපයන්නන් $count',
      one: 'සේවා සපයන්නෙක් $count',
    );
    return '$label, $_temp0';
  }

  @override
  String reviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'සමාලෝචන $count',
      one: 'සමාලෝචනයක් $count',
    );
    return '$_temp0';
  }

  @override
  String providerIdLabel(String code) {
    return 'හැඳුනුම් අංකය $code';
  }

  @override
  String get navHome => 'මුල් පිටුව';

  @override
  String get navBookings => 'වෙන්කිරීම්';

  @override
  String get navSaved => 'සුරැකි';

  @override
  String get navProfile => 'පැතිකඩ';

  @override
  String get navLeads => 'ඉල්ලීම්';

  @override
  String get navMyJobs => 'මගේ රැකියා';

  @override
  String get navEarnings => 'ඉපැයීම්';

  @override
  String get titleNotifications => 'දැනුම්දීම්';

  @override
  String get titleJobDetails => 'රැකියා විස්තර';

  @override
  String get titleJobPayment => 'රැකියාව අවසන් කිරීම / ගෙවීම';

  @override
  String get jobUnavailableTitle => 'රැකියාව නොමැත';

  @override
  String get jobUnavailableMessage =>
      'මෙම රැකියාව තවදුරටත් ඔබට පවරා නැත. ඔබේ රැකියා බැලීමට ආපසු යන්න.';

  @override
  String providerGreeting(String name) {
    return 'ආයුබෝවන්, $name';
  }

  @override
  String get providerTagline => 'ඔබේ වැඩ, එකම තැනකින්.';

  @override
  String get newRequests => 'නව ඉල්ලීම්';

  @override
  String get todaysJobs => 'අද රැකියා';

  @override
  String get monthlyEarnings => 'මාසික ඉපැයීම්';

  @override
  String get upcomingJob => 'ඉදිරි රැකියාව';

  @override
  String get noUpcomingTitle => 'තවමත් ඉදිරි රැකියා නැත';

  @override
  String get noUpcomingMessage => 'පිළිගත් අනාගත රැකියා මෙහි පෙනේ.';

  @override
  String get viewAll => 'සියල්ල බලන්න';

  @override
  String get noNewRequestsTitle => 'නව රැකියා ඉල්ලීම් නැත';

  @override
  String get noNewRequestsMessage =>
      'පාරිභෝගිකයකු ඔබේ සේවා වෙන්කළ විට ඉල්ලීම් මෙහි පෙනේ.';

  @override
  String get retry => 'නැවත උත්සාහ කරන්න';

  @override
  String get errorAccessDenied =>
      'ප්‍රවේශය ප්‍රතික්ෂේප විය. කරුණාකර සහාය අමතන්න.';

  @override
  String get errorUnableToConnect =>
      'සම්බන්ධ විය නොහැක. ඔබේ සම්බන්ධතාව පරීක්ෂා කර නැවත උත්සාහ කරන්න.';

  @override
  String get errorNotAvailableYet => 'මෙම දත්ත තවම නොමැත. කරුණාකර සහාය අමතන්න.';

  @override
  String get errorUnableToSave =>
      'ඔබේ දත්ත සුරැකීමට හෝ පූරණයට නොහැකි විය. කරුණාකර නැවත උත්සාහ කරන්න.';

  @override
  String get errorUnableToLoad =>
      'ඔබේ දත්ත පූරණය කළ නොහැකි විය. කරුණාකර නැවත උත්සාහ කරන්න.';

  @override
  String get statusPending => 'නව ඉල්ලීම';

  @override
  String get statusConfirmed => 'තහවුරු කළා';

  @override
  String get statusOnTheWay => 'පැමිණෙමින්';

  @override
  String get statusInProgress => 'ක්‍රියාත්මකයි';

  @override
  String get statusDeclined => 'ප්‍රතික්ෂේප කළා';

  @override
  String get statusCompleted => 'නිම කළා';

  @override
  String get statusCancelled => 'අවලංගු කළා';

  @override
  String get statusUnknown => 'නොදන්නා තත්ත්වය';

  @override
  String get viewRequest => 'ඉල්ලීම බලන්න';

  @override
  String get viewDetails => 'විස්තර බලන්න';

  @override
  String get notProvided => 'සපයා නැත';

  @override
  String get notScheduled => 'කාලසටහන් කර නැත';
}
