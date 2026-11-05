import { useState, useEffect } from "react";
import { useParams, useNavigate, useLocation } from "react-router-dom";
import { ArrowRight, CheckCircle, CreditCard, Store, Tag, Receipt } from "lucide-react";
import "../components/Payment/PaymentPage.css";
import { Modal, Select, Divider, Card, Row, Col } from "antd";
import { message, Button } from "antd";
import { PostPayment, PostPaymentOffline } from "../API/Payment";
import { GetVoucher, GetAdminVouchers } from "../API/Voucher";

const { Option } = Select;

const PaymentOptionPage = () => {
    const { sessionId } = useParams();
    const navigate = useNavigate();
    const location = useLocation();
    const [selected, setSelected] = useState(null);
    const [loading, setLoading] = useState(false);
    const [paymentId, setPaymentId] = useState(null);
    const [amount, setAmount] = useState(0);
    const [showPopup, setShowPopup] = useState(false);

    // Voucher states
    const [vouchers, setVouchers] = useState([]);
    const [selectedVoucher, setSelectedVoucher] = useState(null);
    const [discount, setDiscount] = useState(0);

    // Invoice details
    const [invoiceDetails, setInvoiceDetails] = useState({
        energyDelivered: 0,
        pricePerKWh: 0,
        vatRate: 0,
        chargingTime: '00:00:00'
    });


    // Load dữ liệu từ location.state (được truyền từ Session.jsx)
    useEffect(() => {
        try {
            // Lấy data từ location.state
            const paymentData = location.state;

            if (paymentData) {
                const totalAmount = paymentData.totalCost || 0;
                const energy = paymentData.energyDelivered || 0;
                const price = paymentData.pricePerKWh || 0;
                const vat = paymentData.vatRate || 10;
                const time = paymentData.chargingTime || '00:00:00';

                setAmount(totalAmount);
                setInvoiceDetails({
                    energyDelivered: energy,
                    pricePerKWh: price,
                    vatRate: vat,
                    chargingTime: time
                });
            } else {
                // Fallback: thử lấy từ sessionStorage nếu không có location.state
                const storedAmount = parseFloat(sessionStorage.getItem('payment.amount') || 0);
                const storedEnergy = parseFloat(sessionStorage.getItem('payment.energy') || 0);
                const storedPrice = parseFloat(sessionStorage.getItem('payment.pricePerKWh') || 0);
                const storedVat = parseFloat(sessionStorage.getItem('payment.vatRate') || 10);
                const storedTime = sessionStorage.getItem('payment.chargingTime') || '00:00:00';

                setAmount(storedAmount);
                setInvoiceDetails({
                    energyDelivered: storedEnergy,
                    pricePerKWh: storedPrice,
                    vatRate: storedVat,
                    chargingTime: storedTime
                });
            }
        } catch (error) {
            console.error("Lỗi khi lấy thông tin thanh toán:", error);
            message.error("Không thể lấy thông tin thanh toán");
        }

        // Load vouchers
        fetchVouchers();
    }, [location.state]);

    const fetchVouchers = async () => {
        try {
            const response = await GetAdminVouchers();
            const allVouchers = response?.data || [];
            // Chỉ lấy voucher active và còn hiệu lực
            const activeVouchers = allVouchers.filter(v => {
                const now = new Date();
                const validFrom = new Date(v.validFrom);
                const validTo = new Date(v.validTo);
                return v.isActive && now >= validFrom && now <= validTo;
            });
            setVouchers(activeVouchers);
        } catch (error) {
            console.error("Lỗi khi tải voucher:", error);
        }
    };

    const handleVoucherChange = (voucherId) => {
        const voucher = vouchers.find(v => v.id === voucherId);
        if (voucher) {
            setSelectedVoucher(voucher);
            setDiscount(voucher.value);
        } else {
            setSelectedVoucher(null);
            setDiscount(0);
        }
    };

    const finalAmount = Math.max(0, amount - discount);


    const handleNext = async () => {
        if (!selected) return;
        if (!sessionId) {
            message.error("Không tìm thấy sessionId");
            return;
        }
        setLoading(true);
        try {
            if (selected === 'online') {
                const resp = await PostPayment(sessionId);
                const url = resp?.data;
                if (url) {
                    window.location.href = url;
                } else {
                    message.error("Không tìm thấy URL thanh toán");
                }
            } else if (selected === 'offline') {
                const resp = await PostPaymentOffline(sessionId);
                const id = resp?.data?.id ?? resp?.data;
                setShowPopup(true);
                if (id) {
                    setPaymentId(id);
                    try { sessionStorage.setItem('payment.paid', 'true'); } catch { }
                    message.success(resp?.message || "Ghi nhận thanh toán offline thành công");
                } else {
                    message.error("Không tìm thấy paymentId");
                }
            }
        } catch (e) {
            message.error("Có lỗi khi xử lý thanh toán");
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="payment-page">
            {/* Header */}
            <div className="payment-header">
                <h1>Thanh toán phiên sạc</h1>

                <p>Chọn phương thức thanh toán phù hợp cho phiên sạc hiện tại</p>
            </div>



            {/* Content */}
            <div className="payment-method-section">
                {/* Chi tiết hóa đơn */}
                <Card
                    title={
                        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                            <Receipt size={20} />
                            <span>Chi tiết hóa đơn</span>
                        </div>
                    }
                    style={{ marginBottom: '24px' }}
                >
                    <Row gutter={[16, 16]}>
                        <Col span={12}>
                            <div style={{ color: '#666' }}>Điện năng tiêu thụ:</div>
                            <div style={{ fontSize: '16px', fontWeight: '600' }}>
                                {invoiceDetails.energyDelivered.toFixed(2)} kWh
                            </div>
                        </Col>
                        <Col span={12}>
                            <div style={{ color: '#666' }}>Đơn giá:</div>
                            <div style={{ fontSize: '16px', fontWeight: '600' }}>
                                {invoiceDetails.pricePerKWh.toLocaleString()} VNĐ/kWh
                            </div>
                        </Col>
                        <Col span={12}>
                            <div style={{ color: '#666' }}>Thời gian sạc:</div>
                            <div style={{ fontSize: '16px', fontWeight: '600' }}>
                                {invoiceDetails.chargingTime}
                            </div>
                        </Col>
                        <Col span={12}>
                            <div style={{ color: '#666' }}>Thuế VAT:</div>
                            <div style={{ fontSize: '16px', fontWeight: '600' }}>
                                {invoiceDetails.vatRate}%
                            </div>
                        </Col>
                    </Row>

                    <Divider />

                    <div style={{ marginBottom: '16px' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
                            <span>Tiền điện:</span>
                            <span>{Math.round(invoiceDetails.energyDelivered * invoiceDetails.pricePerKWh).toLocaleString('vi-VN')} VNĐ</span>
                        </div>
                        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
                            <span>VAT ({invoiceDetails.vatRate}%):</span>
                            <span>{Math.round((invoiceDetails.energyDelivered * invoiceDetails.pricePerKWh) * (invoiceDetails.vatRate / 100)).toLocaleString('vi-VN')} VNĐ</span>
                        </div>
                        <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '18px', fontWeight: '600', color: '#00b09b' }}>
                            <span>Tổng cộng:</span>
                            <span>{Math.round(amount).toLocaleString('vi-VN')} VNĐ</span>
                        </div>
                    </div>
                </Card>

                {/* Chọn voucher */}
                <Card
                    title={
                        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                            <Tag size={20} />
                            <span>Áp dụng voucher</span>
                        </div>
                    }
                    style={{ marginBottom: '24px' }}
                >
                    <Select
                        placeholder="Chọn voucher giảm giá"
                        style={{ width: '100%', marginBottom: '16px' }}
                        onChange={handleVoucherChange}
                        allowClear
                        onClear={() => {
                            setSelectedVoucher(null);
                            setDiscount(0);
                        }}
                    >
                        {vouchers.map(voucher => (
                            <Option key={voucher.id} value={voucher.id}>
                                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                    <span>{voucher.name} - {voucher.description}</span>
                                    <span style={{ color: '#00b09b', fontWeight: '600' }}>
                                        -{voucher.value.toLocaleString()} VNĐ
                                    </span>
                                </div>
                            </Option>
                        ))}
                    </Select>

                    {selectedVoucher && (
                        <div style={{
                            padding: '12px',
                            background: '#e6f7f5',
                            borderRadius: '8px',
                            border: '1px solid #00b09b'
                        }}>
                            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
                                <span>Giảm giá:</span>
                                <span style={{ color: '#00b09b', fontWeight: '600' }}>
                                    -{discount.toLocaleString()} VNĐ
                                </span>
                            </div>
                            <Divider style={{ margin: '8px 0' }} />
                            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '20px', fontWeight: '700', color: '#00b09b' }}>
                                <span>Thành tiền:</span>
                                <span>{finalAmount.toLocaleString()} VNĐ</span>
                            </div>
                        </div>
                    )}

                    {!selectedVoucher && (
                        <div style={{ textAlign: 'center', color: '#666', fontSize: '14px' }}>
                            {vouchers.length > 0 ? 'Chọn voucher để được giảm giá' : 'Không có voucher khả dụng'}
                        </div>
                    )}
                </Card>

                <h3>Chọn phương thức thanh toán</h3>
                <p>Hỗ trợ thanh toán Online (VNPAY) hoặc Offline tại quầy</p>

                {/* Hai lựa chọn lớn */}
                <div className="method-grid">
                    <div
                        className={`method-card ${selected === 'online' ? 'selected' : ''}`}
                        onClick={() => setSelected('online')}
                    >
                        <div className="method-header">
                            <CreditCard className="w-6 h-6 text-green-600" />
                            <div className="method-title">
                                <h4>Thanh toán Online (VNPAY)</h4>
                                <p>Nhanh chóng, nhận hoá đơn điện tử</p>
                            </div>
                        </div>
                        <ul className="benefit-list">
                            <li>✔ Thanh toán an toàn</li>
                            <li>✔ Xác nhận ngay lập tức</li>
                            <li>✔ Tiện lợi mọi lúc</li>
                        </ul>
                        {selected === 'online' && (
                            <div className="selected-badge">
                                <CheckCircle className="w-5 h-5 text-green-600" />
                            </div>
                        )}
                    </div>

                    <div
                        className={`method-card ${selected === 'offline' ? 'selected' : ''}`}
                        onClick={() => setSelected('offline')}
                    >
                        <div className="method-header">
                            <Store className="w-6 h-6 text-green-600" />
                            <div className="method-title">
                                <h4>Thanh toán Offline tại quầy</h4>
                                <p>Thuận tiện tại điểm sạc</p>
                            </div>
                        </div>
                        <ul className="benefit-list">
                            <li>✔ Dễ dàng, quen thuộc</li>
                            <li>✔ Phù hợp khi không dùng VNPAY</li>
                            <li>✔ Hỗ trợ tại chỗ</li>
                        </ul>
                        {selected === 'offline' && (
                            <div className="selected-badge">
                                <CheckCircle className="w-5 h-5 text-green-600" />
                            </div>
                        )}
                    </div>
                </div>

                <div className="hint-box">
                    <p>
                        💡 Gợi ý: Nếu bạn cần hoá đơn điện tử, hãy chọn <b>Thanh toán Online</b>.
                        Nếu thuận tiện tại điểm sạc, có thể chọn <b>Thanh toán Offline</b>.
                    </p>
                </div>

                {/* Navigation */}
                <div className="nav-buttons">
                    <div></div>
                    <button className={`next-btn ${!selected || loading ? 'disabled' : ''}`} disabled={!selected || loading} onClick={handleNext}>
                        {loading ? 'Đang xử lý...' : 'Tiếp tục'} <ArrowRight className="icon" />
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

            {/* Hiển thị kết quả offline */}
            <Modal
                open={showPopup}
                onCancel={() => setShowPopup(false)}
                footer={null}
                centered
            >
                <div style={{ textAlign: "center", padding: 20 }}>
                    <CheckCircle size={50} color="green" />
                    <h2 style={{ marginTop: 10, color: "#28a745", fontSize: "22px", fontWeight: 600, lineHeight: 1.5, textAlign: "center", }}>Yêu Cầu Thanh Toán Của Bạn Đã Được Ghi Nhận!<br /> </h2>
                    <div style={{ fontSize: "14px", fontWeight: 600 }}>Hoàn thành tại quầy</div>
                    <Button
                        type="primary"
                        style={{ marginTop: 20 }}
                        onClick={() => navigate("/")}
                    >
                        Về Trang Chủ
                    </Button>
                    <Button onClick={() => {
                        try { sessionStorage.setItem('payment.paid', 'true'); } catch { }
                        const returnPath = (() => { try { return sessionStorage.getItem('payment.returnPath'); } catch { return null; } })();
                        if (returnPath) navigate(returnPath); else navigate(-1);
                    }}>Quay lại phiên sạc</Button>


                    {paymentId && (
                        <p style={{ marginTop: 10 }}>Mã thanh toán: <b>{paymentId}</b></p>
                    )}


                </div>
            </Modal>


        </div>
    );
};

export default PaymentOptionPage;


