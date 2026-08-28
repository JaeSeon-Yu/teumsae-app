abstract final class AppRoutes {
  /// 하단 탭 셸. 검색·내 정보 탭이 이 라우트 안에 있습니다.
  ///
  /// 탭은 라우트를 따로 두지 않습니다. 라우트로 나누면 탭을 옮길 때마다
  /// 화면이 다시 만들어져 스크롤 위치와 검색 결과가 사라집니다.
  static const home = '/';
  static const login = '/login';
  static const signup = '/signup';

  /// 장소 상세. 등록에 쓰는 패턴이라 이동할 때는 [placeDetail]을 쓰세요.
  static const placeDetailPattern = '/places/:id';

  static String placeDetail(int id) => '/places/$id';

  /// 계정 설정. 로그인이 필요합니다.
  static const settings = '/settings';
}
