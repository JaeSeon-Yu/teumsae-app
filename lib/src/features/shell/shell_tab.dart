/// 하단 탭 목록. 선언 순서가 곧 탭이 보이는 순서이자 [ShellController]의 인덱스입니다.
enum ShellTab {
  search('검색'),
  saved('저장'),
  account('내 정보'),
  ;

  const ShellTab(this.label);

  final String label;
}
