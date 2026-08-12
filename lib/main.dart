import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

import 'app/app.dart';
import 'core/messaging/notification_service.dart';
import 'core/messaging/push_messaging_service.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  JustAudioMediaKit.ensureInitialized(linux: true, windows: true);
  await dotenv.load(fileName: ".env");
  await NotificationService.init();
  await PushMessagingService.init();
  runApp(const App());
}

