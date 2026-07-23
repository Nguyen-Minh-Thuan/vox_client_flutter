import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/app.dart';
import 'core/notifications/notification_service.dart';
import 'core/notifications/push_notification_service.dart';



Future<void> main() async {
  await dotenv.load(fileName: ".env");
  await NotificationService.init();
  await PushNotificationService.init();
  runApp(const App());
}

