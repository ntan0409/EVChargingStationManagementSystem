import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { Wallet, Calendar, BarChart2, HelpCircle, Star, MapPin, User, Receipt } from "lucide-react";
import { getEVDriverProfile } from "../../API/EVDriver";
import { MyBooking } from "../../API/Booking"; // API lấy lịch sử đặt trạm
import "./ProfilePage.css";

const ProfilePage = () => {
  const navigate = useNavigate();
  const [user, setUser] = useState(null);
  const [accountStatus, setAccountStatus] = useState("Đang tải...");
  const [recentOrders, setRecentOrders] = useState([]);
  const [totalBookingCount, setTotalBookingCount] = useState(0);
  const [linkedVehicles, setLinkedVehicles] = useState(0);

  // trong useEffect
  useEffect(() => {
    const fetchProfile = async () => {
      try {
        const profileRes = await getEVDriverProfile();
        if (profileRes?.data) {
          const data = profileRes.data;
          setUser({
            name: data.name || "Người dùng",
            role: "EVDriver",
          });

          setAccountStatus(
            data.status === "Active" ? "Đã kích hoạt" :
              data.status === "Inactive" ? "Chưa kích hoạt" :
                "Không xác định"
          );
          // Số xe liên kết
          setLinkedVehicles(data.vehicleModelIds?.length || 0);
        } else {
          setUser({ name: "Khách", role: null });
          setAccountStatus("Chưa kích hoạt");
        }
      } catch (err) {
        console.error("Lỗi khi lấy profile EVDriver:", err);
        setUser({ name: "Khách", role: null });
        setAccountStatus("Không xác định");
        setLinkedVehicles(0);
      }
    };

    const fetchRecentOrders = async () => {
      try {
        const res = await MyBooking();
        if (res?.data) {
          const filtered = res.data
            .filter(o => o.status !== "Cancelled")
            .sort((a, b) => new Date(b.startTime) - new Date(a.startTime));
          setRecentOrders(filtered.slice(0, 3)); // 3 gần nhất

          // Tổng số lần đặt (bỏ hủy)
          setTotalBookingCount(filtered.length);
        } else {
          setRecentOrders([]);
          setTotalBookingCount(0);
        }
      } catch (err) {
        console.error("Lỗi khi lấy đơn hàng:", err);
        setRecentOrders([]);
        setTotalBookingCount(0);
      }
    };

    fetchProfile();
    fetchRecentOrders();
  }, []);

  const quickActions = [
    { title: "Tìm trạm sạc", icon: <MapPin size={20} />, path: "/order-charging" },
    { title: "Lịch sử đặt lịch", icon: <Calendar size={20} />, path: "/orders" },
    { title: "Lịch sử thanh toán", icon: <Receipt size={20} />, path: "/payment-history", rolesAllowed: ["EVDriver", "user"] },
    { title: "Tài khoản", icon: <User size={20} />, path: "/profile", rolesAllowed: ["EVDriver", "user"] }, // chỉ user/EVDriver
    { title: "Hỗ trợ", icon: <HelpCircle size={20} />, path: "/user-report", rolesAllowed: ["EVDriver", "user"] },
    { title: "Đánh giá", icon: <Star size={20} />, path: "/rating-page", rolesAllowed: ["EVDriver", "user"] },
  ];

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

  return (
    <div className="profile-page">
      {/* Header */}
      <div className="profile-header">
        <div>
          <h1>Xin chào, {user?.name || "Người dùng"} 👋</h1>
          <p>Chào mừng bạn đến với hệ thống quản lý trạm sạc pin xe điện</p>
        </div>
        <div className="status">
          Tài khoản:{" "}
          <span className={`status-badge ${accountStatus === "Đã kích hoạt" ? "Active" : "Inactive"}`}>
            {accountStatus}
          </span>
        </div>
      </div>

      {/* Thao tác nhanh */}
      {user && (
        <div className="quick-actions">
          <h2>Thao tác nhanh</h2>
          <div className="actions-grid">
            {quickActions
              .filter(a => !a.rolesAllowed || a.rolesAllowed.includes(user?.role))
              .map((a, i) => (
                <div key={i} className="action-box" onClick={() => navigate(a.path)}>
                  <div className="icon">{a.icon}</div>
                  <p>{a.title}</p>
                </div>
              ))}
          </div>
        </div>
      )}

      {/* Giao dịch gần đây */}
      <div className="bottom-section">
        <div className="recent-transactions">
          <h3>Hoạt Động Gần Đây</h3>
          {recentOrders.length === 0 ? (
            <p>Chưa có hoạt động nào cả.</p>
          ) : (
            (() => {
              // Sort giảm dần theo startTime nếu chưa sort
              const sortedOrders = [...recentOrders].sort(
                (a, b) => new Date(b.startTime) - new Date(a.startTime)
              );
              const latestOrder = sortedOrders[0]; // chỉ lấy booking mới nhất
              return (
                <div className="transaction-item" key={latestOrder.id}>
                  <p>
                    Đặc sạc tại {latestOrder.stationName} <span className="positive"></span>
                  </p>
                  <p><small>Mã CheckIn Của Bạn: {latestOrder.checkInCode}</small></p>
                  <small>Thời gian bắt đầu: {formatDateTime(latestOrder.startTime)}</small>
                </div>
              );
            })()
          )}
          <button onClick={() => navigate("/orders")}>Xem tất cả giao dịch →</button>
        </div>


        {/* Trạng thái tài khoản & thông tin */}
        <div className="account-status">
          <h3>Trạng thái tài khoản</h3>
          <p>Số lần đặt : <span className="green">{totalBookingCount} lần</span></p>
          <p>Phương tiện đã liên kết: {linkedVehicles} xe</p>
          <p>Đánh giá trung bình: <span className="star">★ 4.8/5</span></p>

        </div>
      </div>

      {/* Hỗ trợ */}
      <div className="support-section">
        <div>
          <h3>Cần hỗ trợ?</h3>
          <p>Chúng tôi luôn sẵn sàng hỗ trợ bạn 24/7</p>
        </div>
        <div className="support-buttons">
          <button onClick={() => navigate("/user-report")}>Gửi yêu cầu hỗ trợ</button>
          <button onClick={() => navigate("/rating-page")}>Đánh giá dịch vụ</button>
        </div>
      </div>
    </div>
  );
};

export default ProfilePage;
