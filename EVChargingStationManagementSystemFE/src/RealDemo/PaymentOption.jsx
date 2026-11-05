import React, { useEffect, useState } from "react";
import { Button, message, Card, Space } from "antd";
import { useNavigate } from "react-router-dom";
import { PostPaymentOffline, PostPaymentSePay } from "../API/Payment";

const PaymentOption = ({ sessionId }) => {
    const [loading, setLoading] = useState(false);
    const [paymentId, setPaymentId] = useState(null);
    const navigate = useNavigate();

    useEffect(() => {
        if (sessionId) {
            try {
                sessionStorage.setItem('payment.sessionId', String(sessionId));
            } catch { }
        }
    }, [sessionId]);

    const handleOnlinePayment = () => {
        if (sessionId) {
            navigate(`/payment-method/${sessionId}`);
        }
    };

    const handleOfflinePayment = async () => {
        setLoading(true);
        try {
            const resp = await PostPaymentOffline(sessionId);
            message.success(resp?.message || "Ghi nhận thanh toán offline thành công");
            const id = resp?.data?.id ?? resp?.data;
            if (id) {
                setPaymentId(id);
                try { sessionStorage.removeItem('payment.paid'); } catch { }
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
                    <Button type="primary" loading={loading} onClick={handleOnlinePayment} style={{ background: '#00b09b', borderColor: '#00b09b' }}>
                        Thanh toán Chuyển khoản (SePay / VietQR)
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
