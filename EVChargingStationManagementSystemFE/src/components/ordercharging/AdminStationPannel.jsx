import React, { useEffect, useState } from "react";
import {
  getChargingStation,
  addChargingStation,
  updateChargingStation,
  deleteChargingStation,
  updateChargingStationStatus,
} from "../../API/Station";
import { getMyAccountStaff } from "../../API/Staff";
import { toast } from "react-toastify";
import "./ChargingPost.css";

const AdminStationPanel = ({ onClose, onUpdated, onReloadAdminPannel }) => {
  const [stations, setStations] = useState([]);
  const [selectedAction, setSelectedAction] = useState(""); // "add" | "update" | "delete" | "status"
  const [editingStation, setEditingStation] = useState(null);
  const [searchTerm, setSearchTerm] = useState("");
  const [staff, setStaff] = useState([]);
  const [searchTermStaff, setSearchTermStaff] = useState("");
  const [showDropdownStaff, setShowDropdownStaff] = useState(false);

  const [formData, setFormData] = useState({
    stationName: "",
    location: "",
    province: "",
    latitude: "",
    longitude: "",
    status: "",
    operatorId: "",
  });
  const statusLabel = {
    InActive: "Ngưng hoạt động",
    Active: "Sẵn sàng",
    Maintained: "Bảo trì",
    Busy: "Đang sử dụng", // BE trả Busy → FE hiển thị Đang sử dụng
  };

  // Load stations
  const loadStations = async () => {
    try {
      const res = await getChargingStation();
      const data = Array.isArray(res) ? res : res.data || [];
      setStations(data);
    } catch (err) {
      console.error("Lỗi load trạm:", err);
      toast.error("Không thể tải danh sách trạm!");
    }
  };

  // Load staff
  const loadStaff = async () => {
    try {
      const res = await getMyAccountStaff();
      const activeStaff = (res.data || []).filter((s) => s.status === "Active");
      setStaff(activeStaff);
    } catch (err) {
      console.error("Lỗi load staff:", err);
      toast.error("Không thể tải danh sách nhân viên!");
    }
  };

  useEffect(() => {
    loadStations();
    loadStaff();
  }, []);

  // Prefill operator khi edit
  useEffect(() => {
    if (!editingStation || staff.length === 0) return;
    const found = staff.find((s) => s.id === editingStation.operatorId);
    if (found) {
      setSearchTermStaff(found.name);
      setFormData((prev) => ({ ...prev, operatorId: found.id }));
    } else {
      setSearchTermStaff("");
    }
  }, [editingStation, staff]);

  // Reset form khi đổi action
  useEffect(() => {
    if (selectedAction === "add") {
      setEditingStation(null);
      setFormData({
        stationName: "",
        location: "",
        province: "",
        latitude: "",
        longitude: "",
        status: "",
        operatorId: "",
      });
      setSearchTermStaff("");
    }
  }, [selectedAction]);

  // Normalize for search
  const normalize = (str = "") =>
    str.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();
  const escapeRegex = (s) => {
    if (typeof s !== "string") return "";
    return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  };

  const filteredStations = searchTerm
    ? stations.filter(
        (st) =>
          normalize(st.stationName).includes(normalize(searchTerm)) ||
          normalize(st.location).includes(normalize(searchTerm)) ||
          normalize(st.province).includes(normalize(searchTerm))
      )
    : stations;

  const filteredStaff = searchTermStaff
    ? staff.filter((s) => normalize(s.name).includes(normalize(searchTermStaff)))
    : staff;

 const handleSubmit = async (e) => {
  e.preventDefault();
  try {
    if (editingStation) {
      const updatedData = {
        stationName: formData.stationName,
        location: formData.location,
        province: formData.province,
        latitude: formData.latitude,
        longitude: formData.longitude,
      };
      await updateChargingStation(editingStation.id, updatedData);
      toast.success("Cập nhật trạm thành công!");
    } else {
      if (!formData.operatorId) {
        toast.error("Vui lòng chọn nhân viên Operator!");
        return;
      }
      await addChargingStation(
        formData.stationName,
        formData.location,
        formData.province,
        formData.latitude,
        formData.longitude,
        formData.operatorId
      );
      toast.success("Thêm trạm mới thành công!");
    }

    // Reload danh sách trạm sau submit
    await loadStations();

    // Reset form chỉ khi thêm mới, không reset khi edit
    if (!editingStation) {
      setFormData({
        stationName: "",
        location: "",
        province: "",
        latitude: "",
        longitude: "",
        status: "",
        operatorId: "",
      });
      setSearchTermStaff("");
    }

    // Nếu muốn đóng form sau submit
    // setSelectedAction("");
    onUpdated?.();
    onReloadAdminPannel?.();
  } catch (err) {
    console.error(err);
    const msg = err.response?.data?.message || err.message;
    toast.error(
      msg.includes("đã được phân công")
        ? "Nhân viên đã được phân công ở trạm khác!"
        : "Lỗi lưu dữ liệu trạm!"
    );
  }
};


  const handleEditClick = (st) => {
    setEditingStation(st);
    setSelectedAction("update");
    setFormData({
      stationName: st.stationName || "",
      location: st.location || "",
      province: st.province || "",
      latitude: st.latitude || "",
      longitude: st.longitude || "",
      operatorId: st.operatorId,
    });
  };

  const handleDelete = async (id) => {
    if (!window.confirm("Xác nhận xóa trạm này?")) return;
    try {
      await deleteChargingStation(id);
      toast.success("Xóa trạm thành công!");
      await loadStations();
      onUpdated?.();
      onReloadAdminPannel?.();
    } catch (err) {
      console.error(err);
      toast.error("Xóa trạm thất bại!");
    }
  };

  const handleChangeStatus = async (st, status) => {
    try {
      await updateChargingStationStatus(st.id, status);
      toast.success("Cập nhật trạng thái thành công!");
      await loadStations();
      onUpdated?.();
      onReloadAdminPannel?.();
    } catch (err) {
      console.error(err);
      toast.error("Lỗi cập nhật trạng thái trạm!");
    }
  };

  return (
    <div className="post-popup-overlay">
      <div className="post-popup-box">
        {/* Sidebar */}
        <div className="post-popup-sidebar">
          <button onClick={() => setSelectedAction("status")}>Trạng thái</button>
          <button onClick={() => setSelectedAction("update")}>Cập nhật</button>
          <button onClick={() => setSelectedAction("delete")}>Xóa</button>
          <button onClick={onClose} className="close-btn">Đóng</button>
        </div>

        {/* Content */}
        <div className="post-popup-content">
          <h3>Quản lý trạm sạc</h3>

          {/* Form thêm/cập nhật */}
          {(selectedAction === "add" || (selectedAction === "update" && editingStation)) && (
            <form onSubmit={handleSubmit} className="post-popup-form">
              <label>
                Tên trạm:
                <input type="text" value={formData.stationName} onChange={(e) => setFormData({ ...formData, stationName: e.target.value })} required />
              </label>
              <label>
                Địa chỉ:
                <input type="text" value={formData.location} onChange={(e) => setFormData({ ...formData, location: e.target.value })} required />
              </label>
              <label>
                Tỉnh/Thành:
                <input type="text" value={formData.province} onChange={(e) => setFormData({ ...formData, province: e.target.value })} required />
              </label>
              <label>
                Kinh Độ:
                <input type="text" value={formData.latitude} onChange={(e) => setFormData({ ...formData, latitude: e.target.value })} required />
              </label>
              <label>
                Vĩ Độ:
                <input type="text" value={formData.longitude} onChange={(e) => setFormData({ ...formData, longitude: e.target.value })} required />
              </label>

              {!editingStation && (
                <>
                  <label>Chọn nhân viên :</label>
                  <div className="autocomplete-container">
                    <input
                      type="text"
                      placeholder="Nhập tên nhân viên"
                      value={searchTermStaff}
                      onFocus={() => setShowDropdownStaff(true)}
                      onChange={(e) => {
                        setSearchTermStaff(e.target.value);
                        setShowDropdownStaff(true);
                      }}
                      className="autocomplete-input"
                    />
                    {showDropdownStaff && filteredStaff.length > 0 && (
                      <div className="autocomplete-list">
                        {filteredStaff.map((s) => {
                          const regex = new RegExp(`(${escapeRegex(searchTermStaff)})`, "i");
                          const parts = s.name.split(regex);
                          return (
                            <div key={s.id} className="autocomplete-item" onClick={() => { setSearchTermStaff(s.name); setFormData({ ...formData, operatorId: s.id }); setShowDropdownStaff(false); }}>
                              {parts.map((part, i) => regex.test(part) ? <span key={i} className="highlight">{part}</span> : part)} ({s.status})
                            </div>
                          );
                        })}
                      </div>
                    )}
                  </div>
                </>
              )}

              <button type="submit">{editingStation ? "Lưu cập nhật" : "Thêm trạm"}</button>
            </form>
          )}

          {/* Danh sách trạm luôn hiển thị */}
          <div className="post-popup-list">
            <h4>Danh sách trạm</h4>
            <input
              type="text"
              placeholder="Tìm kiếm theo tên, địa chỉ, tỉnh..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="search-input"
            />
            {filteredStations.length === 0 ? (
              <p>Không có trạm nào.</p>
            ) : (
              filteredStations.map((st) => (
                <div key={st.id} className="post-popup-item">
                  <span>
                    {st.stationName} - {st.location}, {st.province} | Trạng thái: {statusLabel[st.status] || "Chưa xác định"}
                  </span>
                  {selectedAction === "update" && <button onClick={() => handleEditClick(st)}>Sửa</button>}
                  {selectedAction === "delete" && <button onClick={() => handleDelete(st.id)}>Xóa</button>}
                  {selectedAction === "status" && (
                    <select defaultValue={st.status || "Inactive"} onChange={(e) => handleChangeStatus(st, e.target.value)}>
                      <option value="Inactive">Ngưng Hoạt Động</option>
                      <option value="Active">Hoạt Động</option>
                      <option value="Maintenance">Bảo trì</option>
                    </select>
                  )}
                </div>
              ))
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default AdminStationPanel;
