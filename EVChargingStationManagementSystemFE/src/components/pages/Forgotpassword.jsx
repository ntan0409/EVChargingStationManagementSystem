import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { Card } from "antd";
import { Zap, Mail, ArrowLeft } from "lucide-react";
import { forgotPassword } from "../../API/Auth";
import InputField from "../account/InputField";
import "./Forgotpassword.css";

const ForgotPassword = () => {
  const [email, setEmail] = useState("");
  const [message, setMessage] = useState("");
  const [loading, setLoading] = useState(false);
  const [isSuccess, setIsSuccess] = useState(false);

  useEffect(() => {
    document.body.className = "forgot-body";
    return () => {
      document.body.className = "";
    };
  }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!email) {
      setMessage("Vui lòng nhập email.");
      setIsSuccess(false);
      return;
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      setMessage("Email không đúng định dạng.");
      setIsSuccess(false);
      return;
    }

    try {
      setLoading(true);
      setMessage("");
      const response = await forgotPassword(email);
      setIsSuccess(true);
      setMessage(response?.message || "Yêu cầu đặt lại mật khẩu đã được gửi. Vui lòng kiểm tra email.");
    } catch (error) {
      console.error(error);
      setIsSuccess(false);
      const data = error.response?.data;
      const serverMsg =
        data?.errors?.Email?.[0] ||
        data?.errors?.email?.[0] ||
        data?.message ||
        data?.title ||
        "Đã xảy ra lỗi. Vui lòng thử lại.";
      setMessage(serverMsg);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="forgot-page-wrapper">
      <div className="forgot-page-container">
        {/* Left Side - Branding */}
        <div className="forgot-branding">
          <div className="branding-content">
            <div className="brand-icon">
              <Zap size={64} color="white" />
            </div>
            <h1 className="brand-title">Hệ thống quản lý trạm sạc xe điện</h1>
            
            <div className="brand-features">
              <div className="feature-item">
                <div className="feature-icon">🔒</div>
                <span>Bảo mật cao</span>
              </div>
              <div className="feature-item">
                <div className="feature-icon">📧</div>
                <span>Khôi phục nhanh chóng</span>
              </div>
              <div className="feature-item">
                <div className="feature-icon">✨</div>
                <span>Hỗ trợ 24/7</span>
              </div>
            </div>
          </div>
        </div>

        {/* Right Side - Forgot Password Form */}
        <div className="forgot-form-section">
          <Card className="forgot-card">
            <div className="forgot-header">
              <h2 className="forgot-title">Quên Mật Khẩu</h2>
              <p className="forgot-subtitle">Nhập email để nhận liên kết đặt lại mật khẩu</p>
            </div>

            <form className="forgot-form" onSubmit={handleSubmit}>
              <div className="form-group">
                <label className="form-label">
                  <Mail size={16} />
                  <span>Email</span>
                </label>
                <InputField
                  name="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  type="email"
                  placeholder="Nhập địa chỉ email của bạn"
                />
              </div>

              {message && (
                <div className={`message ${isSuccess ? 'success-message' : 'error-message'}`}>
                  <span>{isSuccess ? '✓' : '⚠️'}</span>
                  <span>{message}</span>
                </div>
              )}

              <button
                className="forgot-button"
                type="submit"
                disabled={loading}
              >
                {loading ? (
                  <>
                    <span className="spinner"></span>
                    <span>Đang gửi...</span>
                  </>
                ) : (
                  <>
                    <Mail size={20} />
                    <span>Gửi liên kết đặt lại</span>
                  </>
                )}
              </button>
            </form>

            <div className="back-section">
              <Link to="/login" className="back-link">
                <ArrowLeft size={16} />
                <span>Quay lại đăng nhập</span>
              </Link>
            </div>
          </Card>
        </div>
      </div>
    </div>
  );
};

export default ForgotPassword;
