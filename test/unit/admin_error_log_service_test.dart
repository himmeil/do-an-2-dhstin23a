import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diadiem_quanh_day/features/tim_kiem/services/admin_error_log_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('admin error record maps a known code and Firestore timestamp', () {
    final lastSeen = DateTime.utc(2026, 11, 4, 10);
    final record = AdminErrorEntry.fromMap({
      'code': AdminErrorCode.nearbySearchFailed.value,
      'lastSeenAt': Timestamp.fromDate(lastSeen),
    });

    expect(record.code, AdminErrorCode.nearbySearchFailed);
    expect(record.lastSeenAt?.isAtSameMomentAs(lastSeen), isTrue);
  });

  test('unknown admin error codes are rejected', () {
    expect(
      () => AdminErrorEntry.fromMap({
        'code': 'UNREGISTERED_ERROR',
        'lastSeenAt': null,
      }),
      throwsFormatException,
    );
  });
}
