import 'package:flutter/foundation.dart';

import '../network/api_client.dart';
import '../network/api_endpoints.dart';

/// Nền tảng mà backend chấp nhận cho một thiết bị nhận thông báo.
///
/// Enum `NotificationDevicePlatform` bên vox chỉ có WEB/ANDROID/IOS, và use case
/// đăng ký gọi thẳng `valueOf(platform.toUpperCase())` -- gửi "desktop" sẽ ăn 400
/// "Nền tảng desktop không được hỗ trợ", nên desktop trả `null` và bỏ qua hẳn
/// việc đăng ký.
String? currentPushPlatform() {
  if (kIsWeb) return 'WEB';
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => 'ANDROID',
    TargetPlatform.iOS => 'IOS',
    _ => null,
  };
}

/// Đăng ký/gỡ thiết bị này khỏi danh sách nhận push của tài khoản đang đăng nhập.
class NotificationDeviceApi {
  NotificationDeviceApi._();

  /// Backend upsert theo `ON CONFLICT (installation_id)`, nên gọi lại bao nhiêu lần
  /// cũng không sinh dòng rác -- và mỗi lần gọi làm mới `last_seen_at`, thứ mà job
  /// dọn dẹp dùng để xoá thiết bị im lặng quá 90 ngày.
  ///
  /// Cần access token: endpoint là `@PreAuthorize("isAuthenticated()")`.
  static Future<void> register({
    required String deviceId,
    required String platform,
    required String installationId,
  }) async {
    await ApiClient().post(
      ApiEndpoints.notificationDevices,
      data: {
        'deviceId': deviceId,
        'platform': platform,
        'installationId': installationId,
      },
    );
  }

  /// Chỉ dùng khi người dùng chủ động tắt thông báo trên máy này.
  ///
  /// Đăng xuất thì KHÔNG cần gọi: backend đã tự gỡ thiết bị theo
  /// `DeviceSessionRevokedEvent` (xoá theo userId + deviceId).
  static Future<void> unregister(String installationId) async {
    await ApiClient().delete(ApiEndpoints.notificationDevice(installationId));
  }
}
