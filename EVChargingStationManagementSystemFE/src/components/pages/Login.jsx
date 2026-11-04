import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { Card } from "antd";
import { Zap, Mail, Lock } from "lucide-react";
import { login as loginApi } from "../../API/Auth";
import InputField from "../account/InputField";
import SocialLogin from "../account/SocialLogin";
import "./login.css";


const Login = () => {
  const navigate = useNavigate();
  const [formValues, setFormValues] = useState({ email: "", password: "" });
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    document.body.className = "login-body"; // set body class
    return () => {
      document.body.className = ""; // cleanup khi thoát trang
    };
  }, []);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormValues((prev) => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");

    if (!formValues.email || !formValues.password) {
      setError("Vui lòng nhập email và mật khẩu.");
      return;
    }

    try {
      setSubmitting(true);
      const result = await loginApi(formValues.email, formValues.password);


      // lấy role từ kết quả hoặc localStorage
      const userRole = (result?.user?.role || localStorage.getItem("user_role") || "")
        .trim()
        .toLowerCase();

      if (userRole === "admin") navigate("/admin");
      else if (userRole === "staff") navigate("/staff");
      else navigate("/");
      window.dispatchEvent(new Event("auth-changed"));

    } catch (err) {
      let msg = "Đăng nhập thất bại"; // mặc định

      if (err?.response?.status === 400) {
        // nếu axios trả lỗi 400
        msg = " Email Hoặc Mật Khẩu Không Đúng!";
      } else if (typeof err === "string") {
        msg = err;
      } else if (err?.message) {
        msg = err.message;
      }

      setError(msg);
    } finally {
      setSubmitting(false);
    }
  };


  return (
    <div className="login-page-wrapper">
      <div className="login-page-container">
        {/* Left Side - Branding */}
        <div className="login-branding">
          <div className="branding-content">
            <div className="brand-icon">
              <Zap size={64} color="white" />
            </div>
            <h1 className="brand-title">Hệ thống quản lý trạm sạc xe điện </h1>
            
            <div className="brand-features">
              <div className="feature-item">
                <div className="feature-icon">⚡</div>
                <span>Sạc nhanh & An toàn</span>
              </div>
              <div className="feature-item">
                <div className="feature-icon">🌍</div>
                <span>Thân thiện môi trường</span>
              </div>
              <div className="feature-item">
                <div className="feature-icon">📱</div>
                <span>Quản lý dễ dàng</span>
              </div>
            </div>
          </div>
        </div>

        {/* Right Side - Login Form */}
        <div className="login-form-section">
          <Card className="login-card">
            <div className="login-header">
              <h2 className="login-title">Đăng Nhập</h2>
              <p className="login-subtitle">Chào mừng bạn trở lại!</p>
            </div>

            <SocialLogin />

            <div className="separator">
              <span>Hoặc đăng nhập với email</span>
            </div>

            <form className="login-form" onSubmit={handleSubmit}>
              <div className="form-group">
                <label className="form-label">
                  <Mail size={16} />
                  <span>Email</span>
                </label>
                <InputField
                  name="email"
                  value={formValues.email}
                  onChange={handleChange}
                  type="email"
                  placeholder="Nhập địa chỉ email của bạn"

                />
              </div>

              <div className="form-group">
                <label className="form-label">
                  <Lock size={16} />
                  <span>Mật khẩu</span>
                </label>
                <InputField
                  name="password"
                  value={formValues.password}
                  onChange={handleChange}
                  type="password"
                  placeholder="Nhập mật khẩu của bạn"

                />
              </div>

              <div className="form-footer">
                <Link to="/forgot-password" className="forgot-link">
                  Quên mật khẩu?
                </Link>
              </div>

              {error && (
                <div className="error-message">
                  <span>⚠️</span>
                  <span>{error}</span>
                </div>
              )}

              <button
                className="login-button"
                type="submit"
                disabled={submitting}
              >
                {submitting ? (
                  <>
                    <span className="spinner"></span>
                    <span>Đang đăng nhập...</span>
                  </>
                ) : (
                  <>
                    <Zap size={20} />
                    <span>Đăng nhập</span>
                  </>
                )}
              </button>
            </form>

            <div className="signup-section">
              <p className="signup-text">
                Chưa có tài khoản?
                <Link to="/sign-up" className="signup-link"> Đăng ký ngay!</Link>
              </p>
            </div>
          </Card>
        </div>
      </div>
    </div>
  );
};

export default Login;
