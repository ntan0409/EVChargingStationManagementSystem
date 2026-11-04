import { useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { jwtDecode } from "jwt-decode";
import "./SocialLogin.css";

export default function SocialLogin() {
  const navigate = useNavigate();

  const handleCredentialResponse = async (response) => {
    console.log("✅ ID Token:", response.credential);
    try {
      const res = await fetch("https://localhost:7252/api/Auth/login-google", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ idToken: response.credential }),
      });

      if (!res.ok) {
        const errorText = await res.text();
        console.error("Google login failed on backend:", errorText);
        alert("Đăng nhập Google thất bại: " + errorText);
        return;
      }

      const data = await res.json();
      const actualToken = data.token;
      if (!actualToken) {
        console.error("Không tìm thấy token trong phản hồi:", data);
        return;
      }

      // Lưu token vào localStorage
      localStorage.setItem("token", actualToken);

      // Giải mã token và lưu thông tin người dùng giống như Auth.js
      const decoded = jwtDecode(actualToken);
      const role = decoded.role || (data.user && data.user.role) || "EVDriver";
      const name = decoded.name || (data.user && data.user.name) || "";
      const email = decoded.email || (data.user && data.user.email) || "";
      const userId = decoded.userId || decoded.nameid || decoded.sub || (data.user && data.user.id) || "";
      const avatar = decoded.avatar || (data.user && data.user.avatar) || "";

      localStorage.setItem("user_id", userId);
      localStorage.setItem("user_name", name);
      localStorage.setItem("email", email);
      localStorage.setItem("user_role", role);
      localStorage.setItem("user_role_raw", role);
      localStorage.setItem("user_avatar", avatar);

      // Bắn sự kiện để Navbar, Header và Layout cập nhật ngay lập tức
      if (typeof window !== "undefined") {
        window.dispatchEvent(new Event("auth-changed"));
      }

      console.log("Google Login thành công. User:", { userId, name, email, role, avatar });
      navigate("/");
    } catch (err) {
      console.error("Login failed:", err);
    }
  };

  useEffect(() => {
    if (!window.google) return;

    window.google.accounts.id.initialize({
      client_id: "688603250408-etb8ia4m3kl05nbi95gd6f4094606q1p.apps.googleusercontent.com",
      callback: handleCredentialResponse,
    });

    // Render nút Google
    window.google.accounts.id.renderButton(
      document.getElementById("googleBtn"),
      {
        theme: "outline",      
        size: "large",
        width: 280,             
        shape: "rectangular",
      }
    );
  }, []);

  return (
    <div className="social-login">
      {/* Wrapper để kéo dài nút và thêm text */}
      <div className="google-btn-wrapper">
        <div id="googleBtn"></div>
        <span className="google-text">Đăng nhập với Google</span>
      </div>
    </div>
  );
}
