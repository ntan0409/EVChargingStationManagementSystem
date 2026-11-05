import { useState, useRef, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import "./ProfileMenu.css";
import { logout } from "../../API/Auth";
import { getEVDriverProfile } from "../../API/EVDriver";
import { MyBooking } from "../../API/Booking";
import { jwtDecode } from "jwt-decode";
import { User, Car, Clock, Zap, LogOut, ChevronDown, ShieldCheck } from "lucide-react";

const ProfileMenu = () => {
  const [open, setOpen] = useState(false);
  const [role, setRole] = useState("");
  const [driverProfile, setDriverProfile] = useState(null);

  const navigate = useNavigate();
  const menuRef = useRef();

  useEffect(() => {
    const token = localStorage.getItem("token");
    if (token) {
      try {
        const decoded = jwtDecode(token);
        setRole(decoded.role || "");
      } catch (err) {
        console.error("Không thể giải mã token:", err);
        setRole("");
      }
    }
  }, []);

  useEffect(() => {
    if (role === "EVDriver") {
      (async () => {
        try {
          const res = await getEVDriverProfile();
          const driver = res?.data?.data || res?.data;
          if (driver) setDriverProfile(driver);
        } catch (err) {
          console.error("Lỗi tải EVDriver profile:", err);
        }
      })();
    }
  }, [role]);

  const avatarSrc =
    role === "EVDriver"
      ? driverProfile?.profilePictureUrl || "https://cdn-icons-png.flaticon.com/512/847/847969.png"
      : "https://cdn-icons-png.flaticon.com/512/847/847969.png";

  const displayName = driverProfile?.name || (role === "Admin" ? "Quản Trị Viên" : role === "Staff" ? "Nhân Viên" : "Tài Xế EV");

  useEffect(() => {
    const handleClickOutside = (e) => {
      if (menuRef.current && !menuRef.current.contains(e.target)) {
        setOpen(false);
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const handleNavigate = (path) => {
    navigate(path);
    setOpen(false);
  };

  const handleSimulate = async () => {
    try {
      const res = await MyBooking();
      const bookings = res?.data || [];
      if (bookings.length === 0) {
        navigate("/station-list");
        return;
      }
      const booking = bookings[0];
      const stationId = booking.stationId;
      const postId = booking.chargingPostId;
      const connectorId = booking.connectorId;
      navigate(`/station-list/${stationId}/posts/${postId}/connector/${connectorId}/session`);
    } catch (err) {
      console.error("Lỗi xem booking:", err);
      navigate("/station-list");
    }
    setOpen(false);
  };

  return (
    <div className="profile-container" ref={menuRef}>
      <div className={`profile-pill-trigger ${open ? "active" : ""}`} onClick={() => setOpen(!open)}>
        <img src={avatarSrc} alt="Avatar" className="user-avatar" />
        <div className="trigger-user-info">
          <span className="user-display-name">{displayName}</span>
          <span className="user-role-badge">
            <ShieldCheck size={11} />
            <span>{role || "Thành viên"}</span>
          </span>
        </div>
        <ChevronDown size={14} className={`dropdown-arrow ${open ? "rotate" : ""}`} />
      </div>

      {open && (
        <div className="profile-dropdown-card">
          <div className="dropdown-header">
            <p className="dropdown-title">Tài Khoản EVOne</p>
            <p className="dropdown-subtitle">{displayName}</p>
          </div>

          <div className="dropdown-menu-list">
            <button className="dropdown-item" onClick={() => handleNavigate("/profile")}>
              <User size={16} />
              <span>Hồ sơ & Trung tâm tài xế</span>
            </button>

            {role === "EVDriver" && (
              <button className="dropdown-item" onClick={() => handleNavigate("/car")}>
                <Car size={16} />
                <span>Garage xe điện của tôi</span>
              </button>
            )}

            <button className="dropdown-item" onClick={() => handleNavigate("/order-charging")}>
              <Zap size={16} />
              <span>Đặt chỗ sạc trước</span>
            </button>

            <button className="dropdown-item" onClick={() => handleNavigate("/orders")}>
              <Clock size={16} />
              <span>Lịch sử đặt sạc</span>
            </button>

            <button className="dropdown-item" onClick={handleSimulate}>
              <Zap size={16} />
              <span>Mô phỏng sạc trực tiếp</span>
            </button>
          </div>

          <div className="dropdown-divider"></div>

          <button
            className="dropdown-item logout-action"
            onClick={() => {
              logout();
              setOpen(false);
            }}
          >
            <LogOut size={16} />
            <span>Đăng xuất</span>
          </button>
        </div>
      )}
    </div>
  );
};

export default ProfileMenu;
