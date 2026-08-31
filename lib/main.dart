import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/core/auth/firebase_bootstrap.dart';
import 'src/core/map/map_bootstrap.dart';

Future<void> main() async {
  // 지도 SDK는 첫 지도 위젯보다 먼저, Firebase는 첫 소셜 로그인보다 먼저
  // 준비돼야 합니다. 둘 다 실패해도 예외 없이 이유만 남기므로 앱은 계속 뜹니다.
  WidgetsFlutterBinding.ensureInitialized();
  await MapBootstrap.initialize();
  await FirebaseBootstrap.initialize();

  runApp(const TeumsaeApp());
}
