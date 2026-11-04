import React, { useEffect, useState } from "react";
import { getStationBooking } from "../../API/Booking";
import { getEVDriverId } from "../../API/EVDriver";
import "./BookingOrder.css";

const BookingOrder = () => {
  const [bookings, setBookings] = useState([]);
  const [loading, setLoading] = useState(false);
  const [filterStatus, setFilterStatus] = useState("All");
  const [search, setSearch] = useState("");

  useEffect(() => {
    fetchBookings();
  }, []);
  const statusVietnamese = {
    Scheduled: "Đã lên lịch",
    Charging: "Đang sạc",
    Completed: "Hoàn thành",
    Cancelled: "Đã hủy",
  };

  const fetchBookings = async () => {
    setLoading(true);
    try {
      const res = await getStationBooking();
      let data = res.data || [];

      // Gọi song song API lấy thông tin driver cho từng booking
      const bookingsWithDriver = await Promise.all(
        data.map(async (b) => {
          if (b.bookedBy) {
            try {
              const driverInfo = await getEVDriverId(b.bookedBy);
              return { ...b, driverInfo };
            } catch {
              return { ...b, driverInfo: null };
            }
          }
          return { ...b, driverInfo: null };
        })
      );

      setBookings(bookingsWithDriver);
    } catch (error) {
      console.error("Không thể tải danh sách booking:", error);
    } finally {
      setLoading(false);
    }
  };

  const filteredBookings = bookings.filter((b) => {
    const matchStatus =
      filterStatus === "All" || b.status === filterStatus;
    const matchSearch =
      search === "" ||
      b.stationName?.toLowerCase().includes(search.toLowerCase()) ||
      b.driverInfo?.name?.toLowerCase().includes(search.toLowerCase()) ||
      b.checkInCode?.toLowerCase().includes(search.toLowerCase());
    return matchStatus && matchSearch;
  });

  return (
    <div className="booking-container">
      <h2 className="booking-title">📘 Quản Lý Đặt Lịch Sạc</h2>

      <div className="booking-filter">
        <input
          type="text"
          placeholder="🔍 Tìm kiếm theo trạm, tài xế, hoặc mã check-in..."
          className="booking-search"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
        <select
          className="booking-select"
          value={filterStatus}
          onChange={(e) => setFilterStatus(e.target.value)}
        >
          <option value="All">Tất cả</option>
          <option value="Scheduled">Đã lên lịch</option>
          <option value="Charging">Đang Sạc</option>
          <option value="Completed">Hoàn Thành</option>
          <option value="Cancelled">Đã Hủy</option>
        </select>
      </div>

      <div className="booking-card">
        {loading ? (
          <p className="loading-text">Đang tải dữ liệu...</p>
        ) : (
          <table className="booking-table">
            <thead>
              <tr>
                <th>STT</th>
                <th>Mã Check-in</th>
                <th>Trạm sạc</th>
                <th>Vị trí</th>
                <th>Thời gian bắt đầu</th>
                <th>Thời gian kết thúc</th>
                <th>Trạng thái</th>
                <th>Tài xế</th>
                <th>Email</th>
              </tr>
            </thead>
            <tbody>
              {filteredBookings.length === 0 ? (
                <tr>
                  <td colSpan="9" className="no-booking">
                    Không có lích đặt sạc nào phù hợp.
                  </td>
                </tr>
              ) : (
                filteredBookings.map((b, index) => (
                  <tr key={b.id}>
                    <td>{index + 1}</td>
                    <td>{b.checkInCode}</td>
                    <td>{b.stationName || "N/A"}</td>
                    <td>{b.location || "N/A"}</td>
                    <td>
                      {b.startTime
                        ? new Date(b.startTime).toLocaleString()
                        : "N/A"}
                    </td>
                    <td>
                      {b.endTime
                        ? new Date(b.endTime).toLocaleString()
                        : "N/A"}
                    </td>
                    <td>
                      <span
                        className={`booking-status status-${b.status?.toLowerCase()}`}
                      >
                       {statusVietnamese[b.status] || b.status}
                      </span>
                    </td>
                    <td>{b.driverInfo?.name || b.driverName || "Không rõ"}</td>
                    <td>{b.driverInfo?.email || b.driverEmail || "N/A"}</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
};

export default BookingOrder;
