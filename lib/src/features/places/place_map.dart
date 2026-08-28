import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import '../../core/map/map_bootstrap.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_callout.dart';
import 'place_summary.dart';

/// 지도 위젯을 만드는 자리.
///
/// 지도는 플랫폼 뷰(AndroidView/UiKitView)라 위젯 테스트에서 그릴 수 없습니다.
/// 그래서 화면은 `NaverMap`을 직접 쓰지 않고 이 인터페이스를 통해 받습니다.
/// 테스트는 [FakePlaceMapBuilder]처럼 가벼운 대역을 등록합니다.
abstract interface class PlaceMapBuilder {
  /// 검색 결과 지도. 마커를 누르면 [onPlaceTap], 지도를 옮긴 뒤
  /// "이 지역 재검색"을 누르면 [onSearchArea]가 불립니다.
  Widget results({
    required List<PlaceSummary> places,
    required double centerLat,
    required double centerLng,
    required ValueChanged<int> onPlaceTap,
    required void Function(double lat, double lng) onSearchArea,
  });

  /// 장소 하나만 보여 주는 지도. 상세 화면에서 씁니다.
  Widget single({
    required double lat,
    required double lng,
    required String name,
  });
}

/// 실제 네이버 지도 구현.
class NaverPlaceMapBuilder implements PlaceMapBuilder {
  const NaverPlaceMapBuilder();

  @override
  Widget results({
    required List<PlaceSummary> places,
    required double centerLat,
    required double centerLng,
    required ValueChanged<int> onPlaceTap,
    required void Function(double lat, double lng) onSearchArea,
  }) {
    if (!MapBootstrap.isAvailable) {
      return _MapUnavailable(reason: MapBootstrap.unavailableReason);
    }

    return _SearchResultsMap(
      places: places,
      centerLat: centerLat,
      centerLng: centerLng,
      onPlaceTap: onPlaceTap,
      onSearchArea: onSearchArea,
    );
  }

  @override
  Widget single({
    required double lat,
    required double lng,
    required String name,
  }) {
    if (!MapBootstrap.isAvailable) {
      return _MapUnavailable(reason: MapBootstrap.unavailableReason);
    }

    return _SinglePlaceMap(lat: lat, lng: lng, name: name);
  }
}

/// 키가 없거나 지도를 못 쓸 때의 안내. 지도 자리만 대체하고
/// 나머지 화면은 그대로 동작합니다.
class _MapUnavailable extends StatelessWidget {
  const _MapUnavailable({required this.reason});

  final String? reason;

  @override
  Widget build(BuildContext context) {
    return AppCallout(
      title: reason ?? '지도를 표시할 수 없습니다.',
      description: '지도 없이도 목록으로 장소를 찾을 수 있습니다.',
      tone: CalloutTone.info,
    );
  }
}

/// 검색 결과 마커 지도.
///
/// 지도를 옮기면 바로 재검색하지 않고 "이 지역 재검색" 버튼을 띄웁니다.
/// 손가락을 뗄 때마다 검색하면 요청이 계속 나가고 결과가 흔들립니다.
/// (웹도 지도 이동과 재검색을 분리해 둡니다)
class _SearchResultsMap extends StatefulWidget {
  const _SearchResultsMap({
    required this.places,
    required this.centerLat,
    required this.centerLng,
    required this.onPlaceTap,
    required this.onSearchArea,
  });

  final List<PlaceSummary> places;
  final double centerLat;
  final double centerLng;
  final ValueChanged<int> onPlaceTap;
  final void Function(double lat, double lng) onSearchArea;

  @override
  State<_SearchResultsMap> createState() => _SearchResultsMapState();
}

class _SearchResultsMapState extends State<_SearchResultsMap> {
  NaverMapController? _controller;
  NLatLng? _movedCenter;

  @override
  void didUpdateWidget(_SearchResultsMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.places != widget.places) {
      _drawMarkers();
    }

    // 재검색이나 현재 위치로 중심이 바뀌면 지도도 따라갑니다.
    if (oldWidget.centerLat != widget.centerLat ||
        oldWidget.centerLng != widget.centerLng) {
      _movedCenter = null;
      _controller?.updateCamera(
        NCameraUpdate.withParams(
          target: NLatLng(widget.centerLat, widget.centerLng),
        ),
      );
    }
  }

  Future<void> _drawMarkers() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    await controller.clearOverlays(type: NOverlayType.marker);

    final markers = <NMarker>{};
    for (final place in widget.places) {
      final marker = NMarker(
        id: place.id.toString(),
        position: NLatLng(place.lat, place.lng),
        caption: NOverlayCaption(text: place.name),
      );
      marker.setOnTapListener((_) => widget.onPlaceTap(place.id));
      markers.add(marker);
    }

    if (markers.isNotEmpty) {
      await controller.addOverlayAll(markers);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        NaverMap(
          options: NaverMapViewOptions(
            initialCameraPosition: NCameraPosition(
              target: NLatLng(widget.centerLat, widget.centerLng),
              zoom: 14,
            ),
            // 실내지도·회전·기울기는 쉼터를 찾는 데 쓸 일이 없어 끕니다.
            indoorEnable: false,
            rotationGesturesEnable: false,
            tiltGesturesEnable: false,
          ),
          onMapReady: (controller) {
            _controller = controller;
            _drawMarkers();
          },
          onCameraIdle: () async {
            final controller = _controller;
            if (controller == null) {
              return;
            }

            // 패키지가 정확한 값은 getCameraPosition으로 받으라고 안내합니다.
            // (nowCameraPosition은 experimental입니다)
            final position = await controller.getCameraPosition();
            if (!mounted) {
              return;
            }

            setState(() => _movedCenter = position.target);
          },
        ),
        if (_movedCenter != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: AppSpacing.lg,
            child: Center(
              child: FilledButton.icon(
                onPressed: () {
                  final center = _movedCenter!;
                  setState(() => _movedCenter = null);
                  widget.onSearchArea(center.latitude, center.longitude);
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('이 지역 재검색'),
              ),
            ),
          ),
      ],
    );
  }
}

/// 상세 화면용 지도. 손대지 못하게 막고 위치만 보여 줍니다.
/// (웹 `StaticPlaceMap`과 같은 취급입니다)
class _SinglePlaceMap extends StatelessWidget {
  const _SinglePlaceMap({
    required this.lat,
    required this.lng,
    required this.name,
  });

  final double lat;
  final double lng;
  final String name;

  @override
  Widget build(BuildContext context) {
    return NaverMap(
      options: NaverMapViewOptions(
        initialCameraPosition: NCameraPosition(
          target: NLatLng(lat, lng),
          zoom: 16,
        ),
        indoorEnable: false,
        scrollGesturesEnable: false,
        zoomGesturesEnable: false,
        rotationGesturesEnable: false,
        tiltGesturesEnable: false,
        scaleBarEnable: false,
      ),
      onMapReady: (controller) {
        controller.addOverlay(
          NMarker(
            id: 'place',
            position: NLatLng(lat, lng),
            caption: NOverlayCaption(text: name),
          ),
        );
      },
    );
  }
}
