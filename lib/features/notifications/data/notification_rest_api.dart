import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

/// Phần ghi của thông báo. Đánh dấu đã đọc là REST (PATCH), còn đọc danh sách
/// thì bên GraphQL -- xem [NotificationGraphQLApi].
class NotificationRestApi {
  NotificationRestApi(this._client);

  final ApiClient _client;

  Future<void> markRead(String id) async {
    await _client.patch(ApiEndpoints.notificationRead(id));
  }

  Future<void> markAllRead() async {
    await _client.patch(ApiEndpoints.notificationsReadAll);
  }
}
