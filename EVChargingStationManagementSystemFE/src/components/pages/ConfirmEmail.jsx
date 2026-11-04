import { useState, useEffect, useRef } from "react";
import { useNavigate, useSearchParams, Link } from "react-router-dom";
import { confirmEmail } from "../../API/Auth";
import "./ConfirmEmail.css";

const ConfirmEmail = () => {
    const [searchParams] = useSearchParams();
    const navigate = useNavigate();
    const [message, setMessage] = useState("");
    const [loading, setLoading] = useState(true);
    const [isSuccess, setIsSuccess] = useState(false);
    const hasConfirmed = useRef(false); // ⚡ tránh gọi trùng API

    useEffect(() => {
        const urlUserId = searchParams.get("userId");
        const rawQuery = window.location.search.substring(1);
        const rawParams = Object.fromEntries(rawQuery.split("&").map(p => p.split("=")));
        const rawToken = rawParams.token;

        // ✅ Chỉ chạy 1 lần
        if (hasConfirmed.current) return;
        hasConfirmed.current = true;

        if (urlUserId && rawToken) {
            handleConfirmEmail(urlUserId, rawToken);
        } else {
            setMessage("Liên kết xác nhận email không hợp lệ hoặc đã hết hạn.");
            setIsSuccess(false);
            setLoading(false);
        }
    }, [searchParams]);

    const handleConfirmEmail = async (userId, token) => {
        console.log("Confirming email with:", userId, token);
        try {
            setLoading(true);
            const response = await confirmEmail(userId, token);
            console.log("Email confirmation response:", response);
            setMessage("🎉 Xác nhận email thành công! Bạn có thể đăng nhập ngay bây giờ.");
            setIsSuccess(true);

            setTimeout(() => navigate("/login"), 3000);
        } catch (error) {
            console.error("Error confirming email:", error);
            const data = error.response?.data;
            let serverMsg = "Đã xảy ra lỗi. Vui lòng thử lại.";

            if (data?.message) {
                serverMsg = data.message;
            } else if (data?.title) {
                serverMsg = data.title;
            } else if (error?.message) {
                serverMsg = error.message;
            }
            if (error.response?.status === 409) {
                serverMsg = "Email này đã được xác nhận trước đó.";
                setIsSuccess(true);
            }

            setMessage(serverMsg);
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="confirm-container">
            <div className="confirm-card">
                {loading ? (
                    <h2 className="confirm-loading">⏳ Đang xác nhận email...</h2>
                ) : (
                    <>
                        <h1 className={isSuccess ? "confirm-success" : "confirm-error"}>
                            {isSuccess ? "Thành công" : "Thất bại"}
                        </h1>
                        <p className="confirm-message">{message}</p>

                        <div style={{ marginTop: "20px" }}>
                            {isSuccess ? (
                                <Link to="/login" className="confirm-link">
                                    Đến trang đăng nhập
                                </Link>
                            ) : (
                                <Link to="/resend-confirmation" className="confirm-link">
                                    Gửi lại email xác nhận
                                </Link>
                            )}
                        </div>
                    </>
                )}
            </div>
        </div>
    );
};

export default ConfirmEmail;
