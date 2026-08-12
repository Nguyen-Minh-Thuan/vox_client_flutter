import '../../../core/messaging/notification_signal.dart';
import 'models/app_notification.dart';
import 'notification_graphql_api.dart';
import 'notification_rest_api.dart';

/// Gộp hai nửa của thông báo (đọc qua GraphQL, ghi qua REST) và giữ cho badge
/// chuông luôn khớp với thứ vừa xảy ra trên màn hình.
class NotificationRepository {
  NotificationRepository(this._graphQLApi, this._restApi);

  final NotificationGraphQLApi _graphQLApi;
  final NotificationRestApi _restApi;

  Future<NotificationPage> getPage({String? cursor, int limit = 20}) {
    return _graphQLApi.getMyNotifications(cursor: cursor, limit: limit);
  }

  /// Đồng bộ badge với server. Gọi khi mở app và mỗi lần mở màn thông báo --
  /// push chỉ cộng dồn tại chỗ nên có thể lệch (đọc trên web, gỡ app rồi cài lại...).
  Future<int> refreshUnreadCount() async {
    final count = await _graphQLApi.getUnreadCount();
    NotificationSignal.instance.setUnreadCount(count);
    return count;
  }

  /// Trừ badge ngay tại chỗ thay vì query lại: đọc một thông báo thì đúng bằng
  /// một đơn vị, không cần thêm một vòng mạng chỉ để biết điều đó.
  Future<void> markRead(String id) async {
    await _restApi.markRead(id);
    NotificationSignal.instance.decrementUnread();
  }

  Future<void> markAllRead() async {
    await _restApi.markAllRead();
    NotificationSignal.instance.clearUnread();
  }
}
