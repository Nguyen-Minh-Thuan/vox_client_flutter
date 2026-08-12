import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../app/widgets.dart';
import '../../../core/messaging/notification_signal.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/graphql_client.dart';
import '../data/notification_graphql_api.dart';
import '../data/notification_repository.dart';
import '../data/notification_rest_api.dart';
import 'notifications_screen.dart';

/// Chuông thông báo kèm badge số chưa đọc.
///
/// Badge đọc thẳng [NotificationSignal] nên nó tự cập nhật ở cả hai chiều: push
/// tới thì cộng thêm, màn thông báo đánh dấu đã đọc thì trừ đi — không màn nào
/// phải biết đến màn nào.
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  @override
  void initState() {
    super.initState();
    // Lấy số thật từ server mỗi lần màn chủ dựng lại. Best-effort: badge sai còn
    // hơn màn chủ hỏng vì một lượt mạng phụ.
    NotificationRepository(
      NotificationGraphQLApi(GraphQLClient()),
      NotificationRestApi(ApiClient()),
    ).refreshUnreadCount().catchError((_) => 0);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NotificationSignal.instance.unreadCount,
      builder: (context, count, child) {
        if (count <= 0) return child!;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            child!,
            Positioned(right: -1, top: -1, child: _Badge(count)),
          ],
        );
      },
      child: IconCircle(
        Icons.notifications_none,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.count);

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      constraints: const BoxConstraints(minWidth: 18),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 10,
          height: 1.3,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
