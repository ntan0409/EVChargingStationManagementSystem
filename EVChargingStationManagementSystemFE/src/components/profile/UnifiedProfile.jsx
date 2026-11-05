import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import {
  User,
  Mail,
  Phone,
  MapPin,
  Car,
  Lock,
  Camera,
  Edit3,
  CheckCircle2,
  Calendar,
  Receipt,
  HelpCircle,
  Star,
  ArrowRight,
  Zap,
  ShieldCheck,
  Sparkles,
  X,
  Plus
} from "lucide-react";
import { updateEVDriver, getEVDriverProfile, deleteEVDriverVehicalid } from "../../API/EVDriver";
import { getVehicleModels } from "../../API/Admin";
import { changePassword } from "../../API/Auth";
import { MyBooking } from "../../API/Booking";
import { ToastContainer, toast } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";
import "./UnifiedProfile.css";

const defaultAvatar = "https://cdn-icons-png.flaticon.com/512/847/847969.png";

const UnifiedProfile = () => {
  const navigate = useNavigate();

  // State
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [showPopup, setShowPopup] = useState(""); // "" | "avatar" | "vehicle" | "editProfile" | "password"
  const [searchTerm, setSearchTerm] = useState("");

  const [formData, setFormData] = useState({
    name: "",
    email: "",
    phone: "",
    role: "",
    address: "",
    avatar: "",
    driverId: "",
  });

  const [passwordData, setPasswordData] = useState({
    oldPassword: "",
    newPassword: "",
    confirmPassword: "",
  });

  const [vehicleModels, setVehicleModels] = useState([]);
  const [selectedVehicles, setSelectedVehicles] = useState([]);
  const [recentOrders, setRecentOrders] = useState([]);
  const [totalBookingCount, setTotalBookingCount] = useState(0);

  // Fetch all profile and booking data
  useEffect(() => {
    const fetchAllData = async () => {
      try {
        const [profileRes, modelsRes, bookingRes] = await Promise.all([
          getEVDriverProfile().catch(() => null),
          getVehicleModels().catch(() => ({ data: [] })),
          MyBooking().catch(() => ({ data: [] }))
        ]);

        // Process Profile
        const driver = profileRes?.data?.data || profileRes?.data;
        if (driver) {
          const userData = {
            name: driver.name || "Tài xế EVOne",
            email: driver.email || "",
            phone: driver.phoneNumber || "",
            role: driver.role || "EVDriver",
            avatar: driver.profilePictureUrl || "",
            address: driver.address || "",
            driverId: driver.id || "",
            vehicleModelIds: driver.vehicleModelIds || [],
            status: driver.status || "Active"
          };
          setUser(userData);
          setFormData(userData);
          setSelectedVehicles([...(userData.vehicleModelIds || [])]);
        } else {
          setUser({
            name: "Tài xế EVOne",
            email: "driver@evone.vn",
            role: "EVDriver",
            avatar: "",
            status: "Active"
          });
        }

        // Process Vehicle Models
        if (modelsRes?.data) {
          setVehicleModels(Array.isArray(modelsRes.data) ? modelsRes.data : []);
        }

        // Process Bookings
        if (bookingRes?.data && Array.isArray(bookingRes.data)) {
          const validBookings = bookingRes.data
            .filter((o) => o.status !== "Cancelled")
            .sort((a, b) => new Date(b.startTime) - new Date(a.startTime));
          setRecentOrders(validBookings);
          setTotalBookingCount(validBookings.length);
        }
      } catch (err) {
        console.error("Lỗi khi tải dữ liệu trang cá nhân:", err);
      } finally {
        setLoading(false);
      }
    };

    fetchAllData();
  }, []);

  // Handlers
  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  const handleOpenEdit = () => {
    if (user) {
      setFormData({
        name: user.name || "",
        email: user.email || "",
        phone: user.phone || "",
        address: user.address || "",
        avatar: user.avatar || "",
        driverId: user.driverId || "",
        role: user.role || "EVDriver",
      });
    }
    setShowPopup("editProfile");
  };

  const handleSaveProfile = async () => {
    try {
      if (!user?.driverId) {
        toast.info("Đã lưu thông tin hồ sơ!");
        setUser({ ...user, ...formData, vehicleModelIds: selectedVehicles });
        setShowPopup("");
        return;
      }

      const res = await updateEVDriver(
        user.driverId,
        formData.name,
        formData.phone,
        formData.address || "",
        formData.avatar || "",
        selectedVehicles
      );

      if (res?.status === 200 || res?.data?.success) {
        setUser({
          ...formData,
          driverId: user.driverId,
          vehicleModelIds: selectedVehicles,
        });
        setShowPopup("");
        toast.success("Cập nhật thông tin thành công!");
      } else {
        toast.error(res?.data?.message || "Lỗi cập nhật!");
      }
    } catch (error) {
      console.error("Lỗi khi cập nhật:", error);
      toast.error("Cập nhật thất bại, vui lòng thử lại!");
    }
  };

  const handlePasswordChange = async () => {
    const { oldPassword, newPassword, confirmPassword } = passwordData;
    if (!oldPassword || !newPassword || !confirmPassword) {
      toast.error("Vui lòng nhập đầy đủ thông tin!");
      return;
    }
    if (newPassword !== confirmPassword) {
      toast.error("Mật khẩu mới và xác nhận không khớp!");
      return;
    }

    try {
      await changePassword(oldPassword, newPassword, confirmPassword);
      toast.success("Đổi mật khẩu thành công!");
      setPasswordData({ oldPassword: "", newPassword: "", confirmPassword: "" });
      setShowPopup("");
    } catch (err) {
      console.error("Lỗi đổi mật khẩu:", err);
      toast.error(err.response?.data?.message || "Mật khẩu cũ không chính xác");
    }
  };

  const handleDeleteVehicle = async (vehicleModelId) => {
    if (!vehicleModelId) return;
    if (window.confirm("Bạn có chắc muốn bỏ chọn dòng xe này?")) {
      const updated = selectedVehicles.filter((id) => id !== vehicleModelId);
      setSelectedVehicles(updated);
      try {
        await deleteEVDriverVehicalid(vehicleModelId);
        toast.success("Đã xóa xe khỏi danh sách!");
      } catch (e) {
        // Ignored or local fallback
      }
    }
  };

  const normalize = (str = "") =>
    str.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();

  const formatDateTime = (isoString) => {
    if (!isoString) return "-";
    const date = new Date(isoString);
    return date.toLocaleString("vi-VN", {
      hour: "2-digit",
      minute: "2-digit",
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
    });
  };

  const quickActions = [
    { title: "Tìm trạm sạc", icon: <MapPin size={22} />, path: "/order-charging", type: "map" },
    { title: "Lịch sử đặt lịch", icon: <Calendar size={22} />, path: "/orders", type: "calendar" },
    { title: "Lịch sử thanh toán", icon: <Receipt size={22} />, path: "/payment-history", type: "receipt" },
    { title: "Garage xe điện", icon: <Car size={22} />, path: "/car", type: "car" },
    { title: "Thông tin tài khoản", icon: <User size={22} />, onClick: handleOpenEdit, type: "user" },
    { title: "Báo cáo & Hỗ trợ", icon: <HelpCircle size={22} />, path: "/user-report", type: "support" },
  ];

  const latestBooking = recentOrders.length > 0 ? recentOrders[0] : null;

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <div className="text-center font-semibold text-slate-500">Đang tải hồ sơ...</div>
      </div>
    );
  }

  return (
    <div className="unified-profile-page">
      {/* ========================================================
          SECTION 1: HERO COVER & DRIVER PROFILE BANNER
      ======================================================== */}
      <div className="profile-hero-card">
        <div className="profile-hero-cover" />
        
        <div className="profile-hero-body">
          <div className="profile-avatar-wrap">
            <div className="profile-avatar-container">
              <img
                src={user?.avatar || defaultAvatar}
                alt="Avatar"
                className="profile-avatar-img"
              />
              <button
                className="profile-avatar-camera-btn"
                onClick={() => setShowPopup("avatar")}
                title="Đổi ảnh đại diện"
              >
                <Camera size={16} />
              </button>
            </div>

            <div className="profile-driver-meta">
              <h1>{user?.name || "Tài xế EVOne"}</h1>
              <div className="profile-driver-sub">
                <span className="profile-badge-role">Tài Xế EVOne</span>
                <span>•</span>
                <span>{user?.email || "Chưa cập nhật email"}</span>
                <span>•</span>
                <span className="inline-flex items-center gap-1 text-emerald-600 font-semibold">
                  <CheckCircle2 size={14} /> Đã kích hoạt
                </span>
              </div>
            </div>
          </div>

          {/* Action buttons placed side by side at top */}
          <div className="profile-hero-actions">
            <button className="btn-pill-edit" onClick={handleOpenEdit}>
              <Edit3 size={15} /> Chỉnh sửa hồ sơ
            </button>
            <button className="btn-pill-password" onClick={() => setShowPopup("password")}>
              <Lock size={15} /> Đổi mật khẩu
            </button>
          </div>
        </div>

        {/* Quick Stats Strip */}
        <div className="profile-stats-strip">
          <div className="profile-stat-box">
            <div className="profile-stat-icon emerald">
              <Zap size={22} />
            </div>
            <div>
              <div className="profile-stat-val">{totalBookingCount} lượt</div>
              <div className="profile-stat-lbl">Lịch Sử Sạc Điện</div>
            </div>
          </div>

          <div className="profile-stat-box">
            <div className="profile-stat-icon blue">
              <Car size={22} />
            </div>
            <div>
              <div className="profile-stat-val">{selectedVehicles.length} xe</div>
              <div className="profile-stat-lbl">Phương Tiện Đã Ghép</div>
            </div>
          </div>

          <div className="profile-stat-box">
            <div className="profile-stat-icon amber">
              <Star size={22} />
            </div>
            <div>
              <div className="profile-stat-val">4.9 / 5.0</div>
              <div className="profile-stat-lbl">Đánh Giá Hội Viên</div>
            </div>
          </div>

          <div className="profile-stat-box">
            <div className="profile-stat-icon purple">
              <ShieldCheck size={22} />
            </div>
            <div>
              <div className="profile-stat-val">Bảo Mật</div>
              <div className="profile-stat-lbl">Tài Khoản Đã Xác Thực</div>
            </div>
          </div>
        </div>
      </div>

      {/* ========================================================
          SECTION 2: TIỆN ÍCH & THAO TÁC NHANH
      ======================================================== */}
      <div className="profile-section-card">
        <div className="section-head">
          <h2>
            <Sparkles size={18} className="text-emerald-500" />
            Tiện Ích & Thao Tác Nhanh
          </h2>
        </div>

        <div className="actions-bento-grid">
          {quickActions.map((action, i) => (
            <div
              key={i}
              className={`action-tile ${action.type}`}
              onClick={() => {
                if (action.onClick) action.onClick();
                else if (action.path) navigate(action.path);
              }}
            >
              <div className="icon-circle">{action.icon}</div>
              <p>{action.title}</p>
            </div>
          ))}
        </div>
      </div>

      {/* ========================================================
          SECTION 3: LỊCH ĐẶT SẠC GẦN NHẤT (NẾU CÓ)
      ======================================================== */}
      {latestBooking && (
        <div className="booking-banner-card">
          <div className="booking-banner-left">
            <div className="booking-pulse-badge">
              <Zap size={24} />
            </div>
            <div>
              <div className="booking-station-name">
                Lịch sạc tại {latestBooking.stationName || "Trạm sạc trung tâm"}
              </div>
              <div className="booking-meta-row">
                <span>Thời gian: {formatDateTime(latestBooking.startTime)}</span>
                {latestBooking.checkInCode && (
                  <span className="booking-checkin-chip">
                    CHECK-IN: {latestBooking.checkInCode}
                  </span>
                )}
              </div>
            </div>
          </div>

          <button
            className="btn-booking-details"
            onClick={() => navigate("/orders")}
          >
            Xem lịch sử đặt <ArrowRight size={15} />
          </button>
        </div>
      )}

      {/* ========================================================
          SECTION 4: BANNER HỖ TRỢ & KHẢO SÁT 24/7
      ======================================================== */}
      <div className="profile-support-banner">
        <div>
          <h3>Bạn Cần Trợ Giúp Kỹ Thuật Hoặc Khiếu Nại?</h3>
          <p>Bộ phận hỗ trợ trạm sạc EVOne luôn túc trực hỗ trợ tài xế 24/7</p>
        </div>

        <div className="support-banner-btns">
          <button
            className="support-banner-btn primary"
            onClick={() => navigate("/user-report")}
          >
            Gửi Yêu Cầu Hỗ Trợ
          </button>
          <button
            className="support-banner-btn"
            onClick={() => navigate("/rating-page")}
          >
            Đánh Giá Dịch Vụ
          </button>
        </div>
      </div>

      {/* ========================================================
          POPUPS / MODALS
      ======================================================== */}
      {/* 1. Modal Thông Tin Cá Nhân & Tài Khoản (Được gọi từ nút "Chỉnh sửa hồ sơ" ở đầu trang) */}
      {showPopup === "editProfile" && (
        <div className="unified-popup-overlay" onClick={() => setShowPopup("")}>
          <div className="unified-popup-box account-modal-box" onClick={(e) => e.stopPropagation()}>
            <div className="popup-header-row">
              <h3 className="flex items-center gap-2">
                <User size={20} className="text-emerald-600" />
                Thông Tin Cá Nhân & Tài Khoản
              </h3>
              <button className="popup-close-x" onClick={() => setShowPopup("")}>
                <X size={18} />
              </button>
            </div>

            <div className="profile-details-grid modal-edit-grid">
              {/* Họ và tên */}
              <div className="detail-row modal-input-row">
                <span className="detail-label"><User size={16} /> Họ và tên</span>
                <input
                  type="text"
                  name="name"
                  className="modal-inline-input"
                  value={formData.name}
                  onChange={handleInputChange}
                  placeholder="Nhập họ và tên"
                />
              </div>

              {/* Email (readonly) */}
              <div className="detail-row modal-input-row">
                <span className="detail-label"><Mail size={16} /> Địa chỉ Email</span>
                <input
                  type="email"
                  name="email"
                  className="modal-inline-input readonly"
                  value={formData.email}
                  readOnly
                />
              </div>

              {/* Số điện thoại */}
              <div className="detail-row modal-input-row">
                <span className="detail-label"><Phone size={16} /> Số điện thoại</span>
                <input
                  type="text"
                  name="phone"
                  className="modal-inline-input"
                  value={formData.phone}
                  onChange={handleInputChange}
                  placeholder="Nhập số điện thoại"
                />
              </div>

              {/* Địa chỉ */}
              <div className="detail-row modal-input-row">
                <span className="detail-label"><MapPin size={16} /> Địa chỉ</span>
                <input
                  type="text"
                  name="address"
                  className="modal-inline-input"
                  value={formData.address}
                  onChange={handleInputChange}
                  placeholder="Chưa cung cấp địa chỉ"
                />
              </div>

              {/* Dòng xe sở hữu */}
              <div className="detail-row modal-input-row">
                <span className="detail-label"><Car size={16} /> Dòng xe sở hữu</span>
                <div className="vehicle-chips-wrap">
                  {selectedVehicles.length === 0 ? (
                    <span className="text-slate-400 text-sm">Chưa chọn dòng xe</span>
                  ) : (
                    selectedVehicles.map((id) => {
                      const model = vehicleModels.find((v) => v.id === id);
                      return (
                        <span key={id} className="vehicle-chip">
                          {model?.modelName || id}
                          <button
                            className="vehicle-chip-remove"
                            onClick={() => handleDeleteVehicle(id)}
                            title="Xóa xe"
                          >
                            ✕
                          </button>
                        </span>
                      );
                    })
                  )}
                  <button
                    className="btn-manage-vehicles"
                    onClick={() => setShowPopup("vehicle")}
                  >
                    <Plus size={12} className="inline mr-1" /> Thêm xe
                  </button>
                </div>
              </div>
            </div>

            <div className="modal-actions-footer">
              <button
                className="btn-submit-save"
                onClick={handleSaveProfile}
              >
                Lưu Thay Đổi
              </button>
              <button
                className="btn-submit-cancel"
                onClick={() => setShowPopup("")}
              >
                Đóng
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 2. Modal Đổi Mật Khẩu (Kế bên nút Chỉnh sửa hồ sơ) */}
      {showPopup === "password" && (
        <div className="unified-popup-overlay" onClick={() => setShowPopup("")}>
          <div className="unified-popup-box" onClick={(e) => e.stopPropagation()}>
            <div className="popup-header-row">
              <h3 className="flex items-center gap-2">
                <Lock size={20} className="text-emerald-600" />
                Đổi Mật Khẩu Tài Khoản
              </h3>
              <button className="popup-close-x" onClick={() => setShowPopup("")}>
                <X size={18} />
              </button>
            </div>

            <div className="unified-form">
              <div className="form-group-field">
                <label>Mật khẩu hiện tại</label>
                <input
                  type="password"
                  placeholder="Nhập mật khẩu hiện tại"
                  value={passwordData.oldPassword}
                  onChange={(e) =>
                    setPasswordData({ ...passwordData, oldPassword: e.target.value })
                  }
                />
              </div>

              <div className="form-group-field">
                <label>Mật khẩu mới</label>
                <input
                  type="password"
                  placeholder="Nhập mật khẩu mới (tối thiểu 6 ký tự)"
                  value={passwordData.newPassword}
                  onChange={(e) =>
                    setPasswordData({ ...passwordData, newPassword: e.target.value })
                  }
                />
              </div>

              <div className="form-group-field">
                <label>Xác nhận mật khẩu mới</label>
                <input
                  type="password"
                  placeholder="Nhập lại mật khẩu mới"
                  value={passwordData.confirmPassword}
                  onChange={(e) =>
                    setPasswordData({ ...passwordData, confirmPassword: e.target.value })
                  }
                />
              </div>

              <div className="modal-actions-footer">
                <button
                  className="btn-submit-save"
                  onClick={handlePasswordChange}
                >
                  Xác Nhận Đổi Mật Khẩu
                </button>
                <button
                  className="btn-submit-cancel"
                  onClick={() => setShowPopup("")}
                >
                  Hủy
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* 3. Modal Đổi Avatar */}
      {showPopup === "avatar" && (
        <div className="unified-popup-overlay" onClick={() => setShowPopup("")}>
          <div className="unified-popup-box" onClick={(e) => e.stopPropagation()}>
            <div className="popup-header-row">
              <h3 className="flex items-center gap-2">
                <Camera size={20} className="text-emerald-600" />
                Cập Nhật Ảnh Đại Diện
              </h3>
              <button className="popup-close-x" onClick={() => setShowPopup("")}>
                <X size={18} />
              </button>
            </div>
            <p className="text-sm text-slate-500 mb-3">
              Dán đường link hình ảnh (URL) bạn muốn sử dụng làm ảnh đại diện:
            </p>
            <input
              type="text"
              className="vehicle-search-box"
              placeholder="https://example.com/my-photo.jpg"
              value={formData.avatar}
              onChange={(e) => setFormData({ ...formData, avatar: e.target.value })}
            />
            <div className="modal-actions-footer">
              <button
                className="btn-submit-save"
                onClick={async () => {
                  await handleSaveProfile();
                  setShowPopup("");
                }}
              >
                Cập Nhật
              </button>
              <button className="btn-submit-cancel" onClick={() => setShowPopup("")}>
                Hủy
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 4. Modal Quản Lý Dòng Xe */}
      {showPopup === "vehicle" && (
        <div className="unified-popup-overlay" onClick={() => setShowPopup("")}>
          <div className="unified-popup-box" onClick={(e) => e.stopPropagation()}>
            <div className="popup-header-row">
              <h3 className="flex items-center gap-2">
                <Car size={20} className="text-emerald-600" />
                Quản Lý Dòng Xe Điện Của Bạn
              </h3>
              <button className="popup-close-x" onClick={() => setShowPopup("")}>
                <X size={18} />
              </button>
            </div>

            <input
              type="text"
              className="vehicle-search-box"
              placeholder="Tìm kiếm dòng xe (VinFast, Tesla, Porsche, BYD...)"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />

            <div className="vehicle-columns-grid">
              {/* Selected Column */}
              <div className="v-col">
                <h4>Xe Đã Chọn ({selectedVehicles.length})</h4>
                <div className="v-list-scroll">
                  {selectedVehicles.length === 0 ? (
                    <div className="text-xs text-slate-400 p-2">Chưa chọn xe nào</div>
                  ) : (
                    selectedVehicles.map((vId) => {
                      const v = vehicleModels.find((m) => m.id === vId);
                      return (
                        <div key={vId} className="v-item-row selected">
                          <span>{v?.modelName || vId}</span>
                          <button
                            className="text-red-500 text-xs font-bold"
                            onClick={() => handleDeleteVehicle(vId)}
                          >
                            Xóa
                          </button>
                        </div>
                      );
                    })
                  )}
                </div>
              </div>

              {/* Available Column */}
              <div className="v-col">
                <h4>Dòng Xe Hỗ Trợ</h4>
                <div className="v-list-scroll">
                  {vehicleModels
                    .filter((m) => !selectedVehicles.includes(m.id))
                    .filter((m) =>
                      normalize(m.modelName).includes(normalize(searchTerm))
                    )
                    .map((m) => (
                      <div key={m.id} className="v-item-row">
                        <span>{m.modelName}</span>
                        <button
                          className="text-emerald-600 text-xs font-bold"
                          onClick={() =>
                            setSelectedVehicles([...selectedVehicles, m.id])
                          }
                        >
                          + Chọn
                        </button>
                      </div>
                    ))}
                </div>
              </div>
            </div>

            <div className="modal-actions-footer">
              <button
                className="btn-submit-save"
                onClick={async () => {
                  await handleSaveProfile();
                  setShowPopup("editProfile");
                }}
              >
                Xác Nhận Xe
              </button>
              <button className="btn-submit-cancel" onClick={() => setShowPopup("editProfile")}>
                Quay Lại
              </button>
            </div>
          </div>
        </div>
      )}

      <ToastContainer position="top-right" autoClose={2000} />
    </div>
  );
};

export default UnifiedProfile;
