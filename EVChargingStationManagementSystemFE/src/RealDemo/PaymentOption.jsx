import React, { useEffect, useState } from "react";
import { Button, message, Card, Space } from "antd";
import { useNavigate } from "react-router-dom";
import { PostPayment, PostPaymentOffline } from "../API/Payment";

const PaymentOption = ({ sessionId }) => {
    const [loading, setLoading] = useState(false);
    const [paymentId, setPaymentId] = useState(null);
    const navigate = useNavigate();

    useEffect(() => {
        // Đảm bảo lưu sessionId để các trang khác có thể dùng nếu cần
        if (sessionId) {
            try {
                sessionStorage.setItem('payment.sessionId', String(sessionId));
            } catch { }
        }
    }, [sessionId]);

    const handleOnlinePayment = async () => {
        setLoading(true);
        try {
            const resp = await PostPayment(sessionId);
            message.success(resp?.message || "Tạo url thanh toán thành công");
            const url = resp?.data;
            if (url) {
                window.location.href = url; // redirect sang VNPAY sandbox
            } else {
                message.error("Không tìm thấy URL thanh toán");
            }
        } catch (err) {
            message.error("Không thể tạo thanh toán online");
        } finally {
            setLoading(false);
        }
    };

    const handleOfflinePayment = async () => {
        setLoading(true);
        try {
            const resp = await PostPaymentOffline(sessionId);
            message.success(resp?.message || "Ghi nhận thanh toán offline thành công");
            const id = resp?.data?.id ?? resp?.data;
            console.log("Offline paymentId:", sessionId);
            if (id) {
                setPaymentId(id);
                try { sessionStorage.setItem('payment.paid', 'true'); } catch { }
            } else {
                message.warning("Không tìm thấy paymentId");
            }
        } catch (err) {
            message.error("Không thể ghi nhận thanh toán offline");
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="flex justify-center items-center min-h-screen bg-gradient-to-br from-pink-50 to-white">
            <Card className="w-full max-w-md rounded-2xl shadow-lg border border-pink-100" title="Chọn phương thức thanh toán">
                <Space direction="vertical" className="w-full">
                    <Button type="primary" loading={loading} onClick={handleOnlinePayment}>
                        Thanh toán Online (VNPAY)
                    </Button>
                    <Button onClick={handleOfflinePayment} loading={loading}>
                        Thanh toán Tiền mặt tại quầy
                    </Button>

                    {paymentId && (
                        <div className="mt-4">
                            <div className="text-gray-700">Mã thanh toán (offline): <b>{paymentId}</b></div>
                            <div className="mt-2">
                                <Button onClick={() => {
                                    const returnPath = sessionStorage.getItem('payment.returnPath');
                                    if (returnPath) {
                                        navigate(returnPath);
                                    } else {
                                        navigate(-1);
                                    }
                                }}>Quay lại phiên sạc</Button>
                            </div>
                        </div>
                    )}
                </Space>
            </Card>
        </div>
    );
};

export default PaymentOption;
