export const HTTP_ERROR_MESSAGES: Record<number, string> = {
  400: "Yêu cầu không hợp lệ.",
  401: "Bạn chưa đăng nhập hoặc phiên đăng nhập đã hết hạn.",
  403: "Bạn không có quyền truy cập vào tài nguyên này.",
  404: "Không tìm thấy tài nguyên.",
  500: "Lỗi hệ thống. Vui lòng thử lại sau.",
  502: "Lỗi từ máy chủ trung gian.",
  503: "Máy chủ hiện không khả dụng. Thử lại sau.",
  504: "Máy chủ phản hồi quá chậm.",
};
export const DEFAULT_ERROR_MESSAGE = "Đã xảy ra lỗi không xác định.";
