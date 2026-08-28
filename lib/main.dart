import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/core/map/map_bootstrap.dart';

Future<void> main() async {
  // 지도 SDK는 첫 지도 위젯보다 먼저 준비돼야 합니다.
  // 키가 없거나 인증이 거부돼도 예외 없이 이유만 남기므로 앱은 계속 뜹니다.
  WidgetsFlutterBinding.ensureInitialized();
  await MapBootstrap.initialize();

  runApp(const TeumsaeApp());
}
