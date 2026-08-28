import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import 'place_detail.dart';
import 'place_review.dart';
import 'places_repository.dart';

/// 장소 상세 화면 상태. [PlaceDetailBinding]이 라우트 진입 시 등록합니다.
///
/// 장소 id는 라우트 파라미터(`/places/:id`)로 받습니다.
class PlaceDetailController extends GetxController {
  PlaceDetailController({required PlacesRepository repository, required this.id})
      : _repository = repository;

  final PlacesRepository _repository;
  final int id;

  final _place = Rxn<PlaceDetail>();
  final _isLoading = true.obs;
  final _errorMessage = RxnString();

  final _rating = ReviewValidators.defaultRating.obs;
  final _isSubmittingReview = false.obs;
  final _deletingReviewId = RxnInt();
  final _reviewError = RxnString();

  PlaceDetail? get place => _place.value;
  bool get isLoading => _isLoading.value;
  String? get errorMessage => _errorMessage.value;

  /// 후기 작성 폼에서 고른 별점.
  int get rating => _rating.value;

  bool get isSubmittingReview => _isSubmittingReview.value;

  /// 삭제 중인 후기 id. 그 항목의 버튼만 잠그는 데 씁니다.
  int? get deletingReviewId => _deletingReviewId.value;

  /// 후기 작성·삭제 실패 문구. 장소를 못 불러온 것과는 다른 상황이라
  /// [errorMessage]와 따로 둡니다.
  String? get reviewError => _reviewError.value;

  List<PlaceReview> get reviews => place?.reviews ?? const [];

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    _isLoading.value = true;
    _errorMessage.value = null;

    try {
      _place.value = await _repository.getPlace(id);
    } on ApiException catch (error) {
      _place.value = null;
      // 404는 서버 메시지가 영문일 수 있어 화면 문구를 따로 둡니다.
      _errorMessage.value =
          error.statusCode == 404 ? '없는 장소이거나 삭제된 장소입니다.' : error.message;
    } on Object {
      _place.value = null;
      _errorMessage.value = '장소 정보를 불러오지 못했습니다.';
    } finally {
      _isLoading.value = false;
    }
  }

  void changeRating(int value) {
    if (ReviewValidators.validateRating(value) != null) {
      return;
    }
    _rating.value = value;
  }

  /// 후기를 등록하고 상세를 다시 불러옵니다.
  ///
  /// 평균 별점과 후기 수는 서버가 계산하므로(`PlaceService`) 로컬에서 더하지 않고
  /// 다시 받습니다. 웹은 화면에서 평균을 다시 계산하지만, 그러면 서버 값과
  /// 어긋날 수 있습니다. 저장 기능도 같은 이유로 다시 불러옵니다.
  ///
  /// 성공하면 `true`. 실패하면 [reviewError]를 채우고 `false`.
  Future<bool> submitReview(String comment) async {
    if (_isSubmittingReview.value) {
      return false;
    }

    final invalid = ReviewValidators.validateComment(comment);
    if (invalid != null) {
      // 서버에 보내지 않고 즉시 알립니다.
      _reviewError.value = invalid;
      return false;
    }

    _isSubmittingReview.value = true;
    _reviewError.value = null;

    try {
      await _repository.createReview(
        placeId: id,
        rating: _rating.value,
        comment: comment.trim(),
      );
      _rating.value = ReviewValidators.defaultRating;
      await load();
      return true;
    } on ApiException catch (error) {
      _reviewError.value = error.message;
      return false;
    } on Object {
      _reviewError.value = '후기를 등록하지 못했습니다.';
      return false;
    } finally {
      _isSubmittingReview.value = false;
    }
  }

  /// 후기를 삭제하고 상세를 다시 불러옵니다.
  ///
  /// 성공하면 `true`. 실패하면 [reviewError]를 채우고 `false`.
  Future<bool> deleteReview(int reviewId) async {
    if (_deletingReviewId.value != null) {
      return false;
    }

    _deletingReviewId.value = reviewId;
    _reviewError.value = null;

    try {
      await _repository.deleteReview(placeId: id, reviewId: reviewId);
      await load();
      return true;
    } on ApiException catch (error) {
      _reviewError.value = error.message;
      return false;
    } on Object {
      _reviewError.value = '후기를 삭제하지 못했습니다.';
      return false;
    } finally {
      _deletingReviewId.value = null;
    }
  }

  void clearReviewError() => _reviewError.value = null;
}
