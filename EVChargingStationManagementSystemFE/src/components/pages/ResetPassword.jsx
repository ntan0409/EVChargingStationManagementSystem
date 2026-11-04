import { useState, useEffect } from "react";
import { useNavigate, useSearchParams, Link } from "react-router-dom";
import { Card } from "antd";
import { Zap, Lock, ArrowLeft } from "lucide-react";
import { resetPassword } from "../../API/Auth";
import InputField from "../account/InputField";
import "./ResetPassword.css";

const ResetPassword = () => {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const [userId, setUserId] = useState("");
  const [token, setToken] = useState("");
  const [formData, setFormData] = useState({
    newPassword: "",
    confirmPassword: ""
  });
  const [message, setMessage] = useState("");
  const [loading, setLoading] = useState(false);
  const [isSuccess, setIsSuccess] = useState(false);

  useEffect(() => {
    document.body.className = "reset-body";
    return () => {
      document.body.className = "";
    };
  }, []);

  //  Lấy userId bằng searchParams, token thì giữ nguyên gốc
  useEffect(() => {
    const urlUserId = searchParams.get("userId");

    //  Lấy token gốc từ window.location.search (giữ nguyên ký tự %)
    const rawQuery = window.location.search.substring(1); // bỏ dấu '?'
    const rawParams = Object.fromEntries(rawQuery.split("&").map(p => p.split("=")));
    const rawToken = rawParams.token;

    if (urlUserId && rawToken) {
      setUserId(urlUserId);
      setToken(rawToken);
      console.log(" Token gốc (giữ nguyên %):", rawToken);
    } else {
      setMessage("Liên kết đặt lại mật khẩu không hợp lệ hoặc đã hết hạn.");
      setIsSuccess(false);
    }
  }, [searchParams]);

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
  };

  const validatePassword = (password) => {
    const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;
    return passwordRegex.test(password);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    if (!userId || !token) {
      setMessage("Liên kết đặt lại mật khẩu không hợp lệ hoặc đã hết hạn.");
      setIsSuccess(false);
      return;
    }

    if (!formData.newPassword || !formData.confirmPassword) {
      setMessage("Vui lòng nhập đầy đủ thông tin.");
      setIsSuccess(false);
      return;
    }

    if (!validatePassword(formData.newPassword)) {
      setMessage("Mật khẩu phải có ít nhất 8 ký tự, bao gồm chữ hoa, chữ thường, số và ký tự đặc biệt.");
      setIsSuccess(false);
      return;
    }

    if (formData.newPassword !== formData.confirmPassword) {
      setMessage("Mật khẩu xác nhận không khớp.");
      setIsSuccess(false);
      return;
    }

    try {
      setLoading(true);
      setMessage("");

      await resetPassword(userId, token, formData.newPassword);

      setIsSuccess(true);
      setMessage("Đặt lại mật khẩu thành công! Đang chuyển hướng đến trang đăng nhập...");

      setTimeout(() => {
        navigate("/login");
      }, 2000);
    } catch (error) {
      console.error("Reset password error:", error);
      setIsSuccess(false);

      const data = error.response?.data;
      let serverMsg = "Đã xảy ra lỗi. Vui lòng thử lại.";

      if (data?.errors && Array.isArray(data.errors)) {
        const firstError = data.errors[0];
        if (firstError?.code === "InvalidToken") {
          serverMsg = "Token đặt lại mật khẩu không hợp lệ hoặc đã hết hạn. Vui lòng yêu cầu liên kết mới.";
        } else if (firstError?.description) {
          serverMsg = firstError.description;
        }
      } else if (data?.message) {
        serverMsg = data.message;
      } else if (data?.title) {
        serverMsg = data.title;
      } else if (error?.message) {
        serverMsg = error.message;
      }

      setMessage(serverMsg);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="reset-page-wrapper">
      <div className="reset-page-container">
        {/* Left Side - Branding */}
        <div className="reset-branding">
          <div className="branding-content">
            <div className="brand-icon">
              <Zap size={64} color="white" />
            </div>
            <h1 className="brand-title">Hệ thống quản lý trạm sạc xe điện </h1>
        
            <div className="brand-features">
              <div className="feature-item">
                <div className="feature-icon">🔐</div>
                <span>Bảo mật tuyệt đối</span>
              </div>
              <div className="feature-item">
                <div className="feature-icon">🔑</div>
                <span>Đặt lại dễ dàng</span>
              </div>
              <div className="feature-item">
                <div className="feature-icon">✅</div>
                <span>An toàn & Nhanh chóng</span>
              </div>
            </div>
          </div>
        </div>

        {/* Right Side - Reset Password Form */}
        <div className="reset-form-section">
          <Card className="reset-card">
            <div className="reset-header">
              <h2 className="reset-title">Đặt Lại Mật Khẩu</h2>
              <p className="reset-subtitle">Nhập mật khẩu mới của bạn</p>
            </div>

            <form className="reset-form" onSubmit={handleSubmit}>
              <div className="form-group">
                <label className="form-label">
                  <Lock size={16} />
                  <span>Mật khẩu mới</span>
                </label>
                <InputField
                  name="newPassword"
                  value={formData.newPassword}
                  onChange={handleChange}
                  type="password"
                  placeholder="Nhập mật khẩu mới"
                />
                <p className="password-hint">
                  Mật khẩu phải có ít nhất 8 ký tự, bao gồm chữ hoa, chữ thường, số và ký tự đặc biệt
                </p>
              </div>

              <div className="form-group">
                <label className="form-label">
                  <Lock size={16} />
                  <span>Xác nhận mật khẩu</span>
                </label>
                <InputField
                  name="confirmPassword"
                  value={formData.confirmPassword}
                  onChange={handleChange}
                  type="password"
                  placeholder="Nhập lại mật khẩu mới"
                />
              </div>

              {message && (
                <div className={`message ${isSuccess ? 'success-message' : 'error-message'}`}>
                  <span>{isSuccess ? '✓' : '⚠️'}</span>
                  <div>
                    <span>{message}</span>
                    {!isSuccess && message.includes("Token đặt lại mật khẩu không hợp lệ") && (
                      <div style={{ marginTop: "8px" }}>
                        <Link to="/forgot-password" className="inline-link">
                          Yêu cầu liên kết đặt lại mật khẩu mới
                        </Link>
                      </div>
                    )}
                  </div>
                </div>
              )}

              <button
                className="reset-button"
                type="submit"
                disabled={loading || !userId || !token}
              >
                {loading ? (
                  <>
                    <span className="spinner"></span>
                    <span>Đang xử lý...</span>
                  </>
                ) : (!userId || !token) ? (
                  <>
                    <Lock size={20} />
                    <span>Liên kết không hợp lệ</span>
                  </>
                ) : (
                  <>
                    <Lock size={20} />
                    <span>Đặt lại mật khẩu</span>
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

export default ResetPassword;
