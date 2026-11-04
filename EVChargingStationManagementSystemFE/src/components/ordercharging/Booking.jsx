
import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { ToastContainer, toast } from "react-toastify";
import { addBooking ,MyBooking} from "../../API/Booking.js";
import { getVehicleModels } from "../../API/Admin";
import { getEVDriverProfile} from "../../API/EVDriver.js";
import { jwtDecode } from "jwt-decode";
import { useNotifications } from "../notification/NotificationContext.jsx";
import {getChargingStationId} from "../../API/Station.js"


import "react-toastify/dist/ReactToastify.css";
import "./Booking.css";
export default function BookingPopup({ stations = [], stationId, onClose, onAdded }) {
  const [termStation, setTermStation] = useState("");
  const [termVehicle, setTermVehicle] = useState("");
  const [showDropdownStation, setShowDropdownStation] = useState(false);
  const [showDropdownVehicle, setShowDropdownVehicle] = useState(false);
  const [vehicleModels, setVehicleModels] = useState([]);
  const [profile, setProfile] = useState(null);
  const [showSuccessPopup, setShowSuccessPopup] = useState(false);
  const [checkInCode,setcheckInCode]= useState(null);
  const [isStationLocked, setIsStationLocked] = useState(false);
  const { addNotification } = useNotifications();
  const navigate = useNavigate();

  const [bookingData, setBookingData] = useState({
    stationId: stationId || "",
    vehicleId: "",
    startTime: "",
    currentBattery: 0,
    targetBattery: 0,
  });
  // Khi stationId được truyền từ bên ngoài (ví dụ: click từ bản đồ)
  useEffect(() => {
    if (stationId) {
      const selected = stations.find(st => st.id === stationId);
      if (selected) {
        setTermStation(selected.stationName);
        setBookingData(prev => ({ ...prev, stationId }));
        setIsStationLocked(true); 
      }
    }
  }, [stationId, stations]);
  

  // Lấy danh sách xe
  useEffect(() => {
    const fetchVehicleModels = async () => {
      try {
        const res = await getVehicleModels();
        setVehicleModels(res.data || []);
      } catch (error) {
        console.error("Không thể lấy danh sách xe", error);
        toast.error("Không thể tải danh sách xe!");
      }
    };
    fetchVehicleModels();
  }, []);

  // Lấy hồ sơ EVDriver
  useEffect(() => {
    const fetchProfile = async () => {
      try {
        const res = await getEVDriverProfile();
        const data = res?.data?.data || res?.data || {};
        setProfile({
          name: data.name,
          phoneNumber: data.phoneNumber,
          selectedVehicles: data.vehicleModelIds || [],
        });
      } catch (error) {
        console.error("Không thể lấy hồ sơ người dùng", error);
      }
    };
    fetchProfile();
  }, []);
  
  let role = null;

  const token = localStorage.getItem("token");
  if (token) {
  try {
    const decoded = jwtDecode(token);
    role = decoded.role;
  } catch (err) {
    console.error("Không thể giải mã token:", err);
  }
}
console.log("Lấy Role:", role);

  //  Kiểm tra quyền role

  if (role !== "EVDriver") {
    console.log('Lấy Role',role);
    return (
      <div className="popup-overlay" onClick={onClose}>
        <div className="popup-container" onClick={(e) => e.stopPropagation()}>
          <h3> Xin hãy đăng nhập để có thể sử dụng dịch vụ.</h3>
          <div className="btn-buttonlogin">
              <button
                className="btn-login"
                onClick={() => navigate("/login")}
              >
                Đăng nhập
              </button>
            </div>
          
        </div>
      </div>
    );
    
  }

  // Kiểm tra profile hoàn chỉnh
  const isProfileIncomplete =
    !profile ||
    !profile.name ||
    profile.name.trim() === "" ||
    profile.name.includes("Chưa cập nhật") ||
    !profile.phoneNumber ||
    profile.phoneNumber.trim() === "" ||
    profile.phoneNumber.includes("Chưa cập nhật") ||
    !profile.selectedVehicles ||
    profile.selectedVehicles.length === 0;

  if (isProfileIncomplete) {
    return (
      <div className="popup-overlay" onClick={onClose}>
        <div className="popup-container" onClick={(e) => e.stopPropagation()}>
          <h3> Hồ sơ chưa hoàn chỉnh</h3>
          <p>
            Vui lòng cập nhật đủ <b>Họ tên</b>, <b>Số điện thoại</b>,<b>Xe</b> và hãy xác minh <b>email</b> của bạn thông qua hộp thư chúng tôi gửi trước khi đặt lịch sạc.
          </p>
          <button className="cancel-btn" onClick={onClose}>Đóng</button>
        </div>
      </div>
    );
  }
  const userVehicles = vehicleModels.filter(v =>
    profile?.selectedVehicles?.includes(v.id)
  );

  const normalize = (str = "") =>
    str.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();

  const escapeRegex = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

  const filteredStations = termStation
    ? stations.filter(
        (st) =>
          normalize(st.stationName).includes(normalize(termStation)) ||
          normalize(st.location).includes(normalize(termStation)) ||
          normalize(st.province).includes(normalize(termStation))
      )
    : stations;

  const filteredVehicles = termVehicle
    ? userVehicles.filter(
        (v) =>
          normalize(v.modelName).includes(normalize(termVehicle)) ||
          normalize(v.vehicleType).includes(normalize(termVehicle))
      )
    : userVehicles;

  const handleSelectStation = (st) => {
    setTermStation(st.stationName);
    setBookingData({ ...bookingData, stationId: st.id });
    setShowDropdownStation(false);
  };

  const handleSelectVehicle = (v) => {
    setTermVehicle(`${v.vehicleType} ${v.modelName}`);
    setBookingData({ ...bookingData, vehicleId: v.id });
    setShowDropdownVehicle(false);
  };

  const handleAddBooking = async () => {
  if (!bookingData.stationId || !bookingData.vehicleId || !bookingData.startTime) {
    toast.warning("⚠️ Vui lòng nhập đủ thông tin!");
    return;
  }

  try {
    // --- Lấy dữ liệu trạm mới nhất ---
    const stationDetail = await getChargingStationId(bookingData.stationId);
    const posts = stationDetail.chargingPosts || [];

    // Lấy thông tin xe người dùng chọn
    const selectedVehicle = vehicleModels.find(v => v.id === bookingData.vehicleId);
    if (!selectedVehicle) {
      toast.error("Xe không hợp lệ, vui lòng chọn lại!");
      return;
    }
    const userVehicleType = selectedVehicle.vehicleType.toLowerCase(); // 'car' hoặc 'bike'

    // Kiểm tra trạm có hỗ trợ loại xe này không
    const hasSupported = posts.some(
      (p) =>
        p.vehicleTypeSupported?.toLowerCase().includes(userVehicleType) &&
        p.status?.toLowerCase() === "available"
    );

    if (!hasSupported) {
      toast.error("❌ Trạm này không hỗ trợ loại xe của bạn hoặc không còn trụ khả dụng!");
      return;
    }

    // Chuyển thời gian về ISO VN
    const localTime = new Date(bookingData.startTime);
    const startTimeVN = new Date(localTime.getTime() - localTime.getTimezoneOffset() * 60000);
    const startTimeISO = startTimeVN.toISOString();

    // --- Thêm booking ---
    const res = await addBooking(
      bookingData.stationId,
      bookingData.vehicleId,
      startTimeISO,
      parseInt(bookingData.currentBattery),
      parseInt(bookingData.targetBattery)
    );

    if (res?.data?.message) {
      toast.success(res.data.message);
    }

    setcheckInCode(res?.data?.checkInCode || null);
    setShowSuccessPopup(true);
    if (res?.data?.checkInCode) {
      addNotification(`Booking thành công! Mã check-in: ${res.data.checkInCode}`);
    }
  } catch (error) {
    console.error("Booking error:", error);
    const msg = error?.response?.data?.message || error?.message || "";
    if (msg.includes("Bạn đã có booking đang hoạt động")) {
      toast.warning("Bạn đã có một đơn đặt lịch trước đó, vui lòng hoàn thành đơn hàng cũ!");
    } else if (msg.includes("Thời gian bắt đầu phải cách hiện tại")) {
      toast.warning("Bạn cần đặt lịch sạc trước ít nhất 5 phút so với hiện tại!");
    } else if (msg.includes("Tài khoản chưa được xác thực")) {
      toast.error("Tài khoản của bạn chưa được xác thực. Vui lòng xác thực trước khi đặt lịch!");
    } else if (msg.includes("Tất cả cổng sạc tại trạm đều đã được đặt trong thời gian này.")) {
      toast.warning("Trạm sạc hiện không có cổng sạc khả dụng, vui lòng thử lại trạm khác!");
    }else if (msg.includes("Trạm sạc hiện không có cổng sạc hoạt động.")) {
      toast.warning("Trạm sạc hiện không có cổng sạc hoạt động vui lòng chọn trạm khác ");
    } else {
      toast.error("Lỗi khi thêm đặt lịch sạc hoặc chọn sai thời gian bắt đầu!");
    }
  }
};



  const closeSuccessPopup = () => {
    setShowSuccessPopup(false);
    if (onAdded) onAdded();
    onClose();
  };

  return (
    <div className="popup-overlay" onClick={onClose}>
      <div className="popup-container" onClick={(e) => e.stopPropagation()}>
        <h3>Thêm Booking Mới</h3>

        <label>Chọn trạm:</label>
        <div className="autocomplete-container">
          <input
            type="text"
            placeholder="Nhập tên trạm, tỉnh hoặc địa chỉ"
            value={termStation}
            onFocus={() => setShowDropdownStation(true)}
            onChange={(e) => {
              setTermStation(e.target.value);
              setShowDropdownStation(true);
            }}
            disabled={isStationLocked}
            className="autocomplete-input"
          />
          {showDropdownStation && filteredStations.length > 0 && (
            <div className="autocomplete-list">
              {filteredStations.map((st) => {
                const regex = new RegExp(`(${escapeRegex(termStation)})`, "i");
                const parts = st.stationName.split(regex);
                return (
                  <div
                    key={st.id}
                    className="autocomplete-item"
                    onClick={() => handleSelectStation(st)}
                  >
                    {parts.map((part, i) =>
                      regex.test(part) ? <span key={i} className="highlight">{part}</span> : part
                    )}{" "}
                    ({st.location}, {st.province})
                  </div>
                );
              })}
            </div>
          )}
        </div>

        <label>Chọn xe:</label>
        <div className="autocomplete-container">
          <input
            type="text"
            placeholder="Nhập tên hoặc hãng xe"
            value={termVehicle}
            onFocus={() => setShowDropdownVehicle(true)}
            onChange={(e) => {
              setTermVehicle(e.target.value);
              setShowDropdownVehicle(true);
            }}
            className="autocomplete-input"
          />
          {showDropdownVehicle && filteredVehicles.length > 0 && (
            <div className="autocomplete-list">
              {filteredVehicles.map((v) => {
                const regex = new RegExp(`(${escapeRegex(termVehicle)})`, "i");
                const parts =`${v.vehicleType} ${v.modelName}`.split(regex);
                return (
                  <div
                    key={v.id}
                    className="autocomplete-item"
                    onClick={() => handleSelectVehicle(v)}
                  >
                    {parts.map((part, i) =>
                      regex.test(part) ? <span key={i} className="highlight">{part}</span> : part
                    )}
                  </div>
                );
              })}
            </div>
          )}
        </div>

        <label>Thời Gian Bắt Đầu</label>
        <input
          type="datetime-local"
          value={bookingData.startTime}
          onChange={(e) => setBookingData({ ...bookingData, startTime: e.target.value })}
        />

        <div className="popup-buttons">
          <button className="cancel-btn" onClick={onClose}>Hủy</button>
          <button className="add-btn" onClick={handleAddBooking}>Xác nhận</button>
          
        </div>
      </div>

      {/* Popup thành công */}
      {showSuccessPopup && (
        <div className="popup-overlay">
          <div className="popup-container success-popup" onClick={(e) => e.stopPropagation()}>
            <h3>🎉 Đặt Lịch Thành Công!</h3>
            <p>---------------------------------------</p>
            {checkInCode && (
              <p>
                <b>Mã check-in của bạn:</b> <span style={{ color: "#28a745" }}>{checkInCode}</span>
              </p>
            )}
            <p>---------------------------------------</p> 

            

            <button className="btn-close" onClick={closeSuccessPopup}>Đóng</button>
          </div>
        </div>
      )}

      <ToastContainer position="top-right" autoClose={2000} />
    </div>
  );
}
