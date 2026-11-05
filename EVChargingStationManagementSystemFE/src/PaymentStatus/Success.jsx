import React from "react";
import successAnim from "../components/animation/Check Mark - Success.json";
import Lottie from "lottie-react";
import { Button } from "antd";
import { useNavigate } from "react-router-dom";

export default function SuccessPage() {
    const navigate = useNavigate();

    return (
        <div style={{
            minHeight: "100vh",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            padding: 24,
            boxSizing: "border-box"
        }}>
            <div style={{
                width: "100%",
                maxWidth: 560,
                textAlign: "center",
                background: "white",
                borderRadius: 12,
                padding: 28,
                boxShadow: "0 10px 30px rgba(0,0,0,0.08)"
            }}>
                <div style={{ marginBottom: 8 }}>
                    <Lottie animationData={successAnim} loop={false} style={{ width: 180, height: 180, margin: "0 auto" }} />
                </div>

                <h2 style={{ margin: "12px 0 6px", color: "#052021" }}>Thanh toán thành công</h2>
                <p style={{ margin: 0, color: "#475569" }}>Cảm ơn bạn — giao dịch đã được xử lý thành công.</p>

                <div style={{ marginTop: 20, display: "flex", gap: 12, justifyContent: "center" }}>
                    <Button type="primary" onClick={() => navigate("/")}>Về trang chủ</Button>
                    <Button onClick={() => {
                        try { sessionStorage.setItem('payment.paid', 'true'); } catch {}
                        const returnPath = (() => { try { return sessionStorage.getItem('payment.returnPath'); } catch { return null; } })();
                        if (returnPath) navigate(returnPath); else navigate(-1);
                    }}>Quay lại phiên sạc</Button>
                </div>
            </div>
        </div>
    );
}