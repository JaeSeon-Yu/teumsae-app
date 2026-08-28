import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_callout.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_user.dart';

/// 내 정보 탭. 웹 `/account`의 프로필 카드에 대응합니다.
///
/// 저장 목록·등록 장소·설정 메뉴는 해당 기능을 붙일 때 함께 추가합니다.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('내 정보')),
      body: Obx(() {
        // 앱을 켠 직후에는 저장된 토큰으로 자동 로그인을 시도하는 중입니다.
        // 이때 로그인 안내를 먼저 보여 주면 화면이 깜빡입니다.
        if (auth.isRestoring) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = auth.user;
        if (user == null) {
          return const _SignedOutView();
        }

        return _SignedInView(
          user: user,
          isSubmitting: auth.isSubmitting,
          onLogout: auth.logout,
        );
      }),
    );
  }
}

class _SignedOutView extends StatelessWidget {
  const _SignedOutView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const AppCallout(
          title: '로그인하면 틈새를 저장할 수 있습니다.',
          description: '마음에 든 쉼터를 모아 두고, 직접 장소를 등록할 수도 있습니다.',
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: () => Get.toNamed(AppRoutes.login),
          child: const Text('로그인'),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(
          onPressed: () => Get.toNamed(AppRoutes.signup),
          child: const Text('회원가입'),
        ),
      ],
    );
  }
}

class _SignedInView extends StatelessWidget {
  const _SignedInView({
    required this.user,
    required this.isSubmitting,
    required this.onLogout,
  });

  final AuthUser user;
  final bool isSubmitting;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                _Avatar(name: user.nickname),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.nickname,
                              style: textTheme.titleLarge,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          AppBadge(
                            user.isAdmin ? '관리자' : '일반 회원',
                            tone: user.isAdmin
                                ? BadgeTone.brand
                                : BadgeTone.positive,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text('@${user.username}', style: textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        OutlinedButton.icon(
          onPressed: () => Get.toNamed(AppRoutes.settings),
          icon: const Icon(Icons.settings_outlined, size: 18),
          label: const Text('계정 및 보안 설정'),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(
          onPressed: isSubmitting ? null : onLogout,
          child: Text(isSubmitting ? '처리 중...' : '로그아웃'),
        ),
      ],
    );
  }
}

/// 프로필 이미지가 없으므로 웹처럼 이름 앞 두 글자를 씁니다.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    // 이모지·자모 결합 문자가 깨지지 않도록 코드 단위가 아니라 글자 단위로 자릅니다.
    final initials = name.characters.take(2).toString().toUpperCase();

    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.brand600,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
