import axios from "axios";
import { HTTP_ERROR_MESSAGES } from "./constants/httpErrors";

// Đọc biến môi trường theo Vite, fallback về localhost để dev nhanh
const apiUrl = (typeof import.meta !== 'undefined' && import.meta.env?.VITE_API_URL) ||
    (typeof process !== 'undefined' ? process.env?.VITE_API_URL : undefined) ||
    'https://localhost:7252/api';

const api = axios.create({
    baseURL: apiUrl,
    timeout: 30000, // 30 giây
    headers: {
        "Content-Type": "application/json",
    },
});

// ===== Interceptor Request =====
api.interceptors.request.use(
    (config) => {
        const token = localStorage.getItem("token");
        if (token) {
            config.headers.Authorization = `Bearer ${token}`;
        }

        // Nếu gửi FormData thì bỏ Content-Type để browser tự set boundary
        if (config.data instanceof FormData && config.headers) {
            delete config.headers["Content-Type"];
        }

        return config;
    },
    (error) => Promise.reject(error)
);

// ===== Interceptor Response =====
api.interceptors.response.use(
    (response) => response,
    (error) => {
        // TIMEOUT
        if (error.code === "ECONNABORTED" || error.message.includes("timeout")) {
            return Promise.reject(new Error("Yêu cầu mất quá nhiều thời gian, vui lòng thử lại sau."));
        }

        // KHÔNG NHẬN ĐƯỢC PHẢN HỒI (mạng / SSL / CORS)
        if (error.request && !error.response) {
            return Promise.reject(new Error("Không nhận được phản hồi từ máy chủ."));
        }

        // LỖI TỪ BACKEND
        if (error.response) {
            const status = error.response.status;

            if (status === 401) {
                error.customMessage = "Phiên đăng nhập đã hết hạn";
                return Promise.reject(error);
            }

            if (status === 403) {
                error.customMessage = "Không có quyền truy cập";
                return Promise.reject(error);
            }

            // Giữ nguyên cấu trúc lỗi validation (400 Bad Request)
            if (status === 400 && error.response.data?.errors) {
                return Promise.reject(error.response.data);
            }

            if (status === 409 && error.response.data?.message) {
                return Promise.reject(error.response.data);
            }

            let message = "";
            if (typeof error.response.data === "string" && error.response.data.trim() !== "") {
                message = error.response.data;
            } else {
                message =
                    error.response.data?.message ||
                    HTTP_ERROR_MESSAGES[status] ||
                    `Lỗi HTTP status ${status}`;
            }

            // gắn thêm customMessage để frontend dùng
            error.customMessage = message;
            return Promise.reject(error);
        }

        return Promise.reject(error);
    }
);

export default api;
