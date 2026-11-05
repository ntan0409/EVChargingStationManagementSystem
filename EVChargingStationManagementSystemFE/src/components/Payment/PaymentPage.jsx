import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { CheckCircle, ArrowRight, ArrowLeft, CreditCard, Package } from "lucide-react";
import "./PaymentPage.css";

export default function PaymentPage() {
  const navigate = useNavigate();
  const [selected, setSelected] = useState(null);

  const methods = [
    {
      id: 1,
      icon: <CreditCard className="w-6 h-6 text-green-600" />,
      title: "Thanh toán theo lượt",
      price: "Mỗi lần sạc: xxx.xxx VNĐ",
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
        "Linh hoạt, đã được mua",
        "Không cần thanh toán thêm",
        "Tiện lợi khi đổi pin",
      ],
    },
  ];

  const handleNext = () => {
    if (selected) navigate("/Pay", { state: { selected } });
  };

  return (
    <div className="payment-page">
      {/* Header */}
      <div className="payment-header">
        <h1>Thanh toán dịch vụ đặt sạc</h1>
        <p>Chọn phương thức thanh toán phù hợp với nhu cầu của bạn</p>
      </div>

      {/* Stepper */}
      <div className="steps">
        <div className="step active">
          <div className="circle">1</div>
          <div className="info">
            <h4>Chọn phương thức</h4>
            <p>Chọn cách thanh toán</p>
          </div>
        </div>
        <div className="divider active"></div>
        <div className="step">
          <div className="circle">2</div>
          <div className="info">
            <h4>Thanh toán</h4>
            <p>Hoàn tất thanh toán</p>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="payment-method-section">
        <h3>Chọn phương thức thanh toán</h3>
        <p>Chọn cách thanh toán phù hợp với cách bạn sử dụng dịch vụ</p>

        <div className="method-grid">
          {methods.map((m) => (
            <div
              key={m.id}
              className={`method-card ${selected === m.id ? "selected" : ""}`}
              onClick={() => setSelected(m.id)}
            >
              <div className="method-header">
                {m.icon}
                <div className="method-title">
                  <h4>{m.title}</h4>
                  <p>{m.price}</p>
                </div>
              </div>
              <ul className="benefit-list">
                {m.benefits.map((b, i) => (
                  <li key={i}>✔ {b}</li>
                ))}
              </ul>
              {selected === m.id && (
                <div className="selected-badge">
                  <CheckCircle className="w-5 h-5 text-green-600" />
                </div>
              )}
            </div>
          ))}
        </div>

        <div className="hint-box">
          <p>
            💡 Gợi ý: Nếu bạn đổi pin ít hơn 10 lần/tháng, hãy chọn{" "}
            <b>“Thanh toán theo lượt”</b>. Nếu đổi nhiều, gói dịch vụ sẽ tiết kiệm hơn.
          </p>
        </div>

        {/* Navigation */}
        <div className="nav-buttons">
          <button className="back-btn" disabled>
            <ArrowLeft className="icon" /> Quay lại
          </button>
          <button
            className={`next-btn ${!selected ? "disabled" : ""}`}
            onClick={handleNext}
            disabled={!selected}
          >
            Tiếp tục <ArrowRight className="icon" />
          </button>
        </div>
      </div>

      {/* Help Section */}
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
