# 틈새 앱 (teumsae_app)

약속 전후에 쉬어갈 "틈새 쉼터"를 찾는 Flutter 앱입니다.
같은 서비스의 웹(`../teumsae-web`)과 서버(`../teumsae-server`)와 짝을 이룹니다.

- 앱 식별자: `kr.co.jason.teumsae` (Android/iOS 동일)
- 표시 이름: 틈새
- Flutter 3.41.2 / Dart 3.11
- 상태관리·DI·라우팅: **GetX** (`get`)

## 실행

이 프로젝트는 Dart 3.11(Flutter 3.41.x)이 필요합니다. `flutter --version`이 그보다 낮으면
`flutter pub get`이 의존성 해석 단계에서 실패합니다. 전역 SDK를 올릴 수 없는 환경에서는
아래처럼 이 프로젝트용 SDK 경로를 앞에 붙여 씁니다.

```bash
export PATH="$HOME/flutter-sdks/3.41.2/flutter/bin:$PATH"
```

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
      shell/                       하단 탭 셸(ShellController · ShellTab · MainShell)
      auth/                        AuthController(GetxController) · 리포지토리 · 검증 · 화면
      places/                      검색·상세 (컨트롤러 · 모델 · 표시 규칙 · 화면)
      saved/                       저장 목록 (SavedController · 저장 버튼 · 저장 탭)
      account/                     내 정보 탭 · 계정 설정 (SettingsController)
    widgets/
      app_callout.dart             안내/에러 배너
      app_badge.dart               상태·역할 배지 (웹 Badge 톤 포팅)
      app_section_card.dart        제목 + 내용 카드 (웹 SectionCard)
      score_badge.dart             점수 배지 (웹 ScoreBadge 색 구간 포팅)
```

`features/places/` 안의 역할 구분:

| 파일 | 역할 |
| --- | --- |
| `places_repository.dart` | `GET /api/places/search`, `GET /api/places/{id}` |
| `place_search_query.dart` | 검색 조건 + 선택값 열거형 (테마·예산·공간·시설·정렬) |
| `place_summary.dart` | 검색 결과 한 건 (점수·거리·추천 이유 포함) |
| `place_detail.dart` | 상세 응답 (편의·상황 점수, 운영시간, 경고, 태그) |
| `place_format.dart` | 거리·비용·체류·공간 표시 규칙 (웹 `format.ts`) |
| `operating_hours.dart` | 자유 형식 `openingHoursText` 파싱 |
| `search_filters_sheet.dart` | 검색 조건 바텀시트 (웹 `SearchFilters`) |

### 화면 구조

`/` 하나가 하단 탭 셸(`MainShell`)이고, 검색·내 정보는 그 안의 탭입니다.
탭마다 라우트를 두지 않는 이유는 탭을 옮길 때 화면이 다시 만들어지면
검색 결과와 스크롤 위치가 사라지기 때문입니다. (`IndexedStack`으로 상태 유지)

로그인·회원가입만 셸 위에 쌓이는 별도 라우트입니다. 로그인에 성공하면
`Get.back()`으로 돌아가므로 사용자가 보고 있던 탭이 그대로 유지됩니다.
장소 상세(`/places/:id`)와 계정 설정(`/settings`)도 셸 위에 쌓입니다.
설정은 `RequireSignInMiddleware`로 막아 로그인하지 않으면 로그인 화면으로 보냅니다.

> 테스트에서 주의: `IndexedStack`의 선택되지 않은 탭은 offstage라
> 기본 finder가 찾지 못합니다. 탭 내용을 확인하려면 먼저 그 탭을 열어야 합니다.
> 상세 화면처럼 긴 `ListView`도 화면 밖 항목은 아직 만들어지지 않으므로
> `scrollUntilVisible`로 먼저 스크롤해야 합니다.

### GetX 사용 규칙

- **의존성**: 모든 등록은 `core/bindings/initial_binding.dart`에 모읍니다.
  화면에서 `Get.put`을 직접 호출하지 않습니다.
  - `InitialBinding`: TokenStore, ApiClient, AuthRepository, `AuthController`,
    PlacesRepository, SavedRepository, `SavedController`를 `permanent: true`로 등록합니다.
    로그인 상태와 저장 상태는 라우트가 바뀌어도 유지돼야 하기 때문입니다.
  - `ShellBinding`: 셸(`/`)에서만 쓰는 `ShellController`와 `PlacesController`를
    `lazyPut`으로 등록합니다. 검색 화면이 셸의 탭 안에 있어 수명이 같습니다.
  - `PlaceDetailBinding`: 상세(`/places/:id`)의 `PlaceDetailController`.
    장소 id는 `Get.parameters['id']`로 받습니다.
  - `SettingsBinding`: 설정(`/settings`)의 `SettingsController`.
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
| 장소 상세 | `GET /api/places/{id}` (로그인 불필요, 비로그인은 `saved=false`) |
| 저장 목록 | `GET /api/saved-places` |
| 저장 / 저장 취소 | `POST` / `DELETE /api/saved-places/{placeId}` (204) |
| 닉네임 변경 | `PATCH /api/auth/nickname` |
| 비밀번호 변경 | `POST /api/auth/password` (204) |
| 회원 탈퇴 | `DELETE /api/auth/me` (204, 본문에 비밀번호) |

마지막 세 개는 토큰 전용 경로(`/api/auth/token/*`)가 아니라 웹과 같은 `/api/auth/*`를
씁니다. 서버 `JwtAuthenticationFilter`가 Authorization 헤더를 쿠키보다 먼저 보기 때문에
쿠키 없이도 그대로 동작합니다.

> 비밀번호를 바꾸면 서버가 그 사용자의 refresh token을 **모두 폐기**합니다
> (`AuthService.changePassword` → `revokeAllForUser`). 그래서 앱은 변경 직후
> 새 비밀번호로 재로그인해 세션을 잇습니다. 그러지 않으면 다음 토큰 갱신 시점에
> 갑자기 로그아웃됩니다.

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

## 웹 기능 이식 순서

웹(`../teumsae-web`)과 같은 기능을 아래 순서로 하나씩 옮깁니다.
의존성이 적고 다음 단계의 토대가 되는 것부터 둔 순서입니다.

1. ~~하단 탭 셸~~ (완료: 검색 · 내 정보)
2. ~~장소 상세~~ (완료: `GET /api/places/{id}`)
3. ~~저장(북마크)~~ (완료: 저장 탭 · 검색·상세의 저장 버튼)
4. ~~설정~~ (완료: 닉네임·비밀번호 변경, 회원 탈퇴)
5. ~~검색 필터 전체~~ (완료: 조건 시트 · 정렬 · 영업중 토글)
6. 위치 권한 + 현재 위치 검색
7. 리뷰 (`/api/places/{id}/reviews`)
8. 지도 (검색 결과 · 상세) — 네이티브 지도 SDK 선정 필요
9. 장소 등록·수정 + 내가 등록한 장소
10. 소셜 로그인 (Firebase Google/Apple)
11. 공개 프로필 + 차단·신고

관리자 화면은 앱에 넣지 않습니다. 웹에서만 쓰는 운영 화면입니다.

### 점수 표시 규칙

`restScore` · `scoreLabel` · `reasons`는 모두 서버(`RestScoreCalculator`)가 계산합니다.
앱은 받은 값을 그대로 보여줍니다.

웹은 목록 카드에서만 서버 `scoreLabel`을 버리고 테마별 문구("쉼점수" 등)를 쓰지만,
앱은 목록과 상세 모두 서버 `scoreLabel`을 씁니다. 테마는 이미 상단 탭에 보이고,
같은 장소의 점수 문구가 화면마다 달라지는 것은 사용자에게 혼란만 줍니다.

상세 화면에는 점수 배지가 없습니다. `GET /api/places/{id}`는 검색 조건(거리·날씨·체류)
없이 장소 하나만 보는 것이어서 서버가 `restScore`를 계산하지 않습니다. 웹도 같습니다.

### 검색 조건

선택값은 모두 열거형(`place_search_query.dart`)입니다. 문자열로 두면 서버가 받지 않는
값을 넘겨도 컴파일이 통과해 버립니다. 서버 `parseEnum`은 대소문자를 가리지 않지만
값은 웹과 같게 보냅니다. (필요 시설만 소문자: `wifi,quiet`)

- 조건 시트(남은 시간 · 반경 · 실내/실외 · 예산 · 필요 시설)는 초안을 들고 있다가
  "조건 적용"에서 한 번만 검색합니다. 항목마다 검색하면 요청이 여러 번 나가고
  결과가 계속 흔들립니다.
- 테마 · 정렬 · 지금 운영중은 시트 밖에 있어 누르는 즉시 검색합니다.
  그래서 시트의 활성 개수 배지에도 세지 않습니다.
- 날씨(`weather`)는 항상 `ANY`입니다. 웹에도 선택 UI가 없습니다.
  점수 계산에서 상황 적합도가 빠지는 셈이라, 넣으려면 웹과 함께 정하는 편이 낫습니다.

### 저장 상태

저장 여부의 출처는 `SavedController` 하나입니다. 검색 카드·상세 화면·저장 탭이
모두 이 컨트롤러를 읽습니다. 화면마다 따로 들고 있으면 상세에서 저장한 장소가
목록에서는 저장 안 된 것으로 보입니다.

- 로그인하면(자동 로그인 포함) `AuthController.userChanges`를 받아 목록을 불러옵니다.
- 로그아웃·세션 만료 시 목록과 저장 id를 비웁니다.
- 그래서 서버 응답의 `saved` 필드는 앱에서 쓰지 않습니다.
- 저장 직후에는 목록을 다시 불러옵니다. 저장 시각과 표시 정보를 서버가 채워 주기
  때문에 로컬에서 항목을 만들 수 없습니다. 저장 취소는 로컬에서 지우기만 합니다.
- 로그인하지 않은 상태에서 저장 버튼을 누르면 서버에 401을 만들지 않고
  바로 로그인 화면으로 보냅니다.

### 웹과 일부러 다르게 한 것

- 운영시간 요일 배지 색: 웹은 주말(`토`/`일`) 판정을 평일보다 먼저 해서
  "평일"에 들어 있는 '일' 때문에 평일이 주말 색으로 보입니다.
  앱은 평일을 먼저 봅니다. (`operating_hours.dart`)
- 저장 성공 알림: 웹은 `router.refresh()`로 화면을 다시 그리지만
  앱은 버튼 모양(`저장` ↔ `저장됨`)으로만 알리고 스낵바는 실패할 때만 띄웁니다.
- 비밀번호 변경 후: 웹은 쿠키가 남아 그대로 쓰지만 앱은 재로그인으로 토큰을 새로 받습니다.
  (위 "서버 연동 규칙" 참고)
- 소셜 계정의 비밀번호 변경: 웹은 폼을 그대로 보여 주고 서버 실패로 알려 주지만,
  앱은 `provider != LOCAL`이면 폼 대신 안내 문구를 띄웁니다.
- 검색 반경 선택: 웹에는 없습니다. 웹은 지도를 움직여 범위를 바꾸지만
  앱에는 아직 지도가 없어 반경 외에는 넓힐 방법이 없습니다.
- 테마 탭에 "전체"(`ANY`)를 넣었습니다. 웹 `THEME_ORDER`와 같은 구성입니다.
  라벨도 웹 `THEME_CONFIG`에 맞췄습니다. (휴식 · 쇼핑 · 즐길거리 · 화장실)
- 클라이언트 재정렬: 웹은 서버에 `sort`를 보내고 받은 목록을 화면에서 또 정렬합니다.
  앱은 서버 정렬을 그대로 씁니다.

## 아직 하지 않은 것

- 위치 권한 및 현재 위치 검색: 지금은 웹과 같은 기본 좌표(37.592, 127.016)로 검색합니다.
- 지도, 장소 등록·수정, 후기, 소셜/Firebase 로그인. (위 이식 순서 참고)
- 상세 화면의 외부 지도 앱 연결: 지도 단계에서 함께 붙입니다.
- 내 정보 탭의 저장·등록 개수 카드: 등록 장소 기능과 함께 넣는 편이 낫습니다.
- 다크 테마: 웹에도 다크 토큰이 없어 함께 정의한 뒤 옮기는 편이 낫습니다.
- Pretendard 폰트 에셋: 현재는 플랫폼 기본 한글 폰트를 씁니다.
