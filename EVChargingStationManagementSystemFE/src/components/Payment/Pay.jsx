import React, { useState } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import { ArrowLeft, CreditCard, Package } from "lucide-react";
import "./Pay.css";

export default function Pay() {
  const navigate = useNavigate();
  const location = useLocation();
  const selectedMethod = location.state?.selected || 1;

  const [paymentMethod, setPaymentMethod] = useState("card");
  const [form, setForm] = useState({
    cardNumber: "",
    expiry: "",
    cvv: "",
    name: "",
  });

  const handleChange = (e) => {
    setForm({ ...form, [e.target.name]: e.target.value });
  };

  const handlePay = () => {
    alert("Thanh toán thành công!");
    navigate("/driver-dashboard");
  };

  // Danh sách phương thức
  const method = [
    {
      id: 1,
      icon: <CreditCard className="w-6 h-6 text-green-600" />,
      title: "Thanh toán theo lượt",
      price: "xx.xxx VNĐ / lượt",
      benefits: [
        "Linh hoạt, chỉ trả khi sử dụng",
        "Không ràng buộc thời gian",
        "Phù hợp cho người dùng ít",
      ],
    },
    {
      id: 2,
      icon: <Package className="w-6 h-6 text-green-600" />,
      title: "Sử dụng gói thuê hiện tại",
      price: "Gói Cao Cấp – Còn 29 lần",
      benefits: [
        "Không cần thanh toán thêm",
        "Đã được mua sẵn",
        "Tiện lợi khi đổi pin",
      ],
    },
  ];

  const chosen = method.find((m) => m.id === selectedMethod);

  return (
    <div className="pay-page">
      {/* Header */}
      <div className="payment-header">
        <h1>Thanh toán dịch vụ đổi pin</h1>
        <p>Chọn phương thức thanh toán phù hợp với nhu cầu của bạn</p>
      </div>

      {/* Stepper */}
      <div className="steps">
        <div className="step done">
          <div className="circle">✔</div>
          <div className="info">
            <h4>Chọn phương thức</h4>
            <p>Đã chọn xong</p>
          </div>
        </div>
        <div className="divider active"></div>
        <div className="step active">
          <div className="circle">2</div>
          <div className="info">
            <h4>Thanh toán</h4>
            <p>Hoàn tất thanh toán</p>
          </div>
        </div>
      </div>

      {/* Payment Box */}
        <div className="pay-box">
          <h3>Thông tin thanh toán</h3>

          {/* Box chứa gói đã chọn */}
          <div className="payment-summary">
            <div className="summary-header">
              <div className="summary-icon">{chosen.icon}</div>
              <div className="summary-info">
                <h4>{chosen.title}</h4>
                <p className="price">{chosen.price}</p>
              </div>
            </div>

            <ul className="summary-benefits">
              {chosen.benefits.map((b, i) => (
                <li key={i}>✔ {b}</li>
              ))}
            </ul>
          </div>

          {/* Phương thức thanh toán */}
          <div className="method-section">
            <h4>Phương thức thanh toán</h4>
            <div className="method-options">
              {["card", "momo", "zalopay"].map((type) => (
                <div
                  key={type}
                  className={`method ${paymentMethod === type ? "selected" : ""}`}
                  onClick={() => setPaymentMethod(type)}
                >
                  <input type="radio" checked={paymentMethod === type} readOnly />
                  <label>
                    {type === "card"
                      ? "Thẻ tín dụng/ghi nợ"
                      : type === "momo"
                      ? "Ví MoMo"
                      : "ZaloPay"}
                  </label>
                </div>
              ))}
            </div>
          </div>

          {/* Form nhập thẻ */}
          {paymentMethod === "card" && (
            <div className="card-form">
              <label>Số thẻ</label>
              <input
                type="text"
                name="cardNumber"
                placeholder="1234 5678 9012 3456"
                value={form.cardNumber}
                onChange={handleChange}
              />
              <div className="row2">
                <div>
                  <label>Ngày hết hạn</label>
                  <input
                    type="text"
                    name="expiry"
                    placeholder="MM/YY"
                    value={form.expiry}
                    onChange={handleChange}
                  />
                </div>
                <div>
                  <label>CVV</label>
                  <input
                    type="text"
                    name="cvv"
                    placeholder="123"
                    value={form.cvv}
                    onChange={handleChange}
                  />
                </div>
              </div>
              <label>Tên chủ thẻ</label>
              <input
                type="text"
                name="name"
                placeholder="NGUYEN VAN A"
                value={form.name}
                onChange={handleChange}
              />
            </div>
          )}

          {/* Buttons */}
          <button className="pay-btn" onClick={handlePay}>
            {selectedMethod === 1
              ? "Thanh toán 50.000 VNĐ"
              : "Xác nhận sử dụng gói thuê"}
          </button>

          <button className="back-btn" onClick={() => navigate(-1)}>
            <ArrowLeft size={16} /> Quay lại
          </button>
        </div>


      {/* Support */}
      <div className="support-section">
        <h3>Cần hỗ trợ?</h3>
        <div className="support-grid">
          <div>
            <h4>Hotline</h4>
            <p>1900 1234</p>
          </div>
          <div>
            <h4>Email</h4>
            <p>support@evbattery.com</p>
          </div>
          <div>
            <h4>Chat</h4>
            <p>Hỗ trợ trực tuyến</p>
          </div>
        </div>
      </div>
    </div>
  );
}
