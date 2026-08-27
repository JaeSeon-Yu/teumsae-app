import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import 'core/bindings/initial_binding.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_pages.dart';

class TeumsaeApp extends StatelessWidget {
  const TeumsaeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '틈새',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialBinding: InitialBinding(),
      initialRoute: AppPages.initial,
      getPages: AppPages.pages,
      // 한국어 전용 서비스라서 Material 기본 위젯 문구도 한국어로 고정합니다.
      locale: const Locale('ko'),
      fallbackLocale: const Locale('ko'),
      supportedLocales: const [Locale('ko'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
