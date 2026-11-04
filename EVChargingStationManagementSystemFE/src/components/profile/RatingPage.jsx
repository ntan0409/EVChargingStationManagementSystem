// RatingPage.jsx
import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { ToastContainer, toast } from "react-toastify";
import { addFeedBack } from "../../API/FeedBack";
import "react-toastify/dist/ReactToastify.css";
import "./RatingPage.css";

const RatingPage = () => {
  const navigate = useNavigate();
  const [rating, setRating] = useState(0);
  const [hoverRating, setHoverRating] = useState(0);
  const [subject, setSubject] = useState("");
  const [message, setMessage] = useState("");

  const handleSubmit = async (e) => {
    e.preventDefault();

    // Validate dữ liệu trước khi gửi
    if (!subject.trim()) {
      toast.error("Vui lòng nhập chủ đề đánh giá!");
      return;
    }

    if (!message.trim()) {
      toast.error("Vui lòng nhập nội dung nhận xét!");
      return;
    }

    if (rating < 1 || rating > 5) {
      toast.error("Vui lòng chọn số sao hợp lệ!");
      return;
    }

    try {
      await addFeedBack(subject.trim(), rating, message.trim());
      toast.success("✅ Cảm ơn đánh giá của bạn!");
      // reset form
      setRating(0);
      setHoverRating(0);
      setSubject("");
      setMessage("");
      setTimeout(() => {
        navigate("/profile-page");
      }, 1500);
    } catch (error) {
      console.log("Error sending feedback:", error);
      toast.error("Gửi đánh giá thất bại! Vui lòng thử lại.");
    }
  };

  const handleGoBack = () => {
    navigate("/profile-page");
  };

  return (
    <div className="rating-page">
      <div className="rating-header">
        <h1>🌟 Đánh giá dịch vụ</h1>
        <p>Hãy cho chúng tôi biết trải nghiệm của bạn</p>
      </div>

      <div className="rating-cards">
        <div className="rating-card">
          <h3>Chọn số sao</h3>
          <div className="stars">
            {[1, 2, 3, 4, 5].map((star) => (
              <span
                key={star}
                className={star <= (hoverRating || rating) ? "active" : ""}
                onClick={() => setRating(star)}
                onMouseEnter={() => setHoverRating(star)}
                onMouseLeave={() => setHoverRating(0)}
              >
                ★
              </span>
            ))}
          </div>
          <h3>Chủ đề đánh giá</h3>
          <input
            type="text"
            placeholder="Nhập chủ đề..."
            value={subject}
            onChange={(e) => setSubject(e.target.value)}
          />

          <h3>Nhận xét</h3>
          <textarea
            placeholder="Nhập nhận xét..."
            value={message}
            onChange={(e) => setMessage(e.target.value)}
          />

          <button className="submit-btn" onClick={handleSubmit}>
            Gửi đánh giá
          </button>
          <button className="back-btn" onClick={handleGoBack}>
            Quay lại
          </button>
        </div>
      </div>

      <ToastContainer position="top-right" />
    </div>
  );
};

export default RatingPage;
