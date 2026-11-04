// import { useState } from 'react';
import { jwtDecode } from 'jwt-decode';
import api from './axios';
// import { roleSlugMap } from '../Utils/RoleSlugMap';

const BASE_URL = '/Auth';


export const getAuthStatus = () => {
  const token = localStorage.getItem('token');

  if (token) {
    try {
      const decoded = jwtDecode(token);

      // Debug: Log decoded data để kiểm tra
      console.log('JWT Decoded:', decoded);

      return {
        isAuthenticated: true,
        user: {
          email: decoded.email,
          name: decoded.name,
          role:
            decoded.role ||
            decoded.user_role ||
            decoded.user_role_raw ||
            decoded.Role ||
            decoded.UserRole ||
            [],
          // Thêm các field khác có thể có trong JWT
          userId: decoded.userId || decoded.sub || decoded.id,
          phone: decoded.phone,
          avatar: decoded.avatar,
          // Log tất cả các field có trong JWT
          ...decoded
        },
      }
    } catch (error) {
      console.error('Lỗi khi decode JWT:', error);
      // Nếu decode lỗi, xóa token cũ
      localStorage.removeItem('token');
      return {
        isAuthenticated: false,
        user: null,
      }
    }
  }

  return {
    isAuthenticated: false,
    user: null,
  }
};

export const register = async (email, password, name, phone) => {
  try {
    const response = await api.post(`${BASE_URL}/register`, { email, password, name, phone });
    return response.data;
  } catch (error) {
    const data = error?.response?.data;

    // Nếu data là mảng và có phần tử
    if (Array.isArray(data) && data.length > 0) {
      // Lấy message đầu tiên
      const serverMsg = data[0].description || data[0].message;
      if (serverMsg) throw new Error(serverMsg);
    }

    // Nếu data là object
    if (data?.description || data?.message) {
      throw new Error(data.description || data.message);
    }

    // fallback
    throw new Error(error.message || "Lỗi không xác định từ server");
  }
};


export const login = async (email, password) => { // đăng nhập
  try {
    const response = await api.post(
      `${BASE_URL}/login`,
      { email, password }
    );

    // Debug: Log toàn bộ response để xem cấu trúc
    console.log('Full response:', response);
    console.log('Response data:', response.data);
    console.log('Type of response.data:', typeof response.data);

    const token = response.data;

    // Kiểm tra nếu token là object, lấy trường token
    let actualToken;
    if (typeof token === 'object' && token !== null) {
      // Thử các trường có thể chứa token
      actualToken = token.token || token.accessToken || token.access_token || token.jwt;
      console.log('Token từ object:', actualToken);
    } else if (typeof token === 'string') {
      actualToken = token;
    } else {
      throw new Error('Token không hợp lệ: không phải string hoặc object');
    }

    if (!actualToken) {
      throw new Error('Không tìm thấy token trong response');
    }

    // Decode token để lấy thông tin user
    const decoded = jwtDecode(actualToken);

    // Lưu token và thông tin user vào localStorage
    localStorage.setItem("token", actualToken);
    localStorage.setItem("user_id", decoded.nameid || decoded.userId || decoded.sub || "");
    localStorage.setItem("user_name", decoded.name || "");
    localStorage.setItem("email", decoded.email || "");
    localStorage.setItem("user_role", decoded.role || "customer");
    localStorage.setItem("user_role_raw", decoded.role || "customer");
    localStorage.setItem("user_avatar", decoded.avatar || "");

    // Phát sự kiện để UI biết auth state đã thay đổi
    if (typeof window !== 'undefined') {
      window.dispatchEvent(new Event('auth-changed'));
    }

    // Log để debug
    console.log('Token đã lưu:', actualToken);
    console.log('User info đã lưu:', {
      userId: decoded.nameid || decoded.userId || decoded.sub,
      name: decoded.name,
      email: decoded.email,
      role: decoded.role
    });

    return {
      token: actualToken,
      user: {
        userId: decoded.nameid || decoded.userId || decoded.sub,
        name: decoded.name,
        email: decoded.email,
        role: decoded.role,
        avatar: decoded.avatar
      }
    };

  } catch (error) {
    console.error('Error during login:', error);
    throw error;
  }
}

// export const confirmEmail = async (userId, code) => { // xác nhận email
//   try {
//     const response = await api.get(
//       `/confirm-email`,
//       { params: { userId, code } }
//     );
//     return response.data;
//   } catch (error) {
//     console.error('Error during email confirmation:', error);
//     throw error;
//   }
// }

export const confirmEmail = async (userId, token) => { // xác nhận email
  try {
    const response = await api.patch(`${BASE_URL}/confirm-email`, { userId, token });
    return response.data;
  } catch (error) {
    console.error('Error during email confirmation:', error);
    throw error;
  }
}

export const resendConfirmationEmail = async (email) => { // gửi lại email xác nhận
  try {
    const response = await api.get(`${BASE_URL}/resend-confirm-email?email=${email}`);
    return response.data;

  } catch (error) {
    console.error('Error during resending confirmation email:', error);
    throw error;
  }
}

// Thêm hàm logout để xóa dữ liệu người dùng
export const logout = () => {
  try {
    localStorage.removeItem('token');
    localStorage.removeItem('user_id');
    localStorage.removeItem('user_name');
    localStorage.removeItem('email');
    localStorage.removeItem('user_role');
    localStorage.removeItem('user_role_raw');
    localStorage.removeItem('user_avatar');
  } finally {
    // Phát sự kiện để UI biết auth state đã thay đổi
    if (typeof window !== 'undefined') {
      window.dispatchEvent(new Event('auth-changed'));
      window.location.href = '/login';
    }
  }
}

export const forgotPassword = async (email) => { // quên mật khẩu
  const attempts = [
    // Theo Swagger: POST với Email ở query string
    { method: 'post', url: `${BASE_URL}/forgot-password`, params: { Email: email } },
    // Ưu tiên biến thể thường gặp ở ASP.NET Core: PascalCase property
    { method: 'post', url: `${BASE_URL}/forgot-password`, data: { Email: email } },
    // Thử URL PascalCase
    { method: 'post', url: `${BASE_URL}/ForgotPassword`, data: { Email: email } },
    // Thử property camelCase
    { method: 'post', url: `${BASE_URL}/forgot-password`, data: { email } },
    // Thử dạng application/x-www-form-urlencoded
    { method: 'post', url: `${BASE_URL}/forgot-password`, data: new URLSearchParams({ Email: email }), headers: { 'Content-Type': 'application/x-www-form-urlencoded' } },
    // Thử multipart/form-data
    (() => { const fd = new FormData(); fd.append('Email', email); return { method: 'post', url: `${BASE_URL}/forgot-password`, data: fd }; })(),
  ];

  let lastError;
  for (const attempt of attempts) {
    try {
      const response = await api.request({
        method: attempt.method,
        url: attempt.url,
        data: attempt.data,
        params: attempt.params,
        headers: attempt.headers,
      });
      return response.data;
    } catch (error) {
      lastError = error;
      const status = error?.response?.status;
      if (status && status >= 500) break; // lỗi server thì dừng thử
      continue; // thử biến thể tiếp theo
    }
  }
  console.error('Error during forgot password:', lastError);
  throw lastError;
}

export const resetPassword = async (userId, token, newPassword) => { // đặt lại mật khẩu
  try {
    const response = await api.post(
      `${BASE_URL}/reset-password`,
      { userId, token, newPassword }
    );
    return response.data;
  } catch (error) {
    console.error('Error during password reset:', error);
    throw error;
  }
}
export const changePassword = async (oldPassword, newPassword, confirmPassword) => {
  try {
    const response = await api.post(`${BASE_URL}/change-password`, {
      oldPassword, newPassword, confirmPassword
    });
    return response.data
  } catch (error) {
    console.error('ErrorChange-password', error);
    throw error;
  }
}
