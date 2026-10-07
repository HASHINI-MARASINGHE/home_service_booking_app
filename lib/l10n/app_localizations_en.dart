// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get languageSwitchLabel => 'Language';

  @override
  String customerHomeGreeting(String name) {
    return 'Hello, $name 👋';
  }

  @override
  String get customerHomeTitle => 'Your Home,\nOur Care';

  @override
  String get customerHomeSubtitle =>
      'Book trusted professionals for every home need, all in one place.';

  @override
  String get searchHint => 'Search providers or services...';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get servicesForYourHome => 'Services for your home';

  @override
  String get verifiedProviders => 'Verified providers';

  @override
  String get seeAll => 'See all';

  @override
  String providerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count providers',
      one: '$count provider',
    );
    return '$_temp0';
  }

  @override
  String get providersLoadError => 'Providers could not be loaded right now.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get noVerifiedProviders =>
      'No verified providers yet. Providers show up here as soon as our team verifies them.';

  @override
  String noProvidersMatch(String query) {
    return 'No providers match \'\'$query\'\'. Try another word or clear the search.';
  }

  @override
  String get noProvidersInCategory =>
      'No providers in this category yet. Try another category.';

  @override
  String get categoryAll => 'All';

  @override
  String get categoryPlumbing => 'Plumbing';

  @override
  String get categoryElectrical => 'Electrical';

  @override
  String get categoryAc => 'AC & Cooling';

  @override
  String get categoryCleaning => 'Cleaning';

  @override
  String get categoryPainting => 'Painting';

  @override
  String get categoryCarpentry => 'Carpentry';

  @override
  String get categoryAppliances => 'Appliances';

  @override
  String get categoryGardening => 'Gardening';

  @override
  String categoryTileSemantics(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count providers',
      one: '$count provider',
    );
    return '$label, $_temp0';
  }

  @override
  String reviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '$count review',
    );
    return '$_temp0';
  }

  @override
  String providerIdLabel(String code) {
    return 'ID $code';
  }

  @override
  String get navHome => 'Home';

  @override
  String get navBookings => 'Bookings';

  @override
  String get navSaved => 'Saved';

  @override
  String get navProfile => 'Profile';

  @override
  String get navLeads => 'Leads';

  @override
  String get navMyJobs => 'My Jobs';

  @override
  String get navEarnings => 'Earnings';

  @override
  String get titleNotifications => 'Notifications';

  @override
  String get titleJobDetails => 'Job details';

  @override
  String get titleJobPayment => 'Job completion / payment';

  @override
  String get jobUnavailableTitle => 'Job unavailable';

  @override
  String get jobUnavailableMessage =>
      'This job is no longer assigned to you. Go back to view your jobs.';

  @override
  String providerGreeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get providerTagline => 'Your work, all in one place.';

  @override
  String get newRequests => 'New requests';

  @override
  String get todaysJobs => 'Today\'\'s jobs';

  @override
  String get monthlyEarnings => 'Monthly earnings';

  @override
  String get upcomingJob => 'Upcoming job';

  @override
  String get noUpcomingTitle => 'No upcoming jobs yet';

  @override
  String get noUpcomingMessage =>
      'Accepted jobs scheduled in the future will appear here.';

  @override
  String get viewAll => 'View all';

  @override
  String get noNewRequestsTitle => 'No new job requests';

  @override
  String get noNewRequestsMessage =>
      'Requests will appear here when a customer books your services.';

  @override
  String get retry => 'Retry';

  @override
  String get errorAccessDenied => 'Access was denied. Please contact support.';

  @override
  String get errorUnableToConnect =>
      'Unable to connect. Check your connection and retry.';

  @override
  String get errorNotAvailableYet =>
      'This data is not available yet. Please contact support.';

  @override
  String get errorUnableToSave =>
      'Unable to save or load your data. Please try again.';

  @override
  String get errorUnableToLoad => 'Unable to load your data. Please try again.';

  @override
  String get statusPending => 'New request';

  @override
  String get statusConfirmed => 'Confirmed';

  @override
  String get statusOnTheWay => 'On the way';

  @override
  String get statusInProgress => 'In progress';

  @override
  String get statusDeclined => 'Declined';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusUnknown => 'Unknown status';

  @override
  String get viewRequest => 'View request';

  @override
  String get viewDetails => 'View details';

  @override
  String get notProvided => 'Not provided';

  @override
  String get notScheduled => 'Not scheduled';
}
