// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get languageSwitchLabel => 'மொழி';

  @override
  String customerHomeGreeting(String name) {
    return 'வணக்கம், $name 👋';
  }

  @override
  String get customerHomeTitle => 'உங்கள் வீடு,\nஎங்கள் கவனிப்பு';

  @override
  String get customerHomeSubtitle =>
      'ஒரே இடத்தில் உங்கள் வீட்டுத் தேவைகளுக்கான நம்பகமான நிபுணர்களை முன்பதிவு செய்யுங்கள்.';

  @override
  String get searchHint => 'சேவை வழங்குநர்கள் அல்லது சேவைகளைத் தேடுங்கள்...';

  @override
  String get clearSearch => 'தேடலை அழி';

  @override
  String get servicesForYourHome => 'உங்கள் இல்லத்திற்கான சேவைகள்';

  @override
  String get verifiedProviders => 'சரிபார்க்கப்பட்ட சேவை வழங்குநர்கள்';

  @override
  String get seeAll => 'அனைத்தையும் காண்க';

  @override
  String providerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count சேவை வழங்குநர்கள்',
      one: '$count சேவை வழங்குநர்',
    );
    return '$_temp0';
  }

  @override
  String get providersLoadError =>
      'சேவை வழங்குநர்களை இப்போது ஏற்ற முடியவில்லை.';

  @override
  String get tryAgain => 'மீண்டும் முயற்சிக்கவும்';

  @override
  String get noVerifiedProviders =>
      'சரிபார்க்கப்பட்ட சேவை வழங்குநர்கள் இன்னும் இல்லை. அவர்கள் சரிபார்க்கப்பட்டதும் இங்கு தோன்றுவர்.';

  @override
  String noProvidersMatch(String query) {
    return '\'\'$query\'\' என்பதற்கு பொருந்தும் வழங்குநர்கள் இல்லை. வேறு வார்த்தையை முயற்சிக்கவும்.';
  }

  @override
  String get noProvidersInCategory =>
      'இந்த பிரிவில் இன்னும் சேவை வழங்குநர்கள் இல்லை. வேறு பிரிவை முயற்சிக்கவும்.';

  @override
  String get categoryAll => 'அனைத்தும்';

  @override
  String get categoryPlumbing => 'குழாய் வேலை';

  @override
  String get categoryElectrical => 'மின் வேலை';

  @override
  String get categoryAc => 'ஏசி & குளிர்விப்பான்';

  @override
  String get categoryCleaning => 'சுத்தம் செய்தல்';

  @override
  String get categoryPainting => 'வண்ணம் பூசுதல்';

  @override
  String get categoryCarpentry => 'மர வேலை';

  @override
  String get categoryAppliances => 'வீட்டு உபகரணங்கள்';

  @override
  String get categoryGardening => 'தோட்ட வேலை';

  @override
  String categoryTileSemantics(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count சேவை வழங்குநர்கள்',
      one: '$count சேவை வழங்குநர்',
    );
    return '$label, $_temp0';
  }

  @override
  String reviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count மதிப்பாய்வுகள்',
      one: '$count மதிப்பாய்வு',
    );
    return '$_temp0';
  }

  @override
  String providerIdLabel(String code) {
    return 'அடையாள எண் $code';
  }

  @override
  String get navHome => 'முகப்பு';

  @override
  String get navBookings => 'முன்பதிவுகள்';

  @override
  String get navSaved => 'சேமித்தவை';

  @override
  String get navProfile => 'சுயவிவரம்';

  @override
  String get navLeads => 'கோரிக்கைகள்';

  @override
  String get navMyJobs => 'என் பணிகள்';

  @override
  String get navEarnings => 'வருமானம்';

  @override
  String get titleNotifications => 'அறிவிப்புகள்';

  @override
  String get titleJobDetails => 'பணி விவரங்கள்';

  @override
  String get titleJobPayment => 'பணி நிறைவு / கட்டணம்';

  @override
  String get jobUnavailableTitle => 'பணி கிடைக்கவில்லை';

  @override
  String get jobUnavailableMessage =>
      'இந்த பணி இனி உங்களுக்கு ஒதுக்கப்படவில்லை. உங்கள் பணிகளைக் காண திரும்பிச் செல்லவும்.';

  @override
  String providerGreeting(String name) {
    return 'வணக்கம், $name';
  }

  @override
  String get providerTagline => 'உங்கள் பணி, ஒரே இடத்தில்.';

  @override
  String get newRequests => 'புதிய கோரிக்கைகள்';

  @override
  String get todaysJobs => 'இன்றைய பணிகள்';

  @override
  String get monthlyEarnings => 'மாத வருமானம்';

  @override
  String get upcomingJob => 'அடுத்த பணி';

  @override
  String get noUpcomingTitle => 'அடுத்த பணிகள் எதுவும் இல்லை';

  @override
  String get noUpcomingMessage =>
      'ஏற்றுக்கொள்ளப்பட்ட எதிர்கால பணிகள் இங்கு தோன்றும்.';

  @override
  String get viewAll => 'அனைத்தையும் காண்க';

  @override
  String get noNewRequestsTitle => 'புதிய பணிக் கோரிக்கைகள் இல்லை';

  @override
  String get noNewRequestsMessage =>
      'வாடிக்கையாளர் சேவையை முன்பதிவு செய்யும்போது கோரிக்கைகள் இங்கு வரும்.';

  @override
  String get retry => 'மீண்டும் முயற்சி';

  @override
  String get errorAccessDenied =>
      'அணுகல் மறுக்கப்பட்டது. ஆதரவைத் தொடர்பு கொள்ளவும்.';

  @override
  String get errorUnableToConnect =>
      'இணைக்க முடியவில்லை. இணைய இணைப்பைச் சரிபார்க்கவும்.';

  @override
  String get errorNotAvailableYet =>
      'இந்தத் தகவல் இன்னும் கிடைக்கவில்லை. ஆதரவைத் தொடர்பு கொள்ளவும்.';

  @override
  String get errorUnableToSave =>
      'தரவைச் சேமிக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get errorUnableToLoad =>
      'தரவை ஏற்ற முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get statusPending => 'புதிய கோரிக்கை';

  @override
  String get statusConfirmed => 'உறுதிப்படுத்தப்பட்டது';

  @override
  String get statusOnTheWay => 'வருகிறார்';

  @override
  String get statusInProgress => 'செயலில் உள்ளது';

  @override
  String get statusDeclined => 'நிராகரிக்கப்பட்டது';

  @override
  String get statusCompleted => 'நிறைவடைந்தது';

  @override
  String get statusCancelled => 'ரத்து செய்யப்பட்டது';

  @override
  String get statusUnknown => 'தெரியாத நிலை';

  @override
  String get viewRequest => 'கோரிக்கையைக் காண்க';

  @override
  String get viewDetails => 'விவரங்களைக் காண்க';

  @override
  String get notProvided => 'வழங்கப்படவில்லை';

  @override
  String get notScheduled => 'திட்டமிடப்படவில்லை';

  @override
  String get textSizeLabel => 'எழுத்து அளவு';

  @override
  String get textSizeNormal => 'இயல்பானது';

  @override
  String get textSizeLarge => 'பெரியது';

  @override
  String get textSizeExtraLarge => 'மிகப் பெரியது';

  @override
  String get searchLabel => 'தேடு';

  @override
  String get verifiedBadge => 'சரிபார்க்கப்பட்டது';

  @override
  String fromPrice(String amount) {
    return '$amount முதல்';
  }

  @override
  String ratingSemantics(String rating) {
    return '5 இல் $rating மதிப்பீடு';
  }

  @override
  String get selectedLabel => 'தேர்ந்தெடுக்கப்பட்டது';

  @override
  String get emptyProvidersTitle => 'வழங்குநர்கள் கிடைக்கவில்லை';

  @override
  String get loadErrorTitle => 'செயல்படவில்லை';
}
