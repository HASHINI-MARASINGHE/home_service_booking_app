import 'package:flutter/material.dart';

import '../../models/booking.dart';
import '../../models/review.dart';
import '../../widgets/common/review_widgets.dart';
import '../../widgets/provider/provider_widgets.dart';

class ProviderJobsScreen extends StatelessWidget {
  const ProviderJobsScreen({
    super.key,
    required this.bookings,
    required this.tab,
    required this.onTab,
    required this.onOpen,
    this.watchReview,
  });
  final List<Booking> bookings;
  final int tab;
  final ValueChanged<int> onTab;
  final ValueChanged<Booking> onOpen;

  /// Streams the customer's review of a job, shown on completed jobs.
  final Stream<Review?> Function(String bookingId)? watchReview;

  @override
  Widget build(BuildContext context) {
    final filtered = bookings
        .where(
          (b) => switch (tab) {
            0 => b.status == BookingStatus.pending,
            1 => b.status == BookingStatus.confirmed,
            _ => b.status.isHistory,
          },
        )
        .toList();
    if (tab == 1) {
      filtered.sort(
        (a, b) => (a.scheduledAt ?? DateTime(9999)).compareTo(
          b.scheduledAt ?? DateTime(9999),
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Requests')),
                ButtonSegment(value: 1, label: Text('Confirmed')),
                ButtonSegment(value: 2, label: Text('History')),
              ],
              selected: {tab},
              showSelectedIcon: false,
              onSelectionChanged: (selection) => onTab(selection.first),
            ),
          ),
        ),
        Expanded(
          child: ProviderPage(
            children: [
              if (filtered.isEmpty)
                ProviderEmpty(
                  title: [
                    'No new job requests',
                    'No confirmed jobs',
                    'No job history yet',
                  ][tab],
                  message: [
                    'New requests assigned to you will appear here.',
                    'Accept a request to add it to your confirmed jobs.',
                    'Completed, declined and cancelled jobs remain here for your records.',
                  ][tab],
                ),
              ...filtered.map(
                (b) => BookingTile(
                  booking: b,
                  onTap: () => onOpen(b),
                  footer:
                      b.status == BookingStatus.completed && watchReview != null
                      ? ReviewRatingLine(
                          prefix: 'Customer rating',
                          stream: watchReview!(b.id),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
