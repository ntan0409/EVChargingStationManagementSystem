import React, { useState, useEffect, useRef } from "react";
import "./Profile.css";
import { updateEVDriver, getEVDriverProfile, deleteEVDriverVehicalid } from "../../API/EVDriver";
import { getVehicleModels } from "../../API/Admin";
import { changePassword } from "../../API/Auth";
import { ToastContainer, toast } from "react-toastify";
import { SettingOutlined } from '@ant-design/icons';
import "react-toastify/dist/ReactToastify.css";

const defaultAvatars = {
  EVDriver: "https://cdn-icons-png.flaticon.com/512/847/847969.png"
};

const Profile = () => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [mode, setMode] = useState("view");
  const [showPopup, setShowPopup] = useState("");
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
  const [dropdownOpen, setDropdownOpen] = useState(false);
  const dropdownRef = useRef(null);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const res = await getEVDriverProfile();
        const driver = res?.data?.data || res?.data;

        if (driver) {
          const userData = {
            name: driver.name || "",
            email: driver.email || "",
            phone: driver.phoneNumber || "",
            role: driver.role || "",
            avatar: driver.profilePictureUrl || "",
            address: driver.address || "",
            driverId: driver.id,
            vehicleModelIds: driver.vehicleModelIds || [],
          };
          setUser(userData);
          setFormData(userData);
          setSelectedVehicles([...userData.vehicleModelIds]);
        } else {
          toast.warn("Không có dữ liệu tài xế!");
        }

        const modelRes = await getVehicleModels();
        setVehicleModels(modelRes?.data || []);
      } catch (err) {
        console.error("Lỗi khi load dữ liệu:", err);
        toast.error("Không thể tải thông tin tài xế!");
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  // đóng dropdown khi click ra ngoài
  useEffect(() => {
    const handleClickOutside = (e) => {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target)) {
        setDropdownOpen(false);
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const handleSaveProfile = async () => {
    try {
      if (!user?.driverId) {
        toast.error("Không tìm thấy mã tài xế!");
        return;
      }

      console.log("Dữ liệu gửi lên:", {
        driverId: user.driverId,
        name: formData.name,
        phoneNumber: formData.phone,
        address: formData.address || "",
        profilePictureUrl: formData.avatar || "",
        vehicleModelIds: selectedVehicles,
      });

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
        setMode("view");
        setShowPopup("");
        toast.success("Cập nhật thông tin thành công!");
      } else {
        toast.error(res?.data?.message || "Lỗi cập nhật!");
      }
    } catch (error) {
      console.error("Lỗi khi cập nhật:", error.response?.data || error);
      toast.error("Cập nhật thất bại, vui lòng thử lại!");
    }
  };

  const normalize = (str = "") =>
    str.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();

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
    const res = await changePassword(oldPassword, newPassword, confirmPassword);
    toast.success("Đổi mật khẩu thành công!");
    setPasswordData({ oldPassword: "", newPassword: "", confirmPassword: "" });
    setMode("view");
  } catch (err) {
    console.log("Lỗi đổi mật khẩu:", err.response?.data || err);
    const msg =
      err.response?.data?.message ||
      "Mật khẩu cũ không đúng";
    toast.error(msg);
  }
};


  const handleDelete = async (vehicleModelId) => {
    if (!vehicleModelId) return;
    setSelectedVehicles((prev) => prev.filter((id) => id !== vehicleModelId));
    if (window.confirm("Bạn chắc muốn xóa loại xe này khỏi danh sách chứ?")) {
      try {
        await deleteEVDriverVehicalid(vehicleModelId);
        toast.success("Xóa thành công!");  
      } catch (error) {
      }
    }
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  if (loading) return <p className="loading">Đang tải...</p>;
  if (!user) return <p>Không tìm thấy thông tin tài xế</p>;

  // Hiển thị tên xe
  const selectedVehicleNames = selectedVehicles
    .map((id) => vehicleModels.find((v) => v.id === id)?.modelName || id)
    .filter(Boolean);

  return (
    
    <div className="profile-wrapper">
      

      {/* Sidebar */}
      <div className="profile-sidebar">
        <div className="sidebar-card user-card">
          <div className="avatar-container">
            <img
              src={
                formData.avatar
                  ? formData.avatar
                  : defaultAvatars[user.role] || defaultAvatars["EVDriver"]
              }
              alt="avatars"
              className="avatars"
            />
            <button
              className="edit-avatar-icon"
              onClick={() => setShowPopup("avatar")}
              title="Đổi ảnh đại diện"
            >
              📷
            </button>
          </div>
          <p className="welcome">Xin chào</p>
          <h3>{user.name}</h3>
        </div>

        <div className="sidebar-card notice-card">
          {/* <p className="warning">Thông tin tài xế</p> */}
          <p className="desc">Hãy cập nhật đầy đủ thông tin tài khoản để sử dụng dịch vụ tốt hơn.</p>
        </div>
      </div>

      {/* Main */}
      <div className="profile-main">
        <div className="profile-card">
          <div className="profile-header">
            <h2>Thông tin cá nhân</h2>
            {mode === "view" && (
              <button className="edit-btn" onClick={() => setMode("edit")}>
                <SettingOutlined className="setting-icon" />
              </button>
            )}
          </div>

          {mode === "view" && (
            <div className="profile-info">
              <div className="info-row">
                <span className="label">Họ và tên</span>
                <span>{user.name}</span>
              </div>
              <div className="info-row">
                <span className="label">Email</span>
                <span>{user.email}</span>
              </div>
              <div className="info-row">
                <span className="label">Số điện thoại</span>
                <span>{user.phone}</span>
              </div>
              <div className="info-row">
                <span className="label">Địa chỉ</span>
                <span>{user.address}</span>
              </div>

              <div className="info-row vehicle-row">
                <span className="label">Xe</span>

                {/* Dropdown click-to-toggle */}
                <div className="vehicle-right">
                  <div
                    className={`vehicle-dropdown ${dropdownOpen ? "open" : ""}`}
                    ref={dropdownRef}
                  >
                    <button
                      className="dropdown-toggle"
                      onClick={() => setDropdownOpen((s) => !s)}
                    >
                      <span className="selected-text">
                        {selectedVehicleNames.length > 0
                          ? `${selectedVehicleNames.length} xe đã chọn`
                          : "Chưa có xe"}
                      </span>
                      <span className="caret">{dropdownOpen ? "▲" : "▼"}</span>
                    </button>

                    {/* PANEL */}
                    <div className="dropdown-panel">
                      {selectedVehicleNames.length === 0 ? (
                        <div className="dropdown-empty">Chưa có xe</div>
                      ) : (
                        <div className="dropdown-items">
                          {selectedVehicles.map((id) => {
                            const vehicle = vehicleModels.find((v) => v.id === id);
                            return (
                              <div key={id} className="dropdown-item-row">
                                <span className="vehicle-name" title={vehicle?.modelName}>
                                  {vehicle?.modelName}
                                </span>

                                <button
                                  className="remove-vehicle-btn"
                                  onClick={() => handleDelete(id)}
                                >
                                  ✕
                                </button>
                              </div>
                            );
                          })}
                        </div>
                      )}

                      <div className="dropdown-footer">
                        <button
                          className="manage-btn"
                          onClick={() => {
                            setShowPopup("vehicle");
                            setDropdownOpen(false);
                          }}
                        >
                          Quản lý xe
                        </button>
                      </div>
                    </div>
                  </div>

                  {/* <button
                    className="link-btn"
                    onClick={() => {
                      setShowPopup("vehicle");
                      setDropdownOpen(false);
                    }}
                  >
                    Chỉnh sửa
                  </button> */}
                </div>

              </div>

              <div className="info-row">
                <span className="label">Mật khẩu</span>
                <button className="link-btn" onClick={() => setMode("password")}>
                  Đổi mật khẩu
                </button>
              </div>
            </div>
          )}

          {mode === "edit" && (
            <div className="profile-form">
              <h3>Tên</h3>
              <input type="text" name="name" placeholder="Xin Hãy Điền Tên " value={formData.name} onChange={handleInputChange} />
              <h3>Email</h3>
              <input type="email" name="email" placeholder="Xin Hãy Điền Email " value={formData.email} readOnly />
              <h3>Số điện thoại</h3>
              <input type="text" name="phone" placeholder="Xin Hãy Điền Số Điện Thoại " value={formData.phone} onChange={handleInputChange} />
              <h3>Địa chỉ</h3>
              <input type="text" name="address" placeholder="Xin Hãy Điền Địa Chỉ " value={formData.address} onChange={handleInputChange} />
              <div className="form-buttons">
                <button className="save" onClick={handleSaveProfile}>Lưu</button>
                <button className="cancel" onClick={() => setMode("view")}>Hủy</button>
              </div>
            </div>
          )}

          {mode === "password" && (
            <div className="profile-form">
              <input type="password" placeholder="Mật khẩu cũ" value={passwordData.oldPassword}
                onChange={(e) => setPasswordData({ ...passwordData, oldPassword: e.target.value })} />
              <input type="password" placeholder="Mật khẩu mới" value={passwordData.newPassword}
                onChange={(e) => setPasswordData({ ...passwordData, newPassword: e.target.value })} />
              <input type="password" placeholder="Xác nhận mật khẩu mới" value={passwordData.confirmPassword}
                onChange={(e) => setPasswordData({ ...passwordData, confirmPassword: e.target.value })} />
              <div className="form-buttons">
                <button className="save" onClick={handlePasswordChange}>Đổi mật khẩu</button>
                <button className="cancel" onClick={() => setMode("view")}>Hủy</button>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Popup Vehicle */}
      {showPopup && (
        <div className="popup-overlay">
          <div className="popup">
            {showPopup === "avatar" && (
              <div className="popup-img">
                <h3>Nhập URL ảnh đại diện</h3>
                <input
                  type="text"
                  placeholder="Dán link ảnh"
                  value={formData.avatar}
                  onChange={(e) => setFormData((prev) => ({ ...prev, avatar: e.target.value }))}
                />
                <div className="popup-buttons">
                  <button className="save" onClick={async () => { await handleSaveProfile(); setShowPopup(""); }}>Lưu</button>
                  <button className="cancel" onClick={() => setShowPopup("")}>Hủy</button>
                </div>
              </div>
            )}

            {showPopup === "vehicle" && (
              <div className="popup vehicle-popup">
                <h3>Tìm loại xe</h3>
                <input
                  type="text"
                  placeholder="Nhập tên xe để tìm..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="vehicle-search-input"
                />

                <div className="vehicle-popup-body">
                  {/* Cột Xe đã chọn */}
                  <div className="selected-vehicles-column">
                    <h3>Xe đã chọn</h3>
                    <div className="selected-vehicles scrollable">
                      {selectedVehicles.length === 0 && <p>Chưa có xe nào</p>}
                      {selectedVehicles.map((vId) => {
                        const vehicle = vehicleModels.find((vm) => vm.id === vId);
                        return (
                          <div key={vId} className="vehicle-item selected">
                            <span>{vehicle?.modelName || vId}</span>
                            <button className="link-btn" onClick={() => handleDelete(vId)}>
                              Xóa
                            </button>
                          </div>
                        );
                      })}
                    </div>
                  </div>

                  {/* Cột Xe có thể chọn */}
                  <div className="available-vehicles-column">
                    <h3>Những loại xe hỗ trợ</h3>
                    <div className="available-vehicles scrollable">
                      {vehicleModels
                        .filter((vm) => !selectedVehicles.includes(vm.id))
                        .filter((vm) =>
                          normalize(vm.modelName).includes(normalize(searchTerm))
                        )
                        .map((vm) => (
                          <div key={vm.id} className="vehicle-item">
                            <span>{vm.modelName}</span>
                            <button
                              className="link-btn"
                              onClick={() =>
                                setSelectedVehicles([...selectedVehicles, vm.id])
                              }
                            >
                              Chọn
                            </button>
                          </div>
                        ))}
                      {vehicleModels.filter(
                        (vm) =>
                          !selectedVehicles.includes(vm.id) &&
                          normalize(vm.modelName).includes(normalize(searchTerm))
                      ).length === 0 && <p>Không tìm thấy xe</p>}
                    </div>
                  </div>
                </div>


                <div className="popup-buttons">
                  <button
                    className="save"
                    onClick={async () => {
                      await handleSaveProfile();
                      setShowPopup("");
                    }}
                  >
                    Lưu
                  </button>
                  <button className="cancel" onClick={() => setShowPopup("")}>
                    Hủy
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      )}
      <ToastContainer position="top-right" autoClose={2000} />
    </div>
  );
};

export default Profile;
