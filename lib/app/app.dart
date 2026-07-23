
import 'package:flutter/material.dart';

import '../core/storage/preference_storage.dart';
import 'theme.dart';
import 'router.dart';



class App extends StatelessWidget {
  const App({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VOX Client',
      debugShowCheckedModeBanner: false,
      navigatorKey: AppRouter.navigatorKey,
      theme: AppTheme.lightTheme,
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRouter.login,
    );
  }
}

