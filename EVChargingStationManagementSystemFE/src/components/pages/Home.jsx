import { useState } from "react";
import "./Home.css";
import { useNavigate, Link } from "react-router-dom";
import Lottie from "lottie-react";
import chargingStationAnim from "../animation/How does an electric vehicle charging station work_.json";
import AntigravityParticles from "../animation/AntigravityParticles";
import {
  Zap,
  MapPin,
  CalendarCheck,
  ShieldCheck,
  Activity,
  ArrowRight,
  Cpu,
  Clock,
  PhoneCall,
  Mail,
  CheckCircle2,
  Sparkles,
  Smartphone
} from "lucide-react";

const Home = () => {
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState("all");

  const handleStartBooking = () => {
    const role = (localStorage.getItem("user_role") || "").toLowerCase();
    if (role === "admin") {
      navigate("/admin/admin-map");
    } else {
      navigate("/order-charging");
    }
  };

  return (
    <div className="modern-home-wrapper">
      {/* HERO SECTION */}
      <section className="hero-section" id="hero">
        {/* Antigravity floating geometric particle physics simulation */}
        <AntigravityParticles
          count={55}
          colors={["#10b981", "#059669", "#0ea5e9", "#34d399", "#8b5cf6"]}
          gravity={-0.03}
          speed={0.65}
        />

        <div className="hero-radial-glow"></div>

        <div className="hero-inner-container">
          <div className="hero-text-block">
            <div className="hero-pill-badge">
              <Sparkles size={14} className="sparkle-icon" />
              <span>Hệ Thống Trạm Sạc Thông Minh 4.0</span>
            </div>

            <h1 className="hero-main-title">
              Năng Lượng Xanh Cho <br />
              <span className="text-gradient-emerald">Hành Trình Bứt Phá</span>
            </h1>

            <p className="hero-description">
              Tìm kiếm, đặt chỗ và sạc nhanh ô tô & xe máy điện tại hàng trăm trạm sạc trên toàn quốc.
              Công nghệ sạc siêu tốc DC tới 250kW, giám sát IoT thời gian thực và thanh toán tự động.
            </p>

            <div className="hero-cta-group">
              <button className="btn-hero-primary" onClick={handleStartBooking}>
                <Zap size={18} />
                <span>Đặt Trạm Sạc Ngay</span>
                <ArrowRight size={16} />
              </button>

              <button
                className="btn-hero-secondary"
                onClick={() => {
                  document.querySelector("#features")?.scrollIntoView({ behavior: "smooth" });
                }}
              >
                <span>Khám Phá Tính Năng</span>
              </button>
            </div>

            {/* Quick Live Stats Pill */}
            <div className="hero-stats-row">
              <div className="stat-pill">
                <span className="stat-number">150+</span>
                <span className="stat-label">Trạm Sạc</span>
              </div>
              <div className="stat-divider"></div>
              <div className="stat-pill">
                <span className="stat-number">800+</span>
                <span className="stat-label">Cổng Sạc DC & AC</span>
              </div>
              <div className="stat-divider"></div>
              <div className="stat-pill">
                <span className="stat-number">99.9%</span>
                <span className="stat-label">Độ Sẵn Sàng</span>
              </div>
            </div>
          </div>

          <div className="hero-visual-block">
            <div className="lottie-glass-frame">
              <div className="ambient-backdrop"></div>
              <Lottie
                animationData={chargingStationAnim}
                loop={true}
                className="charging-lottie"
              />
            </div>
          </div>
        </div>
      </section>

      {/* VALUE BENTO GRID SECTION */}
      <section className="features-bento-section" id="features">
        <div className="section-container">
          <div className="section-header-center">
            <span className="section-tag">TIỆN ÍCH VƯỢT TRỘI</span>
            <h2 className="section-headline">
              Tại Sao Hàng Ngàn Tài Xế Chọn <span className="text-gradient-emerald">EVOne</span>?
            </h2>
            <p className="section-subtext">
              Trải nghiệm nạp năng lượng thông minh, tin cậy và liền mạch từ web đến ứng dụng di động.
            </p>
          </div>

          <div className="bento-grid">
            {/* Bento Card 1: Fast Charging */}
            <div className="bento-card card-featured">
              <div className="card-icon-box emerald">
                <Zap size={26} />
              </div>
              <div className="card-content">
                <h3>Sạc Siêu Nhanh DC Chuẩn Quốc Tế</h3>
                <p>
                  Trang bị trụ sạc siêu tốc CCS2 / CHAdeMO công suất 60kW - 250kW.
                  Chỉ 15 phút sạc cho hơn 200km di chuyển, tiết kiệm tối đa thời gian của bạn.
                </p>
                <div className="bento-tags">
                  <span className="tech-badge">CCS2</span>
                  <span className="tech-badge">GB/T</span>
                  <span className="tech-badge">Công suất tới 250kW</span>
                </div>
              </div>
            </div>

            {/* Bento Card 2: Smart Booking */}
            <div className="bento-card">
              <div className="card-icon-box cyan">
                <CalendarCheck size={26} />
              </div>
              <div className="card-content">
                <h3>Đặt Chỗ Trước Trong Bán Kính 20km</h3>
                <p>
                  Chủ động giữ slot sạc trước giờ đến, không còn nỗi lo chờ đợi hoặc hết cổng sạc vào giờ cao điểm.
                </p>
              </div>
            </div>

            {/* Bento Card 3: IoT Live Monitoring */}
            <div className="bento-card">
              <div className="card-icon-box purple">
                <Activity size={26} />
              </div>
              <div className="card-content">
                <h3>Giám Sát IoT Thời Gian Thực</h3>
                <p>
                  Theo dõi trực quan công suất sạc kW, số kWh đã nạp, nhiệt độ pin và chi phí ước tính ngay trên màn hình.
                </p>
              </div>
            </div>

            {/* Bento Card 4: Automated Payment */}
            <div className="bento-card">
              <div className="card-icon-box green">
                <ShieldCheck size={26} />
              </div>
              <div className="card-content">
                <h3>Thanh Toán Tự Động Minh Bạch</h3>
                <p>
                  Hỗ trợ SePay chuyển khoản tự động, VNPay QR và ví số dư tài xế với xuất hóa đơn điện tử VAT tức thì.
                </p>
              </div>
            </div>

            {/* Bento Card 5: Multi-vehicle support */}
            <div className="bento-card">
              <div className="card-icon-box blue">
                <Cpu size={26} />
              </div>
              <div className="card-content">
                <h3>Hỗ Trợ Đa Phương Tiện EV</h3>
                <p>
                  Tương thích hoàn hảo với các dòng ô tô điện VinFast (VF3, VF5, VF7, VF8, VF9, e34) và xe máy điện thông dụng.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* QUICK WORKFLOW STEPS */}
      <section className="workflow-section">
        <div className="section-container">
          <div className="section-header-center">
            <span className="section-tag">QUY TRÌNH ĐƠN GIẢN</span>
            <h2 className="section-headline">3 Bước Dễ Dàng Để Sạc Xe</h2>
          </div>

          <div className="workflow-steps-grid">
            <div className="workflow-step-card">
              <div className="step-number-badge">01</div>
              <h4>Tìm & Chọn Trạm Sạc</h4>
              <p>Tra cứu trạm gần nhất trong bán kính 20km, kiểm tra số slot trống của ô tô và xe máy theo thời gian thực.</p>
            </div>

            <div className="workflow-step-card">
              <div className="step-number-badge">02</div>
              <h4>Cắm Sạc & Quét Mã QR</h4>
              <p>Kết nối cổng sạc vào xe, quét mã QR trên trụ sạc để kích hoạt phiên sạc an toàn tức thì.</p>
            </div>

            <div className="workflow-step-card">
              <div className="step-number-badge">03</div>
              <h4>Theo Dõi & Thanh Toán</h4>
              <p>Quan sát tiến độ phần trăm pin và số tiền qua ứng dụng. Kết thúc phiên sạc và thanh toán tự động qua SePay/VNPay.</p>
            </div>
          </div>
        </div>
      </section>

      {/* CTA BANNER */}
      <section className="cta-banner-section">
        <div className="section-container">
          <div className="cta-banner-card">
            <div className="cta-content">
              <h2>Sẵn Sàng Trải Nghiệm Mạng Lưới Sạc EVOne?</h2>
              <p>Đăng ký tài khoản miễn phí để nhận ngay ưu đãi sạc và đặt chỗ ưu tiên tại mọi trạm sạc toàn quốc.</p>
              <div className="cta-buttons">
                <button className="btn-cta-primary" onClick={handleStartBooking}>
                  <span>Bắt Đầu Ngay</span>
                  <ArrowRight size={18} />
                </button>
                <Link to="/sign-up" className="btn-cta-secondary">
                  <span>Tạo Tài Khoản Mới</span>
                </Link>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* FOOTER */}
      <footer className="modern-footer">
        <div className="section-container footer-grid">
          <div className="footer-brand-col">
            <div className="brand-logo footer-logo">
              <div className="brand-icon-box">
                <Zap className="brand-bolt" size={20} />
              </div>
              <div className="brand-text-group">
                <div className="brand-name">EV<span>One</span></div>
                <div className="brand-badge"><span>Smart EV Network</span></div>
              </div>
            </div>
            <p className="footer-about-text">
              Hệ thống trạm sạc xe điện thông minh hàng đầu Việt Nam. Nền tảng kết nối tài xế, quản lý năng lượng và trạm sạc 24/7.
            </p>
          </div>

          <div className="footer-links-col">
            <h5>Dịch Vụ</h5>
            <Link to="/order-charging">Đặt Trạm Sạc</Link>
            <Link to="/station-list">Mô Phỏng Sạc</Link>
            <Link to="/profile-page">Quản Lý Xe Điện</Link>
          </div>

          <div className="footer-links-col">
            <h5>Hệ Thống</h5>
            <Link to="/login">Cổng Đăng Nhập</Link>
            <Link to="/sign-up">Đăng Ký Tài Xế</Link>
            <Link to="/admin">Trang Quản Trị</Link>
            <Link to="/staff">Trang Nhân Viên</Link>
          </div>

          <div className="footer-contact-col">
            <h5>Liên Hệ Hỗ Trợ</h5>
            <p className="footer-contact-item">
              <PhoneCall size={16} />
              <span>Hotline 24/7: 1900 8888</span>
            </p>
            <p className="footer-contact-item">
              <Mail size={16} />
              <span>Email: support@evone.vn</span>
            </p>
            <p className="footer-contact-item">
              <MapPin size={16} />
              <span>Hà Nội & TP. Hồ Chí Minh, Việt Nam</span>
            </p>
          </div>
        </div>

        <div className="footer-bottom-bar">
          <p>© {new Date().getFullYear()} EVOne Charging System. All rights reserved.</p>
        </div>
      </footer>
    </div>
  );
};

export default Home;
