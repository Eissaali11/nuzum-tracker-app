/// ============================================
/// 📦 نموذج الاستجابة العام - Generic API Response
/// ============================================
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? error;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
  });

  factory ApiResponse.success(T data, [String? message]) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
    );
  }

  factory ApiResponse.error(String error, [String? message]) {
    return ApiResponse(
      success: false,
      error: error,
      message: message,
    );
  }
}

