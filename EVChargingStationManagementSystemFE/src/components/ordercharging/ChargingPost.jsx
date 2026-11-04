import React, { useEffect, useState } from "react";
import { useRef } from "react";
import { toast } from "react-toastify";
import {
  getAllChargingPost,
  addChargingPost,
  updateChargingPost,
  deleteChargingPost,
  updateChargingPostStatus,
} from "../../API/ChargingPost";
import { getChargingStation } from "../../API/Station";
import "./ChargingPost.css";


const ChargingPost = ({ onClose, onUpdated }) => {
  const [stations, setStations] = useState([]);
  const [selectedStation, setSelectedStation] = useState(null);
  const [posts, setPosts] = useState([]);
  const [searchTerm, setSearchTerm] = useState("");
  const [showDropdown, setShowDropdown] = useState(false);
  const [showPostList, setShowPostList] = useState(false);
  const [mode, setMode] = useState(""); // add | edit | delete | status
  const [formData, setFormData] = useState({
    postName: "",
    connectorType: "",
    maxPowerKw: "",
    vehicleTypeSupported: 0,
    totalConnectors: "",
  });
  const [selectedPost, setSelectedPost] = useState(null);
  const listRef = useRef();

  const statusMap = {
    InActive: 0,
    Available: 1,
    Maintained: 2,
  };
  const statusLabel = {
    InActive: "Ngưng hoạt động",
    Available: "Sẵn sàng",
    Maintained: "Bảo trì",
    Busy: "Đang sử dụng", // BE trả Busy → FE hiển thị Đang sử dụng
  };

  //  Load danh sách trạm
  useEffect(() => {
    const fetchStations = async () => {
      try {
        const res = await getChargingStation();
        const stationList = Array.isArray(res.data) ? res.data : [];
        setStations(stationList);
        
      } catch (err) {
        console.error(" Lỗi load danh sách trạm:", err);
        setStations([]);
      }
    };
    fetchStations();
  }, []);

  //  Load trụ theo stationId
      const loadPosts = async (stationId) => {
        try {
          const posts = await getAllChargingPost(stationId);
          setPosts(posts || []);
        } catch (err) {
          console.error(" Lỗi load trụ:", err);
        }
      };
  
  const normalize = (str = "") =>
  str.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();

  const filteredStations = searchTerm
    ? stations.filter(
        (st) =>
          normalize(st.stationName).includes(normalize(searchTerm)) ||
          normalize(st.location).includes(normalize(searchTerm)) ||
          normalize(st.province).includes(normalize(searchTerm))
      )
    : stations;

  //  Khi chọn trạm
  const handleSelectStation = (id) => {
    const found = stations.find((s) => s.id === id);
    setSelectedStation(found || null);
    setSelectedPost(null);
    loadPosts(id);
    setShowPostList(true);
  };


  //  Chọn trụ để sửa
  const handleSelectPost = (post) => {
    setSelectedPost(post);
    setFormData({
      postName: post.postName,
      connectorType: post.connectorType,
      maxPowerKw: post.maxPowerKw,
      vehicleTypeSupported: post.vehicleTypeSupported,
      totalConnectors: post.totalConnectors,
    });
    setMode("edit");
  };

  // Thêm hoặc cập nhật trụ
  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!selectedStation) return toast.warn(" Vui lòng chọn trạm trước!");

    try {
      if (selectedPost) {
        await updateChargingPost(selectedPost.id, {
          ...formData,
          stationId: selectedStation.id,
        });
        toast.success("Cập nhật trụ thành công!");
      } else {
        await addChargingPost({
          ...formData,
          stationId: selectedStation.id,
        });
        toast.success("Thêm trụ mới thành công!");
      }

      setFormData({
        postName: "",
        connectorType: "",
        maxPowerKw: "",
        vehicleTypeSupported: 0,
        totalConnectors: "",
      });
      setSelectedPost(null);
      loadPosts(selectedStation.id);
      onUpdated?.();
    } catch (err) {
        console.error("Lỗi submit:", err);
        // Nếu BE có phản hồi lỗi rõ ràng
        const beMessage =
          err.response?.data?.message ||
          err.response?.data?.error ||
          err.message ||
          "Đã xảy ra lỗi không xác định!";

        toast.error(beMessage);
      
    }
  };

const handleDelete = async (id) => {
  if (window.confirm("Bạn chắc chắn muốn xóa trụ này?")) {
    try {
      await deleteChargingPost(id);
      toast.success(" Xóa trụ thành công!");

      // Xóa ngay trong danh sách FE (tránh hiển thị cũ)
      setPosts((prev) => prev.filter((p) => String(p.id) !== String(id)));

      // Sau đó gọi lại loadPosts để đồng bộ (nếu có API trả đúng)
      if (selectedStation?.id) await loadPosts(selectedStation.id);

      onUpdated?.();
    } catch (err) {
      console.error(" Lỗi xóa:", err);
      toast.error("Xóa thất bại!");
    }
  }
};




  //  Đổi trạng thái
  const handleChangeStatus = async (post, newStatusString) => {
    try {
      const numericStatus = statusMap[newStatusString];
      await updateChargingPostStatus(post.id, numericStatus);
      toast.success(" Cập nhật trạng thái thành công!");
      loadPosts(selectedStation?.id);
      onUpdated?.();
    } catch (err) {
      console.error("Lỗi đổi trạng thái:", err);
    }
    onUpdated?.();
  };

  return (
    <div className="post-popup-overlay">
      <div className="post-popup-box">
        {/* Sidebar */}
        <div className="post-popup-sidebar">
          {/* <button onClick={() => setMode("add")}>Thêm trụ</button> */}
          <button onClick={() => setMode("status")}>Trạng thái</button>
          <button onClick={() => setMode("edit")}>Cập nhật</button>
          <button onClick={() => setMode("delete")}>Xóa</button>
          {/* <button onClick={() => setMode("status")}>Trạng thái</button> */}
          <button className="close-btn" onClick={onClose}>
            Đóng
          </button>
        </div>

        {/* Content */}
        <div className="post-popup-content">
          <h3>Quản lý trụ sạc</h3>

          {/* Dropdown chọn trạm */}
          <label>Tìm trạm:</label>
          <div className="station-search-box">
            <input
              type="text"
              placeholder="Nhập tên, địa chỉ hoặc tỉnh..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              onFocus={() => setShowDropdown(true)}    // Mở dropdown khi click
              onBlur={() => setTimeout(() => setShowDropdown(false), 150)} // Ẩn khi rời focus
              className="station-search-input"
            />

            {showDropdown && (
              <div className="station-dropdown">
                {filteredStations.length > 0 ? (
                  filteredStations.map((st) => (
                    <div
                      key={st.id}
                      className="station-dropdown-item"
                      onMouseDown={() => {
                        handleSelectStation(st.id);
                        setSearchTerm(st.stationName);
                        setShowDropdown(false);
                      }}
                    >
                      {st.stationName} ({st.province})
                    </div>
                  ))
                ) : (
                  <div className="station-dropdown empty">Không tìm thấy trạm</div>
                )}
              </div>
            )}
          </div>


          {selectedStation && (
            <h4>
              Đang thao tác tại: <b>{selectedStation.stationName}</b> (
              {selectedStation.province})
            </h4>
          )}

          {!selectedStation && (
            <p className="warning-text">
               Vui lòng chọn trạm để hiển thị danh sách trụ!
            </p>
          )}

          {/* Khi có trạm */}
          {selectedStation && (
            <>
              {/*  Danh sách trụ tổng quan */}
              {showPostList && (
                <div className="post-popup-list" ref={listRef}>
                  <h4>Danh sách trụ của trạm</h4>
                  {posts.length === 0 ? (
                    <p>Không có trụ nào.</p>
                  ) : (
                    posts.map((p) => (
                      <div key={p.id} className="post-popup-item">
                        <span>
                          {p.postName} - {p.connectorType} ({p.vehicleTypeSupported}) |{" "}
                          Trạng thái: <b>{statusLabel[p.status] || p.status}</b>
                        </span>
                      </div>
                    ))
                  )}
                </div>
              )}

              {/* Form thêm/sửa */}
              {(mode === "add" || (mode === "edit" && selectedPost)) && (
                <form onSubmit={handleSubmit} className="post-popup-form">
                  <label>
                    Tên trụ:
                    <input
                      type="text"
                      value={formData.postName}
                      onChange={(e) =>
                        setFormData({ ...formData, postName: e.target.value })
                      }
                      required
                    />
                  </label>

                  <label>
                    Loại đầu nối:
                    <input
                      type="text"
                      value={formData.connectorType}
                      onChange={(e) =>
                        setFormData({
                          ...formData,
                          connectorType: e.target.value,
                        })
                      }
                      required
                    />
                  </label>

                  <label>
                    Công suất tối đa (kW):
                    <input
                      type="number"
                      min="1"
                      value={formData.maxPowerKw || ""}
                      onChange={(e) =>
                        setFormData({
                          ...formData,
                          maxPowerKw: e.target.value,
                        })
                      }
                      required
                    />
                  </label>

                  <label>
                    Loại xe hỗ trợ:
                    <select
                      value={formData.vehicleTypeSupported}
                      onChange={(e) =>
                        setFormData({
                          ...formData,
                          vehicleTypeSupported:  Number(e.target.value),
                        })
                      }
                    >
                      <option value="0">Bike</option>
                      <option value="1">Car</option>
                    </select>
                  </label>

                  <label>
                    Số đầu sạc:
                    <input
                      type="number"
                      min="1"
                      value={formData.totalConnectors || ""}
                      onChange={(e) =>
                        setFormData({
                          ...formData,
                          totalConnectors: e.target.value,
                        })
                      }
                      required
                    />
                  </label>

                  <button type="submit">
                    {selectedPost ? "Lưu cập nhật" : "Thêm mới"}
                  </button>
                </form>
              )}

              {/* Danh sách update */}
              {mode === "edit" && !selectedPost && (
                <div className="post-popup-list">
                  <h4>Danh sách trụ thuộc trạm</h4>
                  {posts.length === 0 && <p>Không có trụ nào.</p>}
                  {posts.map((p) => (
                    <div key={p.id} className="post-popup-item">
                      <span>
                        {p.postName} - {p.connectorType} ({p.maxPowerKw} kW)
                      </span>
                      <button onClick={() => handleSelectPost(p)}>Chọn sửa</button>
                    </div>
                  ))}
                </div>
              )}

              {/* Xóa */}
              {mode === "delete" && (
                <div className="post-popup-list">
                  <h4>Danh sách trụ để xóa</h4>
                  {posts.length === 0 && <p>Không có trụ nào.</p>}
                  {posts.map((p) => (
                    <div key={p.id} className="post-popup-item">
                      <span>
                        {p.postName} ({p.connectorType})
                      </span>
                      <button onClick={() => handleDelete(p.id)}>Xóa</button>
                    </div>
                  ))}
                </div>
              )}

              {/* Trạng thái */}
              {mode === "status" && (
                <div className="post-popup-list">
                  <h4>Trạng thái các trụ sạc</h4>
                  {posts.length === 0 && <p>Không có trụ nào.</p>}
                    {posts.map((p) => (
                    <div key={p.id} className="post-popup-item">
                      <span>{p.postName}</span>
                      <select
                        value={p.status || "InActive"}  
                        onChange={(e) => handleChangeStatus(p, e.target.value)}
                      >
                        <option value="InActive">Ngưng Hoạt Động</option>
                        <option value="Available">Sẳn Sàng</option>
                        <option value="Maintained">Bảo Trì</option>
                      </select>
                      <span className="status-label">
                        {statusLabel[p.status] || p.status}
                      </span>
                    </div>
                  ))}
                </div>
              )}
            </>
          )}

        </div>
      </div>
    </div>
  );
};

export default ChargingPost;
