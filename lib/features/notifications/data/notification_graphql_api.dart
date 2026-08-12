import '../../../core/network/graphql_client.dart';
import 'models/app_notification.dart';

/// Phần đọc của thông báo. Backend không có REST cho danh sách -- chỉ có
/// `myNotifications` / `myUnreadNotificationCount` bên GraphQL.
class NotificationGraphQLApi {
  NotificationGraphQLApi(this._client);

  final GraphQLClient _client;

  /// Phân trang bằng cursor chứ không phải offset: `cursor` là id của phần tử
  /// cuối trang trước, backend lọc `id < cursor` và sắp xếp id giảm dần (id là
  /// UUIDv7 nên thứ tự id cũng chính là thứ tự thời gian).
  ///
  /// Backend chặn `limit` ở 100.
  Future<NotificationPage> getMyNotifications({String? cursor, int limit = 20}) async {
    final data = await _client.query('''
      query MyNotifications(\$cursor: ID, \$limit: Int!) {
        myNotifications(cursor: \$cursor, limit: \$limit) {
          content {
            id
            eventType
            title
            body
            payload
            readAt
            createdAt
          }
          nextCursor
          hasNext
        }
      }
    ''', variables: {'cursor': cursor, 'limit': limit});

    final page = data['myNotifications'] as Map<String, dynamic>?;
    if (page == null) return NotificationPage.empty;
    return NotificationPage.fromJson(page);
  }

  Future<int> getUnreadCount() async {
    final data = await _client.query('''
      query MyUnreadNotificationCount {
        myUnreadNotificationCount
      }
    ''');
    return (data['myUnreadNotificationCount'] as num?)?.toInt() ?? 0;
  }
}
