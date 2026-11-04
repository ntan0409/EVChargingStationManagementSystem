import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { Card } from "antd";
import { Zap } from "lucide-react";
import { register as registerApi } from "../../API/Auth";
import InputField from "../account/InputField";
import SocialLogin from "../account/SocialLogin";
import "./Signup.css";

const Signup = () => {
  const navigate = useNavigate();
  const [formValues, setFormValues] = useState({
    name: "",
    email: "",
    phone: "",
    password: "",
    confirmPassword: "",
  });
  const [errors, setErrors] = useState({});
  const [submitting, setSubmitting] = useState(false);
  const [success, setSuccess] = useState("");

  useEffect(() => {
    document.body.className = "signup-body";
    return () => (document.body.className = "");
  }, []);

  const passwordHint =
    "Mật khẩu: ít nhất 8 ký tự, có chữ hoa, chữ thường, số và ký tự đặc biệt.";

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormValues((prev) => ({ ...prev, [name]: value }));

    const newErrors = { ...errors };

    if (name === "email") {
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(value)) newErrors.email = "Email không hợp lệ";
      else delete newErrors.email;
    }

    if (name === "password") {
      const passRegex =
        /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*#?&]).{8,}$/;
      if (!passRegex.test(value)) newErrors.password = passwordHint;
      else delete newErrors.password;
    }

    if (name === "confirmPassword") {
      if (value !== formValues.password)
        newErrors.confirmPassword = "Mật khẩu xác nhận không khớp";
      else delete newErrors.confirmPassword;
    }

    setErrors(newErrors);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const requiredFields = ["name", "email", "password", "confirmPassword"];
    let formErrors = {};
    requiredFields.forEach((f) => {
      if (!formValues[f].trim()) formErrors[f] = "Trường này bắt buộc";
    });
    if (Object.keys(errors).length > 0 || Object.keys(formErrors).length > 0) {
      setErrors({ ...formErrors, ...errors });
      return;
    }

    try {
      setSubmitting(true);
      await registerApi(
        formValues.email,
        formValues.password,
        formValues.name,
        formValues.phone
      );
      setSuccess("Đăng ký thành công! Chuyển tới trang đăng nhập...");
      setErrors({});
      setTimeout(() => navigate("/login"), 2000);
    } catch (err) {
      let apiError = err.message || "";
      let translatedError = "";

      if (apiError.includes("Số điện thoại của bạn đã được đăng ký")) {
        translatedError = "Số điện thoại không hợp lệ hoặc không thể sử dụng.";
      } else if (apiError.includes("Save data fail")) {
        translatedError = "Email không hợp lệ hoặc không thể sử dụng.";
      } else {
        translatedError = apiError; // lỗi khác giữ nguyên
      }

      setErrors({ api: translatedError });
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="signup-page-wrapper">
      <div className="signup-page-container">
        {/* Left Branding */}
        <div className="signup-branding">
          <div className="branding-content">
            <div className="brand-icon">
              <Zap size={64} color="white" />
            </div>
            <h1 className="brand-title">Hệ thống quản lý trạm sạc xe điện </h1>
          </div>
        </div>

        {/* Right Form */}
        <div className="signup-form-section">
          <Card className="signup-card">
            <div className="signup-header">
              <h2 className="signup-title">Tạo Tài Khoản</h2>
              <p className="signup-subtitle">Điền đầy đủ thông tin để đăng ký</p>
            </div>

            <SocialLogin />

            <div className="separator">
              <span>Hoặc đăng ký với email</span>
            </div>

            <form className="signup-form" onSubmit={handleSubmit}>
              <div className="form-group">
                <InputField
                  name="name"
                  value={formValues.name}
                  onChange={handleChange}
                  type="text"
                  placeholder="Họ và tên"
                />
                {errors.name && <div className="error-message">{errors.name}</div>}
              </div>

              <div className="form-group">
                <InputField
                  name="email"
                  value={formValues.email}
                  onChange={handleChange}
                  type="email"
                  placeholder="Email"
                />
                {errors.email && <div className="error-message">{errors.email}</div>}
              </div>

              <div className="form-group">
                <InputField
                  name="phone"
                  value={formValues.phone}
                  onChange={handleChange}
                  type="tel"
                  placeholder="Số điện thoại (bắt buộc)"
                />
              </div>

              <div className="form-group">
                <InputField
                  name="password"
                  value={formValues.password}
                  onChange={handleChange}
                  type="password"
                  placeholder="Mật khẩu"
                />
                {errors.password && (
                  <div className="input-hint">{errors.password}</div>
                )}
              </div>

              <div className="form-group">
                <InputField
                  name="confirmPassword"
                  value={formValues.confirmPassword}
                  onChange={handleChange}
                  type="password"
                  placeholder="Xác nhận mật khẩu"
                />
                {errors.confirmPassword && (
                  <div className="error-message">{errors.confirmPassword}</div>
                )}
              </div>

              {errors.api && <div className="error-message">{errors.api}</div>}
              {success && (
                <div className="success-message">{success}</div>
              )}

              <button className="signup-button" type="submit" disabled={submitting}>
                {submitting ? "Đang đăng ký..." : "Đăng ký"}
              </button>
            </form>

            <div className="signup-section">
              <p className="signup-text">
                Bạn đã có tài khoản? <Link to="/login">Đăng nhập</Link>
              </p>
            </div>
          </Card>
        </div>
      </div>
    </div>
  );
};

export default Signup;
