import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_si.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('si'),
    Locale('ta'),
  ];

  /// Spoken label for the language switch
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSwitchLabel;

  /// No description provided for @customerHomeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name} 👋'**
  String customerHomeGreeting(String name);

  /// No description provided for @customerHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Home,\nOur Care'**
  String get customerHomeTitle;

  /// No description provided for @customerHomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Book trusted professionals for every home need, all in one place.'**
  String get customerHomeSubtitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search providers or services...'**
  String get searchHint;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @servicesForYourHome.
  ///
  /// In en, this message translates to:
  /// **'Services for your home'**
  String get servicesForYourHome;

  /// No description provided for @verifiedProviders.
  ///
  /// In en, this message translates to:
  /// **'Verified providers'**
  String get verifiedProviders;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @providerCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} provider} other{{count} providers}}'**
  String providerCount(int count);

  /// No description provided for @providersLoadError.
  ///
  /// In en, this message translates to:
  /// **'Providers could not be loaded right now.'**
  String get providersLoadError;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @noVerifiedProviders.
  ///
  /// In en, this message translates to:
  /// **'No verified providers yet. Providers show up here as soon as our team verifies them.'**
  String get noVerifiedProviders;

  /// No description provided for @noProvidersMatch.
  ///
  /// In en, this message translates to:
  /// **'No providers match \'\'{query}\'\'. Try another word or clear the search.'**
  String noProvidersMatch(String query);

  /// No description provided for @noProvidersInCategory.
  ///
  /// In en, this message translates to:
  /// **'No providers in this category yet. Try another category.'**
  String get noProvidersInCategory;

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// No description provided for @categoryPlumbing.
  ///
  /// In en, this message translates to:
  /// **'Plumbing'**
  String get categoryPlumbing;

  /// No description provided for @categoryElectrical.
  ///
  /// In en, this message translates to:
  /// **'Electrical'**
  String get categoryElectrical;

  /// No description provided for @categoryAc.
  ///
  /// In en, this message translates to:
  /// **'AC & Cooling'**
  String get categoryAc;

  /// No description provided for @categoryCleaning.
  ///
  /// In en, this message translates to:
  /// **'Cleaning'**
  String get categoryCleaning;

  /// No description provided for @categoryPainting.
  ///
  /// In en, this message translates to:
  /// **'Painting'**
  String get categoryPainting;

  /// No description provided for @categoryCarpentry.
  ///
  /// In en, this message translates to:
  /// **'Carpentry'**
  String get categoryCarpentry;

  /// No description provided for @categoryAppliances.
  ///
  /// In en, this message translates to:
  /// **'Appliances'**
  String get categoryAppliances;

  /// No description provided for @categoryGardening.
  ///
  /// In en, this message translates to:
  /// **'Gardening'**
  String get categoryGardening;

  /// No description provided for @categoryTileSemantics.
  ///
  /// In en, this message translates to:
  /// **'{label}, {count, plural, =1{{count} provider} other{{count} providers}}'**
  String categoryTileSemantics(String label, int count);

  /// No description provided for @reviewCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} review} other{{count} reviews}}'**
  String reviewCount(int count);

  /// No description provided for @providerIdLabel.
  ///
  /// In en, this message translates to:
  /// **'ID {code}'**
  String providerIdLabel(String code);

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navBookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get navBookings;

  /// No description provided for @navSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get navSaved;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navLeads.
  ///
  /// In en, this message translates to:
  /// **'Leads'**
  String get navLeads;

  /// No description provided for @navMyJobs.
  ///
  /// In en, this message translates to:
  /// **'My Jobs'**
  String get navMyJobs;

  /// No description provided for @navEarnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get navEarnings;

  /// No description provided for @titleNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get titleNotifications;

  /// No description provided for @titleJobDetails.
  ///
  /// In en, this message translates to:
  /// **'Job details'**
  String get titleJobDetails;

  /// No description provided for @titleJobPayment.
  ///
  /// In en, this message translates to:
  /// **'Job completion / payment'**
  String get titleJobPayment;

  /// No description provided for @jobUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Job unavailable'**
  String get jobUnavailableTitle;

  /// No description provided for @jobUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'This job is no longer assigned to you. Go back to view your jobs.'**
  String get jobUnavailableMessage;

  /// No description provided for @providerGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String providerGreeting(String name);

  /// No description provided for @providerTagline.
  ///
  /// In en, this message translates to:
  /// **'Your work, all in one place.'**
  String get providerTagline;

  /// No description provided for @newRequests.
  ///
  /// In en, this message translates to:
  /// **'New requests'**
  String get newRequests;

  /// No description provided for @todaysJobs.
  ///
  /// In en, this message translates to:
  /// **'Today\'\'s jobs'**
  String get todaysJobs;

  /// No description provided for @monthlyEarnings.
  ///
  /// In en, this message translates to:
  /// **'Monthly earnings'**
  String get monthlyEarnings;

  /// No description provided for @upcomingJob.
  ///
  /// In en, this message translates to:
  /// **'Upcoming job'**
  String get upcomingJob;

  /// No description provided for @noUpcomingTitle.
  ///
  /// In en, this message translates to:
  /// **'No upcoming jobs yet'**
  String get noUpcomingTitle;

  /// No description provided for @noUpcomingMessage.
  ///
  /// In en, this message translates to:
  /// **'Accepted jobs scheduled in the future will appear here.'**
  String get noUpcomingMessage;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @noNewRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'No new job requests'**
  String get noNewRequestsTitle;

  /// No description provided for @noNewRequestsMessage.
  ///
  /// In en, this message translates to:
  /// **'Requests will appear here when a customer books your services.'**
  String get noNewRequestsMessage;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @errorAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access was denied. Please contact support.'**
  String get errorAccessDenied;

  /// No description provided for @errorUnableToConnect.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect. Check your connection and retry.'**
  String get errorUnableToConnect;

  /// No description provided for @errorNotAvailableYet.
  ///
  /// In en, this message translates to:
  /// **'This data is not available yet. Please contact support.'**
  String get errorNotAvailableYet;

  /// No description provided for @errorUnableToSave.
  ///
  /// In en, this message translates to:
  /// **'Unable to save or load your data. Please try again.'**
  String get errorUnableToSave;

  /// No description provided for @errorUnableToLoad.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your data. Please try again.'**
  String get errorUnableToLoad;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'New request'**
  String get statusPending;

  /// No description provided for @statusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get statusConfirmed;

  /// No description provided for @statusOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get statusOnTheWay;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get statusInProgress;

  /// No description provided for @statusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get statusDeclined;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown status'**
  String get statusUnknown;

  /// No description provided for @viewRequest.
  ///
  /// In en, this message translates to:
  /// **'View request'**
  String get viewRequest;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get viewDetails;

  /// No description provided for @notProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notProvided;

  /// No description provided for @notScheduled.
  ///
  /// In en, this message translates to:
  /// **'Not scheduled'**
  String get notScheduled;

  /// No description provided for @textSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSizeLabel;

  /// No description provided for @textSizeNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get textSizeNormal;

  /// No description provided for @textSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get textSizeLarge;

  /// No description provided for @textSizeExtraLarge.
  ///
  /// In en, this message translates to:
  /// **'Extra large'**
  String get textSizeExtraLarge;

  /// No description provided for @searchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchLabel;

  /// No description provided for @verifiedBadge.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verifiedBadge;

  /// No description provided for @fromPrice.
  ///
  /// In en, this message translates to:
  /// **'From {amount}'**
  String fromPrice(String amount);

  /// No description provided for @ratingSemantics.
  ///
  /// In en, this message translates to:
  /// **'Rated {rating} out of 5'**
  String ratingSemantics(String rating);

  /// No description provided for @selectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selectedLabel;

  /// No description provided for @emptyProvidersTitle.
  ///
  /// In en, this message translates to:
  /// **'No providers found'**
  String get emptyProvidersTitle;

  /// No description provided for @loadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Did not work'**
  String get loadErrorTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'si', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'si':
      return AppLocalizationsSi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
