import 'dart:async';

import 'package:firebase_core/firebase_core.dart';

import 'dispute_service.dart';
import 'image_upload_service.dart';

/// The chosen slot was taken by another booking between loading and saving.
class SlotTakenException implements Exception {
  const SlotTakenException();
}

/// The booking changed on the server (status/time) since it was displayed.
class BookingChangedException implements Exception {
  const BookingChangedException(this.message);
  final String message;
}

enum AppErrorKind { network, session, permission, notFound, conflict, other }

/// Maps backend/platform errors to friendly, non-technical messages so no
/// screen ever shows a raw exception.
abstract final class AppError {
  static AppErrorKind kind(Object error) {
    if (error is TimeoutException) {
      return AppErrorKind.network;
    }
    if (error is SlotTakenException || error is BookingChangedException) {
      return AppErrorKind.conflict;
    }
    if (error is FirebaseException) {
      return switch (error.code) {
        'unavailable' ||
        'network-request-failed' ||
        'deadline-exceeded' => AppErrorKind.network,
        'unauthenticated' ||
        'user-token-expired' ||
        'user-disabled' ||
        'user-not-found' => AppErrorKind.session,
        'permission-denied' || 'unauthorized' => AppErrorKind.permission,
        'not-found' || 'object-not-found' => AppErrorKind.notFound,
        'aborted' || 'failed-precondition' => AppErrorKind.conflict,
        _ => AppErrorKind.other,
      };
    }
    return AppErrorKind.other;
  }

  static String message(Object error) {
    if (error is SlotTakenException) {
      return 'That time slot was just booked. Please choose another.';
    }
    if (error is BookingChangedException) return error.message;
    if (error is ImageUploadException) return error.message;
    if (error is DisputeException) return error.message;
    if (error is ArgumentError) {
      return error.message?.toString() ?? 'Please check your input.';
    }
    if (error is StateError) return error.message;
    return switch (kind(error)) {
      AppErrorKind.network =>
        'You appear to be offline. Check your connection and try again.',
      AppErrorKind.session => 'Your session has expired. Please log in again.',
      AppErrorKind.permission =>
        'This action is not allowed for your account. Refresh and try again.',
      AppErrorKind.notFound => 'We could not find that record.',
      AppErrorKind.conflict =>
        'This booking just changed. Refresh and try again.',
      AppErrorKind.other => 'Something went wrong on our side. Please retry.',
    };
  }
}
