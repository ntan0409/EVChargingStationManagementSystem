import { Outlet, Link, useLocation } from "react-router-dom";
import "./Layout.css";
import { getAuthStatus } from "../../API/Auth";
import { useEffect, useState } from "react";
import ProfileMenu from "../profile/ProfileMenu";
import { jwtDecode } from "jwt-decode";
import { Zap, Menu, X, Shield, MapPin, Sparkles, LogIn } from "lucide-react";

const Layout = () => {
  const location = useLocation();
  const [auth, setAuth] = useState(getAuthStatus());
  const [role, setRole] = useState(localStorage.getItem("user_role") || null);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 20);
    };
    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  useEffect(() => {
    const handleAuthChanged = () => {
      const newAuth = getAuthStatus();
      setAuth(newAuth);

      const token = localStorage.getItem("token");
      if (token) {
        try {
          const decoded = jwtDecode(token);
          if (decoded?.role) {
            localStorage.setItem("user_role", decoded.role);
            setRole(decoded.role);
          }
        } catch (err) {
          console.error("Lỗi giải mã token:", err);
          localStorage.removeItem("user_role");
          setRole(null);
        }
      } else {
        localStorage.removeItem("user_role");
        setRole(null);
      }
    };

    window.addEventListener("auth-changed", handleAuthChanged);
    handleAuthChanged();
    return () => window.removeEventListener("auth-changed", handleAuthChanged);
  }, [location.pathname]);

  const { isAuthenticated } = auth;

  const isActive = (path) => {
    if (path === "/" && location.pathname === "/") return true;
    if (path !== "/" && location.pathname.startsWith(path)) return true;
    return false;
  };

  return (
    <div className="app-shell-wrapper">
      {/* Floating Modern Glass Header */}
      <header className={`ev-navbar ${scrolled ? "scrolled" : ""}`}>
        <div className="nav-container">
          {/* Brand Logo */}
          <Link to="/" className="brand-logo" onClick={() => setMobileMenuOpen(false)}>
            <div className="brand-icon-box">
              <Zap className="brand-bolt" size={20} />
            </div>
            <div className="brand-text-group">
              <div className="brand-name">
                EV<span>One</span>
              </div>
              <div className="brand-badge">
                <span className="live-dot"></span>
                <span>Smart Network</span>
              </div>
            </div>
          </Link>

          {/* Desktop Navigation Links */}
          <nav className="desktop-nav">
            <Link to="/" className={`nav-link ${isActive("/") ? "active" : ""}`}>
              Trang Chủ
            </Link>

            {role !== "Admin" && role !== "Staff" && (
              <Link
                to="/order-charging"
                className={`nav-link ${isActive("/order-charging") ? "active" : ""}`}
              >
                <MapPin size={16} />
                <span>Đặt Trạm Sạc</span>
              </Link>
            )}

            {role === "EVDriver" && (
              <Link
                to="/profile-page"
                className={`nav-link ${isActive("/profile-page") ? "active" : ""}`}
              >
                Hồ Sơ & Xe
              </Link>
            )}

            {role === "Admin" && (
              <Link
                to="/admin"
                className={`nav-link admin-pill ${isActive("/admin") ? "active" : ""}`}
              >
                <Shield size={16} />
                <span>Quản Trị Hệ Thống</span>
              </Link>
            )}

            {role === "Staff" && (
              <Link
                to="/staff"
                className={`nav-link staff-pill ${isActive("/staff") ? "active" : ""}`}
              >
                <Sparkles size={16} />
                <span>Trang Nhân Viên</span>
              </Link>
            )}
          </nav>

          {/* Right Action Bar */}
          <div className="nav-actions">
            {!isAuthenticated ? (
              <div className="auth-buttons">
                <Link to="/login" className="btn-login">
                  <LogIn size={16} />
                  <span>Đăng Nhập</span>
                </Link>
                <Link to="/sign-up" className="btn-signup">
                  Đăng Ký
                </Link>
              </div>
            ) : (
              <div className="user-profile-slot">
                <ProfileMenu />
              </div>
            )}

            {/* Mobile Hamburger Toggle */}
            <button
              className="mobile-toggle"
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              aria-label="Toggle Navigation Menu"
            >
              {mobileMenuOpen ? <X size={22} /> : <Menu size={22} />}
            </button>
          </div>
        </div>

        {/* Mobile Dropdown Menu */}
        {mobileMenuOpen && (
          <div className="mobile-drawer">
            <Link
              to="/"
              className={`mobile-link ${isActive("/") ? "active" : ""}`}
              onClick={() => setMobileMenuOpen(false)}
            >
              Trang Chủ
            </Link>

            {role !== "Admin" && role !== "Staff" && (
              <Link
                to="/order-charging"
                className={`mobile-link ${isActive("/order-charging") ? "active" : ""}`}
                onClick={() => setMobileMenuOpen(false)}
              >
                Đặt Trạm Sạc
              </Link>
            )}

            {role === "EVDriver" && (
              <Link
                to="/profile-page"
                className={`mobile-link ${isActive("/profile-page") ? "active" : ""}`}
                onClick={() => setMobileMenuOpen(false)}
              >
                Hồ Sơ & Xe Của Tôi
              </Link>
            )}

            {role === "Admin" && (
              <Link
                to="/admin"
                className="mobile-link"
                onClick={() => setMobileMenuOpen(false)}
              >
                Quản Trị Hệ Thống
              </Link>
            )}

            {role === "Staff" && (
              <Link
                to="/staff"
                className="mobile-link"
                onClick={() => setMobileMenuOpen(false)}
              >
                Trang Nhân Viên
              </Link>
            )}

            {!isAuthenticated && (
              <div className="mobile-auth-block">
                <Link
                  to="/login"
                  className="btn-login w-full"
                  onClick={() => setMobileMenuOpen(false)}
                >
                  Đăng Nhập
                </Link>
                <Link
                  to="/sign-up"
                  className="btn-signup w-full"
                  onClick={() => setMobileMenuOpen(false)}
                >
                  Đăng Ký Tài Khoản
                </Link>
              </div>
            )}
          </div>
        )}
      </header>

      {/* Main Content Area */}
      <main className="ev-main-content">
        <Outlet />
      </main>
    </div>
  );
};

export default Layout;
