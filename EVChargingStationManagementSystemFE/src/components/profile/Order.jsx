import React, { useEffect, useState } from "react";
import "./Order.css";
import { toast ,ToastContainer} from "react-toastify";
import { MyBooking,AutoCancel } from "../../API/Booking"; //  API lấy lịch sử đặt trạm

const Order = () => {
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");

  useEffect(() => {
    const fetchOrders = async () => {
      try {
        const res = await MyBooking();
        if (res?.data) {
          setOrders(res.data);
        } else {
          setOrders([]);
        }
      } catch (err) {
        console.error("Lỗi khi lấy đơn đặt lịch:", err);
        setOrders([]);
      } finally {
        setLoading(false);
      }
    };

    fetchOrders();
  }, []);

  if (loading) return <p>Đang tải...</p>;

  const filteredOrders = orders.filter(
    (o) =>
      o.stationName?.toLowerCase().includes(search.toLowerCase()) ||
      o.startTime?.toLowerCase().includes(search.toLowerCase()) ||
      o.endTime?.toLowerCase().includes(search.toLowerCase())
  );
const handleCancel = async (orderId) => {
  try {
    await AutoCancel(orderId); // gọi API PATCH cancel
    toast.success("Hủy đặt lịch thành công!");
    setOrders((prev) =>
      prev.map((o) =>
        o.id === orderId ? { ...o, status: "Cancelled" } : o
      )
    );
  } catch (err) {
    console.error(err);

    // Trích message từ response
    const message =
      err?.response?.data?.message || // thường có message từ BE
      err?.message ||                  // fallback
      "Hủy thất bại!";

    // Nếu backend trả lỗi 409
    if (err?.response?.status === 409) {
      toast.warning(message);
    } else {
      toast.error(message);
    }
  }
};



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
    
    <div className="order-history-container">
      <ToastContainer position="top-right" autoClose={3000} />
      <div className="order-history-content">
        <div className="order-history-topbar">
          <h2>Lịch sử Đặt Lịch Sạc</h2>
          <input
            type="text"
            placeholder="Tìm kiếm trạm hoặc thời gian..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>

        <div className="order-history-list">
          {filteredOrders.length === 0 ? (
            <p>Không có đơn đặt lịch nào.</p>
          ) : (
            filteredOrders.map((order) => (
              <div className="order-history-card" key={order.id}>
                <div className="order-history-id">{order.stationName}</div>
                <div className="order-history-info">
                  <p>
                    <strong>Mã Check-in :</strong> {order.checkInCode}
                  </p>
                  <p>
                    <strong>Thời Gian Bắt đầu:</strong> {formatDateTime(order.startTime)}
                  </p>
                  <p>
                    <strong>Thời Gian Kết thúc:</strong> {formatDateTime(order.endTime)}
                  </p>
                  
                  <p>
                    <strong>Trạng thái:</strong>{" "}
                    {order.status === "Scheduled" && <span className={"scheduled"}>Chờ Hoàn Thành </span>}
                    {order.status === "Completed" && <span className={"completed"}>Đã Hoàn Thành</span>}
                    {order.status === "InProgress" && <span className={"inprogress"}>Đang trong quá trình xử lý</span>}
                    {order.status === "Cancelled" && <span className={"cancelled"}>Yêu Cầu Đặt Lịch Sạc Của Bạn Đã Hủy Hợp Lệ </span>}
                    {order.status === "CancelledInvalid" && <span className={"cancelled"}>Hủy Đặt Chổ Ko Hợp Lệ </span>}
                    {order.status === "CompensatedCancelled" && <span className={"cancelled"}>Hủy Đặt Lịch Có Bồi Thường </span>}
                    {order.status === "AutoCancelled" && <span className={"cancelled"}>Đơn Đặt Lịch Tự Động Hủy</span>}
                    {order.status === "Waiting" && <span className={"inprogress"}>Chờ Đơn Đặt Lịch Sạc</span>}
                    {order.status === "Rejected" && <span className={"icancelled"}>Từ Chối Đặt Chổ </span>}
                  </p>
                  {order.status === "Scheduled" && (
                    <button
                      className="link-btn"
                      onClick={() => handleCancel(order.id)} // <-- dùng arrow function
                    >
                      Hủy Đặt Lịch
                    </button>
                  )}
                </div>
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  );
};

export default Order;
