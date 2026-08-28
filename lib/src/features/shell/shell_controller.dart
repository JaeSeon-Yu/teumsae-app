import 'package:get/get.dart';

import 'shell_tab.dart';

/// 어떤 탭이 열려 있는지만 들고 있는 컨트롤러.
///
/// 다른 화면에서도 탭을 옮길 수 있어야 하므로(예: 저장 버튼 → 저장 탭)
/// 셸 위젯의 `State`가 아니라 컨트롤러에 둡니다.
class ShellController extends GetxController {
  final _tab = ShellTab.search.obs;

  ShellTab get tab => _tab.value;
  int get tabIndex => _tab.value.index;

  /// [NavigationBar]가 넘겨주는 인덱스용.
  void changeTabIndex(int index) => goTo(ShellTab.values[index]);

  void goTo(ShellTab tab) => _tab.value = tab;
}
