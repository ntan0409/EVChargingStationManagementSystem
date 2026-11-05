// AdminFeedBackContainer.jsx
import React, { useEffect, useState } from "react";
import { getFeedBack } from "../../../API/FeedBack"; // API feedback
import "./AdminReportContainer.css"; // dùng chung CSS với ReportAdmin

const PAGE_SIZE = 10;

const AdminFeedbackPage = () => {
  const [feedbacks, setFeedbacks] = useState([]);
  const [filteredFeedbacks, setFilteredFeedbacks] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [starFilter, setStarFilter] = useState("all"); // filter theo sao
  const [currentPage, setCurrentPage] = useState(1);

  useEffect(() => {
    const fetchFeedbacks = async () => {
      setLoading(true);
      try {
        const res = await getFeedBack();
        const data = Array.isArray(res) ? res : res.data || [];
        setFeedbacks(data);
        setFilteredFeedbacks(data);
      } catch (err) {
        console.error(err);
        setFeedbacks([]);
        setFilteredFeedbacks([]);
      } finally {
        setLoading(false);
      }
    };
    fetchFeedbacks();
  }, []);

  const removeVietnameseTones = (str) => {
    if (!str) return "";
    return str
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .replace(/đ/g, "d")
      .replace(/Đ/g, "D")
      .toLowerCase();
  };

  const applyFilters = () => {
    let data = [...feedbacks];

    // filter theo số sao
    if (starFilter !== "all") {
      data = data.filter((f) => f.stars === Number(starFilter));
    }

    // filter search
    if (search.trim() !== "") {
      const term = removeVietnameseTones(search);
      data = data.filter(
        (f) =>
          removeVietnameseTones(f.subject).includes(term) ||
          removeVietnameseTones(f.message).includes(term) ||
          f.stars?.toString().includes(term)
      );
    }

    setFilteredFeedbacks(data);
    setCurrentPage(1);
  };

  const handleSearchChange = (e) => {
    setSearch(e.target.value);
  };

  const handleStarFilterChange = (e) => {
    setStarFilter(e.target.value);
  };

  // tự động áp dụng filter khi search hoặc starFilter thay đổi
  useEffect(() => {
    applyFilters();
  }, [search, starFilter, feedbacks]);

  const totalPages = Math.ceil(
    Array.isArray(filteredFeedbacks) ? filteredFeedbacks.length / PAGE_SIZE : 0
  );

  const currentData = Array.isArray(filteredFeedbacks)
    ? filteredFeedbacks.slice(
        (currentPage - 1) * PAGE_SIZE,
        currentPage * PAGE_SIZE
      )
    : [];

  const goToPage = (page) => {
    if (page < 1 || page > totalPages) return;
    setCurrentPage(page);
  };

  if (loading) return <p>Đang tải danh sách feedback...</p>;

  return (
    <div className="booking-container">
      <h1 className="booking-title">Danh sách Feedback</h1>

      <div
        className="filter-container"
        style={{ display: "flex", gap: "16px", marginBottom: "16px" }}
      >
        <div>
          <label>Tìm kiếm:</label>
          <input
            type="text"
            placeholder="Tìm kiếm theo chủ đề, nội dung, số sao..."
            value={search}
            onChange={handleSearchChange}
            style={{ padding: "4px 8px" }}
          />
        </div>

        <div>
          <label>Lọc theo số sao:</label>
          <select value={starFilter} onChange={handleStarFilterChange}>
            <option value="all">Tất cả</option>
            <option value="1">1 sao</option>
            <option value="2">2 sao</option>
            <option value="3">3 sao</option>
            <option value="4">4 sao</option>
            <option value="5">5 sao</option>
          </select>
        </div>
      </div>

      <div className="booking-card">
        <table className="booking-table">
          <thead>
            <tr>
              <th>Chủ đề</th>
              <th>Số sao</th>
              <th>Nội dung</th>
              <th>Ngày tạo</th>
            </tr>
          </thead>
          <tbody>
            {currentData.length > 0 ? (
              currentData.map((fb, index) => (
                <tr key={fb.id || index}>
                  <td>{fb.subject || "-"}</td>
                  <td>{fb.stars || 0}</td>
                  <td>{fb.message || "-"}</td>
                  <td>
                    {fb.createdAt
                      ? new Date(fb.createdAt).toLocaleString()
                      : "-"}
                  </td>
                </tr>
              ))
            ) : (
              <tr>
                <td colSpan="4" style={{ textAlign: "center", padding: "16px" }}>
                  Không có feedback nào
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      <div className="pagination">
        {totalPages > 1 && (
          <div
            style={{
              marginTop: "16px",
              display: "flex",
              justifyContent: "center",
              gap: "8px",
            }}
          >
            <button onClick={() => goToPage(currentPage - 1)} disabled={currentPage === 1}>
              Prev
            </button>
            {Array.from({ length: totalPages }, (_, i) => (
              <button
                key={i + 1}
                onClick={() => goToPage(i + 1)}
                style={{ fontWeight: currentPage === i + 1 ? "bold" : "normal" }}
              >
                {i + 1}
              </button>
            ))}
            <button
              onClick={() => goToPage(currentPage + 1)}
              disabled={currentPage === totalPages}
            >
              Next
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

export default AdminFeedbackPage;
