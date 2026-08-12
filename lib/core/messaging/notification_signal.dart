import 'package:flutter/foundation.dart';

/// Cầu nối một chiều giữa tầng push (core) và UI (feature).
///
/// Push chỉ mang tiêu đề/nội dung và khoá điều hướng, KHÔNG mang id của dòng
/// notification trong DB — nên nó chỉ đóng vai trò tín hiệu: badge cộng thêm một,
/// còn danh sách thật vẫn do `myNotifications` trả về. Nhờ vậy dữ liệu hiển thị
/// luôn là dữ liệu server, không bao giờ lệch với thứ đã lưu.
class NotificationSignal {
  NotificationSignal._();
  static final instance = NotificationSignal._();

  /// Số thông báo chưa đọc — badge trên chuông đọc thẳng giá trị này.
  final ValueNotifier<int> unreadCount = ValueNotifier(0);

  /// Tăng mỗi khi có push mới. Màn hình thông báo lắng nghe để nạp lại từ server.
  final ValueNotifier<int> revision = ValueNotifier(0);

  void onPushReceived() {
    unreadCount.value += 1;
    revision.value += 1;
  }

  void setUnreadCount(int value) => unreadCount.value = value < 0 ? 0 : value;

  void decrementUnread([int by = 1]) => setUnreadCount(unreadCount.value - by);

  void clearUnread() => setUnreadCount(0);
}
