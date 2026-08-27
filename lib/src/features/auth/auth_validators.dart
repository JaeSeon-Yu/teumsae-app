/// 로그인/회원가입 입력 검증.
///
/// 서버 `NativeSignupRequest`의 제약과 반드시 같은 값을 씁니다.
/// 서버도 같은 내용을 한글로 응답하지만(`GlobalExceptionHandler`),
/// 왕복 없이 즉시 알려주는 편이 입력 중 피드백에 좋습니다.
abstract final class AuthValidators {
  /// 서버: `@Size(min = 4, max = 20)`, `@Pattern("^[a-z0-9_]+$")`
  static const usernameMinLength = 4;
  static const usernameMaxLength = 20;

  /// 서버: `@Size(min = 8, max = 72)` (bcrypt 72바이트 한계)
  static const passwordMinLength = 8;
  static const passwordMaxLength = 72;

  /// 서버: `@Size(max = 50)`
  static const nicknameMaxLength = 50;

  static final _usernamePattern = RegExp(r'^[a-z0-9_]+$');

  static const usernameHint = '영문 소문자, 숫자, 밑줄(_)로 4~20자';
  static const passwordHint = '8자 이상 72자 이하';

  /// 통과하면 `null`, 아니면 화면에 그대로 띄울 한글 문구를 반환합니다.
  static String? validateUsername(String? value) {
    final username = value?.trim() ?? '';

    if (username.isEmpty) {
      return '아이디를 입력해 주세요.';
    }
    if (username.length < usernameMinLength ||
        username.length > usernameMaxLength) {
      return '아이디는 $usernameMinLength자 이상 $usernameMaxLength자 이하로 입력해 주세요.';
    }
    if (!_usernamePattern.hasMatch(username)) {
      return '아이디는 영문 소문자, 숫자, 밑줄(_)만 사용할 수 있습니다.';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return '비밀번호를 입력해 주세요.';
    }
    if (password.length < passwordMinLength ||
        password.length > passwordMaxLength) {
      return '비밀번호는 $passwordMinLength자 이상 $passwordMaxLength자 이하로 입력해 주세요.';
    }
    return null;
  }

  /// 로그인은 길이 규칙을 강제하지 않습니다.
  /// 규칙이 바뀌기 전에 만든 계정이 로그인조차 못 하게 되면 안 됩니다.
  static String? validateLoginPassword(String? value) {
    return (value ?? '').isEmpty ? '비밀번호를 입력해 주세요.' : null;
  }

  /// 닉네임은 선택 입력입니다.
  static String? validateNickname(String? value) {
    final nickname = value?.trim() ?? '';

    if (nickname.isEmpty) {
      return null;
    }
    if (nickname.length > nicknameMaxLength) {
      return '닉네임은 $nicknameMaxLength자 이하로 입력해 주세요.';
    }
    return null;
  }
}
