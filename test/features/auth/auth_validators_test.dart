import 'package:flutter_test/flutter_test.dart';
import 'package:teumsae_app/src/features/auth/auth_validators.dart';

/// 서버 `NativeSignupRequest`의 제약과 앱 검증이 어긋나지 않는지 확인합니다.
/// 여기가 깨지면 앱에서는 통과했는데 서버가 400을 주는 상황이 생깁니다.
void main() {
  group('validateUsername', () {
    test('규칙을 만족하면 null', () {
      expect(AuthValidators.validateUsername('teumsae_user'), isNull);
      expect(AuthValidators.validateUsername('abcd'), isNull);
      expect(AuthValidators.validateUsername('a' * 20), isNull);
    });

    test('앞뒤 공백은 무시한다', () {
      expect(AuthValidators.validateUsername('  teumsae  '), isNull);
    });

    test('빈 값은 입력 요청 문구', () {
      expect(AuthValidators.validateUsername(''), '아이디를 입력해 주세요.');
      expect(AuthValidators.validateUsername(null), '아이디를 입력해 주세요.');
    });

    test('길이를 벗어나면 서버와 같은 4~20자 문구', () {
      const expected = '아이디는 4자 이상 20자 이하로 입력해 주세요.';
      expect(AuthValidators.validateUsername('abc'), expected);
      expect(AuthValidators.validateUsername('a' * 21), expected);
    });

    test('허용하지 않는 문자를 걸러낸다', () {
      const expected = '아이디는 영문 소문자, 숫자, 밑줄(_)만 사용할 수 있습니다.';
      expect(AuthValidators.validateUsername('Teumsae'), expected);
      expect(AuthValidators.validateUsername('teum-sae'), expected);
      expect(AuthValidators.validateUsername('틈새사용자'), expected);
      expect(AuthValidators.validateUsername('teum sae'), expected);
    });
  });

  group('validatePassword', () {
    test('8~72자면 null', () {
      expect(AuthValidators.validatePassword('password'), isNull);
      expect(AuthValidators.validatePassword('a' * 72), isNull);
    });

    test('서버 최소 길이(8자) 미달을 막는다', () {
      expect(
        AuthValidators.validatePassword('pass12'),
        '비밀번호는 8자 이상 72자 이하로 입력해 주세요.',
      );
    });

    test('bcrypt 한계(72자) 초과를 막는다', () {
      expect(
        AuthValidators.validatePassword('a' * 73),
        '비밀번호는 8자 이상 72자 이하로 입력해 주세요.',
      );
    });
  });

  group('validateLoginPassword', () {
    test('로그인은 길이 규칙을 적용하지 않는다', () {
      // 규칙이 강화되기 전에 만든 계정도 로그인은 되어야 합니다.
      expect(AuthValidators.validateLoginPassword('123'), isNull);
    });

    test('빈 값만 막는다', () {
      expect(AuthValidators.validateLoginPassword(''), '비밀번호를 입력해 주세요.');
    });
  });

  group('validateNickname', () {
    test('선택 입력이라 비어 있어도 통과', () {
      expect(AuthValidators.validateNickname(''), isNull);
      expect(AuthValidators.validateNickname(null), isNull);
      expect(AuthValidators.validateNickname('   '), isNull);
    });

    test('50자를 넘으면 막는다', () {
      expect(AuthValidators.validateNickname('가' * 50), isNull);
      expect(
        AuthValidators.validateNickname('가' * 51),
        '닉네임은 50자 이하로 입력해 주세요.',
      );
    });
  });
}
