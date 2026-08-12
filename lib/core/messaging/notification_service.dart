import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../app/router.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../storage/preference_storage.dart';

/// Thông báo cục bộ (khay hệ thống). Chỉ cần cho push tới lúc app đang MỞ:
/// khi app ở nền hoặc đã thoát, FCM có sẵn khối `notification` nên hệ điều hành
/// tự dựng khay, plugin này không tham gia.
class NotificationService {
  NotificationService._();
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const linuxInit = LinuxInitializationSettings(defaultActionName: 'Open');
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
        linux: linuxInit,
      ),
      onDidReceiveNotificationResponse: (_) => openNotifications(),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Điểm vào chung khi người dùng bấm vào một thông báo, dù là khay cục bộ hay
  /// khay hệ thống của FCM.
  ///
  /// Không nhận id: payload của push mang `eventType` và khoá điều hướng của
  /// thực thể (candidateResultId, appealId...), KHÔNG mang id dòng notification,
  /// nên không có gì để mở đúng một mục. Mở thẳng danh sách là thứ trung thực nhất.
  static void openNotifications() {
    AppRouter.navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  /// Dựng khay cho push tới lúc app đang mở (foreground).
  static Future<void> show({
    required String title,
    required String body,
    required String payload,
  }) async {
    if (!await PreferenceStorage().getNotificationsEnabled()) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'vox_notifications',
        'Vox Notifications',
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      id: DateTime.now().microsecondsSinceEpoch.remainder(1 << 31),
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }
}
