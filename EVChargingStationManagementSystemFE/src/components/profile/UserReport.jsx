import React, { useState } from "react";
import { addReportByEVDriver } from "../../API/Report";
import "./UserReport.css";
import { useNavigate } from "react-router-dom";

const UserReport = ({ stations = []}) => {
  const [title, setTitle] = useState("");
  const [reportType, setReportType] = useState("");
  const [severity, setSeverity] = useState("");
  const [description, setDescription] = useState("");
  const [stationId, setStationId] = useState("");
  const [loading, setLoading] = useState(false);
  const [successMessage, setSuccessMessage] = useState("");
  const [errorMessage, setErrorMessage] = useState("");
  const navigate = useNavigate(); 

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setSuccessMessage("");
    setErrorMessage("");

    try {
      await addReportByEVDriver(title, reportType, severity, description);
      setSuccessMessage("Gửi báo cáo thành công!");
      setTitle("");
      setReportType("");
      setSeverity("");
      setDescription("");
      setStationId("");
    } catch (error) {
      setErrorMessage("Có lỗi xảy ra khi gửi báo cáo. Vui lòng thử lại.");
    } finally {
      setLoading(false);
    }
  };
  const handleGoBack = () => {
    navigate("/profile-page"); // đổi về trang mong muốn
  };

  return (
    <div className="report-page">
      <div className="page-header">
        <h1>Báo cáo sự cố</h1>
        <p>Gửi thông tin sự cố tại trạm sạc để chúng tôi xử lý nhanh chóng.</p>
      </div>

      <div className="form-container">
        {successMessage && <p className="success-message">{successMessage}</p>}
        {errorMessage && <p className="error-message">{errorMessage}</p>}

        <form onSubmit={handleSubmit}>
          

          <div className="form-group">
            <label>Tiêu đề</label>
            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="Nhập tiêu đề báo cáo"
              required
            />
          </div>

          <div className="form-group">
            <label>Loại báo cáo</label>
            <select
              value={reportType}
              onChange={(e) => setReportType(e.target.value)}
              required
            >
              <option value="">-- Chọn loại --</option>
              <option value="technical">Kỹ thuật</option>
              <option value="service">Dịch vụ</option>
              <option value="other">Khác</option>
            </select>
          </div>

          <div className="form-group">
            <label>Mức độ nghiêm trọng</label>
            <select
              value={severity}
              onChange={(e) => setSeverity(e.target.value)}
              required
            >
              <option value="">-- Chọn mức độ --</option>
              <option value="low">Thấp</option>
              <option value="medium">Trung bình</option>
              <option value="high">Cao</option>
            </select>
          </div>

          <div className="form-group">
            <label>Mô tả</label>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Mô tả chi tiết sự cố..."
              required
            />
          </div>

          <button type="submit" className="submit-btn" disabled={loading}>
            {loading ? "Đang gửi..." : "Gửi báo cáo"}
          </button>
        </form>

        
       {
          <button className="nav-buttonrollbackRP" onClick={handleGoBack}>
            Quay lại
          </button>
        }
      </div>
    </div>
  );
};

export default UserReport;
