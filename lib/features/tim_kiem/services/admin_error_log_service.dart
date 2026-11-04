import 'package:cloud_firestore/cloud_firestore.dart';

enum AdminErrorCode {
  nearbySnapshotReadFailed(
    'OSM_SNAPSHOT_READ_FAILED',
    'Không đọc được dữ liệu bản đồ OpenStreetMap đã đóng gói.',
  ),
  nearbySearchFailed(
    'NEARBY_SEARCH_FAILED',
    'Tra cứu địa điểm quanh đây thất bại.',
  ),
  placesStreamFailed(
    'PLACES_READ_FAILED',
    'Không đọc được danh sách địa điểm trên Firestore.',
  ),
  commentsReadFailed(
    'COMMENTS_READ_FAILED',
    'Không đọc được bình luận của địa điểm.',
  ),
  commentWriteFailed('COMMENT_WRITE_FAILED', 'Không gửi được bình luận.'),
  favoritesStreamFailed(
    'FAVORITES_READ_FAILED',
    'Không đọc được danh sách địa điểm yêu thích.',
  ),
  locationLookupFailed(
    'LOCATION_LOOKUP_FAILED',
    'Không lấy được vị trí thiết bị.',
  ),
  favoriteWriteFailed(
    'FAVORITE_WRITE_FAILED',
    'Không lưu được thay đổi địa điểm yêu thích.',
  ),
  draftReadFailed('DRAFT_READ_FAILED', 'Không đọc được bản nháp địa điểm.'),
  draftPublishFailed(
    'DRAFT_PUBLISH_FAILED',
    'Không đăng được bản nháp lên Firestore.',
  ),
  displayPreferencesReadFailed(
    'DISPLAY_SETTINGS_READ_FAILED',
    'Không đọc được cài đặt hiển thị.',
  ),
  displayPreferencesWriteFailed(
    'DISPLAY_SETTINGS_WRITE_FAILED',
    'Không lưu được cài đặt hiển thị.',
  ),
  signOutFailed('SIGN_OUT_FAILED', 'Không đăng xuất được.'),
  mapRefreshFailed('MAP_REFRESH_FAILED', 'Không cập nhật được dữ liệu bản đồ.'),
  mapSourceReadFailed(
    'MAP_SOURCE_READ_FAILED',
    'Không đọc được danh sách snapshot bản đồ.',
  ),
  mapSourceApplyFailed(
    'MAP_SOURCE_APPLY_FAILED',
    'Không áp dụng được snapshot bản đồ.',
  );

  const AdminErrorCode(this.value, this.description);

  final String value;
  final String description;

  static AdminErrorCode fromValue(String value) => values.firstWhere(
    (code) => code.value == value,
    orElse: () => throw FormatException('Unknown admin error code: $value'),
  );
}

class AdminErrorEntry {
  const AdminErrorEntry({required this.code, this.lastSeenAt});

  final AdminErrorCode code;
  final DateTime? lastSeenAt;

  factory AdminErrorEntry.fromMap(Map<String, dynamic> data) {
    final rawCode = data['code'];
    if (rawCode is! String) {
      throw const FormatException('Admin error code is missing.');
    }

    final rawTimestamp = data['lastSeenAt'];
    final lastSeenAt = switch (rawTimestamp) {
      Timestamp timestamp => timestamp.toDate(),
      DateTime dateTime => dateTime,
      null => null,
      _ => throw const FormatException('Admin error timestamp is invalid.'),
    };

    return AdminErrorEntry(
      code: AdminErrorCode.fromValue(rawCode),
      lastSeenAt: lastSeenAt,
    );
  }
}

abstract interface class AdminErrorLogService {
  Future<void> record(AdminErrorCode code);

  Stream<List<AdminErrorEntry>> watchRecent();
}

class FirestoreAdminErrorLogService implements AdminErrorLogService {
  FirestoreAdminErrorLogService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _errors =>
      _firestore.collection('admin_error_codes');

  @override
  Future<void> record(AdminErrorCode code) => _errors.doc(code.value).set({
    'code': code.value,
    'lastSeenAt': FieldValue.serverTimestamp(),
  });

  @override
  Stream<List<AdminErrorEntry>> watchRecent() => _errors
      .orderBy('lastSeenAt', descending: true)
      .limit(AdminErrorCode.values.length)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((document) => AdminErrorEntry.fromMap(document.data()))
            .toList(growable: false),
      );
}
