import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../account/account_screen.dart';
import '../places/search_screen.dart';
import '../saved/saved_screen.dart';
import 'shell_controller.dart';
import 'shell_tab.dart';

/// 앱의 첫 화면. 하단 탭으로 검색·저장·내 정보를 오갑니다.
///
/// [IndexedStack]을 쓰므로 탭을 옮겨도 각 화면의 상태(검색 결과, 스크롤)가 유지됩니다.
class MainShell extends GetView<ShellController> {
  const MainShell({super.key});

  static const _icons = <ShellTab, (IconData, IconData)>{
    ShellTab.search: (Icons.search_outlined, Icons.search),
    ShellTab.saved: (Icons.bookmark_border, Icons.bookmark),
    ShellTab.account: (Icons.person_outline, Icons.person),
  };

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        body: IndexedStack(
          index: controller.tabIndex,
          children: const [SearchScreen(), SavedScreen(), AccountScreen()],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: controller.tabIndex,
          onDestinationSelected: controller.changeTabIndex,
          destinations: [
            for (final tab in ShellTab.values)
              NavigationDestination(
                icon: Icon(_icons[tab]!.$1),
                selectedIcon: Icon(_icons[tab]!.$2),
                label: tab.label,
              ),
          ],
        ),
      ),
    );
  }
}
