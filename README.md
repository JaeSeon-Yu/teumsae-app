# 틈새 앱 (teumsae_app)

약속 전후에 쉬어갈 "틈새 쉼터"를 찾는 Flutter 앱입니다.
같은 서비스의 웹(`../teumsae-web`)과 서버(`../teumsae-server`)와 짝을 이룹니다.

- 앱 식별자: `kr.co.jason.teumsae` (Android/iOS 동일)
- 표시 이름: 틈새
- Flutter 3.41.2 / Dart 3.11
- 상태관리·DI·라우팅: **GetX** (`get`)

## 실행

API 서버 주소는 `--dart-define`으로 넣습니다. 넣지 않으면 운영 서버를 가리킵니다.

```bash
flutter pub get

# 로컬 서버 (Android 에뮬레이터는 10.0.2.2가 호스트의 localhost입니다)
flutter run --dart-define=TEUMSAE_API_BASE_URL=http://10.0.2.2:8080

# iOS 시뮬레이터
flutter run --dart-define=TEUMSAE_API_BASE_URL=http://localhost:8080
```

## 검증

```bash
flutter analyze
flutter test
```

## 구조

```
lib/
  main.dart                        runApp(TeumsaeApp())
  src/
    app.dart                       GetMaterialApp (initialBinding + getPages)
    routes/
      app_routes.dart              라우트 이름 상수
      app_pages.dart               GetPage 목록 + 로그인 리다이렉트 미들웨어
    core/
      bindings/initial_binding.dart  Get.put/lazyPut 의존성 등록
      config/app_config.dart       API 주소, 검색 기본값 (--dart-define)
      network/
        api_client.dart            Dio + 토큰 부착 + 401 자동 갱신
        api_exception.dart         서버 {status, message} → 화면용 예외
        auth_tokens.dart           토큰 + 만료 시각 계산
      storage/token_store.dart     보안 저장소 (+ 테스트용 메모리 구현)
      theme/                       웹 globals.css 토큰 포팅
    features/
      auth/                        AuthController(GetxController) · 리포지토리 · 검증 · 화면
      places/                      PlacesController(GetxController) · 모델 · 목록 화면
    widgets/app_callout.dart       안내/에러 배너
```

### GetX 사용 규칙

- **의존성**: 모든 등록은 `core/bindings/initial_binding.dart`에 모읍니다.
  화면에서 `Get.put`을 직접 호출하지 않습니다.
  - `InitialBinding`: TokenStore, ApiClient, AuthRepository, `AuthController`,
    PlacesRepository를 `permanent: true`로 등록합니다.
    로그인 상태는 라우트가 바뀌어도 유지돼야 하기 때문입니다.
  - `PlacesBinding`: 검색 화면에서만 쓰는 `PlacesController`를 `lazyPut`으로 등록합니다.
- **상태 노출**: 컨트롤러는 `Rx` 필드를 `private`으로 두고 getter만 공개합니다.
  화면은 `Obx(() => ...)` 안에서 그 getter를 읽습니다.
  (`Obx` 밖에서 읽으면 갱신되지 않습니다.)
- **화면 이동**: `Get.toNamed` / `Get.offNamed` / `Get.offAllNamed` +
  `AppRoutes` 상수를 씁니다. 문자열을 직접 쓰지 않습니다.
- **에러 표시**: 컨트롤러가 `errorMessage`(한글)를 들고 있고 화면은 그대로 렌더링합니다.
  서버 메시지가 이미 한글이라 별도 매핑이 필요 없습니다.

`ApiClient`는 `AuthController`를 직접 참조하지 않습니다.
(`ApiClient → AuthController → AuthRepository → ApiClient`로 순환하기 때문)
대신 `InitialBinding`이 넘긴 콜백이 호출 시점에 `Get.find<AuthController>()`로 찾습니다.

## 서버 연동 규칙

앱은 쿠키를 쓸 수 없으므로 웹용 `/api/auth/*`가 아니라 **토큰 엔드포인트**를 씁니다.

| 기능 | 엔드포인트 |
| --- | --- |
| 회원가입 | `POST /api/auth/token/signup` |
| 로그인 | `POST /api/auth/token/login` |
| 토큰 갱신 | `POST /api/auth/token/refresh` |
| 로그아웃 | `POST /api/auth/token/logout` |
| 검색 | `GET /api/places/search` (로그인 불필요) |

- access token은 `Authorization: Bearer`로 보냅니다.
- 401을 받으면 `ApiClient`가 refresh를 한 번 시도하고 원 요청을 재시도합니다.
  갱신까지 실패하면 토큰을 지우고 `AuthController.handleSessionExpired()`로 알립니다.
- refresh token은 OS 보안 저장소(Keychain / Android KeyStore)에만 둡니다.

### 입력 규칙 (서버와 동일하게 유지)

`lib/src/features/auth/auth_validators.dart`의 상수는 서버
`NativeSignupRequest`의 제약과 같은 값이어야 합니다. 한쪽만 바꾸면 앱에서는
통과했는데 서버가 400을 주는 상황이 생깁니다.

- 아이디: 4~20자, `^[a-z0-9_]+$`
- 비밀번호: 8~72자 (72자는 bcrypt 한계)
- 닉네임: 선택, 50자 이하

## 아직 하지 않은 것

- 위치 권한 및 현재 위치 검색: 지금은 웹과 같은 기본 좌표(37.592, 127.016)로 검색합니다.
- 지도 화면, 장소 상세, 저장·등록, 소셜/Firebase 로그인.
- 다크 테마: 웹에도 다크 토큰이 없어 함께 정의한 뒤 옮기는 편이 낫습니다.
- Pretendard 폰트 에셋: 현재는 플랫폼 기본 한글 폰트를 씁니다.
