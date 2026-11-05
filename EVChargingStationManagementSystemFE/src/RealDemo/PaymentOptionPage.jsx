import { useState, useEffect, useRef } from "react";
import { useParams, useNavigate, useLocation } from "react-router-dom";
import { ArrowRight, CheckCircle, CreditCard, Store, Receipt, Copy, Check, RefreshCw, QrCode } from "lucide-react";
import "../components/Payment/PaymentPage.css";
import { Modal, Select, Divider, Card, Row, Col, message, Button, Spin, Tag } from "antd";
import { PostPaymentOffline, PostPaymentSePay, GetSessionPayment } from "../API/Payment";
import { GetAdminVouchers } from "../API/Voucher";

const { Option } = Select;

const PaymentOptionPage = () => {
    const { sessionId } = useParams();
    const navigate = useNavigate();
    const location = useLocation();
    const [selected, setSelected] = useState('online'); // default to online SePay
    const [loading, setLoading] = useState(false);
    const [paymentId, setPaymentId] = useState(null);
    const [amount, setAmount] = useState(0);
    const [showPopup, setShowPopup] = useState(false);

    // SePay states
    const [showSePayModal, setShowSePayModal] = useState(false);
    const [sePayData, setSePayData] = useState(null);
    const [sePayChecking, setSePayChecking] = useState(false);
    const [sePayPaid, setSePayPaid] = useState(false);
    const [copiedField, setCopiedField] = useState(null);
    const pollingTimerRef = useRef(null);

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

        fetchVouchers();

        return () => {
            if (pollingTimerRef.current) clearInterval(pollingTimerRef.current);
        };
    }, [location.state]);

    const fetchVouchers = async () => {
        try {
            const response = await GetAdminVouchers();
            const allVouchers = response?.data || [];
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

    // Kiểm tra trạng thái SePay
    const checkPaymentStatus = async (silent = false) => {
        if (!sessionId) return;
        if (!silent) setSePayChecking(true);
        try {
            const resp = await GetSessionPayment(sessionId);
            const data = resp?.data;
            if (data?.sessionStatus === "Paid" || data?.payment?.status === "Successed") {
                setSePayPaid(true);
                try { sessionStorage.setItem('payment.paid', 'true'); } catch { }
                if (pollingTimerRef.current) {
                    clearInterval(pollingTimerRef.current);
                    pollingTimerRef.current = null;
                }
                message.success("Thanh toán SePay thành công! Phiên sạc đã hoàn tất.");
            } else if (!silent) {
                message.info("Chưa nhận được giao dịch. Vui lòng kiểm tra lại sau ít giây.");
            }
        } catch (err) {
            if (!silent) message.error("Lỗi khi kiểm tra trạng thái thanh toán");
        } finally {
            if (!silent) setSePayChecking(false);
        }
    };

    const copyToClipboard = (text, field) => {
        navigator.clipboard.writeText(String(text));
        setCopiedField(field);
        message.success(`Đã sao chép ${field}!`);
        setTimeout(() => setCopiedField(null), 2000);
    };

    const handleNext = async () => {
        if (!selected) return;
        if (!sessionId) {
            message.error("Không tìm thấy sessionId");
            return;
        }
        setLoading(true);
        try {
            if (selected === 'online') {
                // Thanh toán qua SePay Test Mode
                const resp = await PostPaymentSePay(sessionId);
                const paymentInfo = resp?.data;
                if (paymentInfo) {
                    setSePayData(paymentInfo);
                    setSePayPaid(paymentInfo.status === "Successed");
                    setShowSePayModal(true);
                    message.success("Tạo yêu cầu thanh toán SePay thành công!");

                    // Bắt đầu tự động kiểm tra mỗi 3s
                    if (pollingTimerRef.current) clearInterval(pollingTimerRef.current);
                    pollingTimerRef.current = setInterval(() => {
                        checkPaymentStatus(true);
                    }, 3000);
                } else {
                    message.error("Không thể tạo yêu cầu thanh toán SePay");
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
            const errMsg = e?.response?.data?.message || "Có lỗi khi xử lý thanh toán";
            message.error(errMsg);
        } finally {
            setLoading(false);
        }
    };

    const handleReturnToSession = () => {
        try { sessionStorage.setItem('payment.paid', 'true'); } catch { }
        const returnPath = sessionStorage.getItem('payment.returnPath');
        if (returnPath) navigate(returnPath);
        else navigate(-1);
    };

    const sepayAmount = sePayData?.amount || finalAmount;
    const sepayTxnRef = sePayData?.transactionCode || sePayData?.txnRef || `EV${sessionId?.substring(0, 8)?.toUpperCase()}`;
    const qrUrl = `https://qr.sepay.vn/img?acc=0000000001&bank=Vietcombank&amount=${sepayAmount}&des=${encodeURIComponent(sepayTxnRef)}`;

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
                            <span style={{ fontSize: '16px', fontWeight: '500' }}>Tạm tính:</span>
                            <span style={{ fontSize: '16px', fontWeight: '600' }}>{amount.toLocaleString()} VNĐ</span>
                        </div>
                    </div>

                    {/* Voucher Selection */}
                    <div style={{ marginBottom: '16px' }}>
                        <div style={{ marginBottom: '8px', fontWeight: '500' }}>Mã giảm giá:</div>
                        <Select
                            placeholder="Chọn voucher"
                            style={{ width: '100%' }}
                            allowClear
                            onChange={handleVoucherChange}
                            value={selectedVoucher?.id}
                        >
                            {vouchers.map(v => (
                                <Option key={v.id} value={v.id}>
                                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                                        <span>{v.code} - {v.title}</span>
                                        <Tag color="green">-{v.value?.toLocaleString()} VNĐ</Tag>
                                    </div>
                                </Option>
                            ))}
                        </Select>
                    </div>

                    {selectedVoucher && (
                        <div style={{ background: '#f6ffed', padding: '12px', borderRadius: '8px', border: '1px solid #b7eb8f' }}>
                            <div style={{ display: 'flex', justifyContent: 'space-between', color: '#52c41a' }}>
                                <span>Giảm giá:</span>
                                <span>-{discount.toLocaleString()} VNĐ</span>
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
                <p>Hỗ trợ thanh toán Chuyển khoản VietQR (SePay) hoặc Tiền mặt tại quầy</p>

                {/* Hai lựa chọn lớn */}
                <div className="method-grid">
                    <div
                        className={`method-card ${selected === 'online' ? 'selected' : ''}`}
                        onClick={() => setSelected('online')}
                    >
                        <div className="method-header">
                            <CreditCard className="w-6 h-6 text-green-600" />
                            <div className="method-title">
                                <h4>Thanh toán Chuyển khoản (SePay / VietQR)</h4>
                                <p>Quét mã VietQR chuyển khoản nhanh, tự động xác nhận</p>
                            </div>
                        </div>
                        <ul className="benefit-list">
                            <li>✔ Quét mã VietQR chuyển khoản ngân hàng</li>
                            <li>✔ SePay tự động xác nhận sau vài giây</li>
                            <li>✔ Cổng sạc tự động mở khóa ngay</li>
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
                            <li>✔ Nhân viên trạm thu tiền trực tiếp</li>
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
                        💡 Gợi ý: Chọn <b>Thanh toán Chuyển khoản (SePay)</b> để quét mã VietQR trên ứng dụng ngân hàng và được hệ thống xác nhận tự động.
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

            {/* Modal Thanh toán SePay VietQR */}
            <Modal
                open={showSePayModal}
                onCancel={() => {
                    setShowSePayModal(false);
                    if (pollingTimerRef.current) clearInterval(pollingTimerRef.current);
                }}
                footer={null}
                centered
                width={520}
            >
                <div style={{ textAlign: "center", padding: "10px 10px 20px" }}>
                    {!sePayPaid ? (
                        <>
                            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, marginBottom: 16 }}>
                                <QrCode size={26} color="#00b09b" />
                                <h2 style={{ margin: 0, fontSize: 20, fontWeight: 700, color: "#1f2937" }}>
                                    Quét mã VietQR (SePay)
                                </h2>
                            </div>

                            <p style={{ color: "#6b7280", fontSize: 14, marginBottom: 16 }}>
                                Mở app Ngân hàng để quét mã QR hoặc chuyển khoản đúng thông tin bên dưới:
                            </p>

                            {/* QR Code Image */}
                            <div style={{ display: 'inline-block', padding: 8, background: '#fff', borderRadius: 12, border: '2px dashed #00b09b', marginBottom: 16 }}>
                                <img
                                    src={qrUrl}
                                    alt="VietQR SePay"
                                    style={{ width: 220, height: 220, display: 'block', borderRadius: 8 }}
                                    onError={(e) => {
                                        // Fallback if image load fails
                                        e.target.style.display = 'none';
                                    }}
                                />
                            </div>

                            {/* Thông tin chuyển khoản chi tiết */}
                            <div style={{ background: '#f9fafb', borderRadius: 12, padding: '14px 18px', textAlign: 'left', marginBottom: 16, border: '1px solid #e5e7eb' }}>
                                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
                                    <span style={{ color: '#6b7280', fontSize: 13 }}>Ngân hàng:</span>
                                    <span style={{ fontWeight: 600, color: '#111827' }}>Vietcombank (VCB)</span>
                                </div>
                                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
                                    <span style={{ color: '#6b7280', fontSize: 13 }}>Chủ tài khoản:</span>
                                    <span style={{ fontWeight: 600, color: '#111827' }}>HO KINH DOANH TEST 65C2</span>
                                </div>
                                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
                                    <span style={{ color: '#6b7280', fontSize: 13 }}>Số tài khoản:</span>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                                        <span style={{ fontWeight: 700, color: '#00b09b', fontSize: 15 }}>0000000001</span>
                                        <Button
                                            type="text"
                                            size="small"
                                            icon={copiedField === 'stk' ? <Check size={14} color="green" /> : <Copy size={14} />}
                                            onClick={() => copyToClipboard('0000000001', 'stk')}
                                        />
                                    </div>
                                </div>
                                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
                                    <span style={{ color: '#6b7280', fontSize: 13 }}>Số tiền:</span>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                                        <span style={{ fontWeight: 700, color: '#ef4444', fontSize: 16 }}>{sepayAmount.toLocaleString()} VNĐ</span>
                                        <Button
                                            type="text"
                                            size="small"
                                            icon={copiedField === 'amount' ? <Check size={14} color="green" /> : <Copy size={14} />}
                                            onClick={() => copyToClipboard(sepayAmount, 'amount')}
                                        />
                                    </div>
                                </div>
                                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                    <span style={{ color: '#6b7280', fontSize: 13 }}>Nội dung CK:</span>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                                        <span style={{ fontWeight: 700, color: '#2563eb', fontSize: 15, background: '#eff6ff', padding: '2px 8px', borderRadius: 4 }}>
                                            {sepayTxnRef}
                                        </span>
                                        <Button
                                            type="text"
                                            size="small"
                                            icon={copiedField === 'code' ? <Check size={14} color="green" /> : <Copy size={14} />}
                                            onClick={() => copyToClipboard(sepayTxnRef, 'code')}
                                        />
                                    </div>
                                </div>
                            </div>

                            <div style={{ background: '#fffbeb', border: '1px solid #fde68a', borderRadius: 8, padding: '8px 12px', fontSize: 12, color: '#92400e', textAlign: 'left', marginBottom: 16 }}>
                                ⚠️ <b>Lưu ý quan trọng:</b> Hãy chuyển đúng <b>Số tiền</b> và <b>Nội dung chuyển khoản</b> trên để SePay tự động khớp giao dịch ngay lập tức.
                            </div>

                            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, marginBottom: 16, color: '#6b7280', fontSize: 13 }}>
                                <Spin size="small" />
                                <span>Đang chờ chuyển khoản... Tự động kiểm tra mỗi 3s</span>
                            </div>

                            <div style={{ display: 'flex', gap: 10, justifyContent: 'center' }}>
                                <Button
                                    icon={<RefreshCw size={14} className={sePayChecking ? "animate-spin" : ""} />}
                                    loading={sePayChecking}
                                    onClick={() => checkPaymentStatus(false)}
                                >
                                    Kiểm tra trạng thái
                                </Button>
                                <Button
                                    type="primary"
                                    style={{ background: '#00b09b', borderColor: '#00b09b' }}
                                    onClick={handleReturnToSession}
                                >
                                    Đã chuyển khoản xong
                                </Button>
                            </div>
                        </>
                    ) : (
                        <div style={{ padding: "20px 0" }}>
                            <CheckCircle size={60} color="#10b981" style={{ margin: "0 auto 16px" }} />
                            <h2 style={{ color: "#10b981", fontSize: 22, fontWeight: 700, marginBottom: 8 }}>
                                Thanh toán SePay Thành Công!
                            </h2>
                            <p style={{ color: "#4b5563", fontSize: 14, marginBottom: 20 }}>
                                Máy chủ đã xác nhận giao dịch. Trụ sạc đã được mở khóa, bạn có thể quay lại để rút súng sạc.
                            </p>
                            <Button
                                type="primary"
                                size="large"
                                style={{ background: '#00b09b', borderColor: '#00b09b', height: 44, padding: '0 24px', fontWeight: 600 }}
                                onClick={handleReturnToSession}
                            >
                                Quay lại phiên sạc
                            </Button>
                        </div>
                    )}
                </div>
            </Modal>

            {/* Hiển thị kết quả offline */}
            <Modal
                open={showPopup}
                onCancel={() => setShowPopup(false)}
                footer={null}
                centered
            >
                <div style={{ textAlign: "center", padding: 20 }}>
                    <CheckCircle size={50} color="green" />
                    <h2 style={{ marginTop: 10, color: "#28a745", fontSize: "22px", fontWeight: 600, lineHeight: 1.5, textAlign: "center", }}>
                        Yêu Cầu Thanh Toán Của Bạn Đã Được Ghi Nhận!<br />
                    </h2>
                    <div style={{ fontSize: "14px", fontWeight: 600 }}>Hoàn thành tại quầy</div>
                    <Button
                        type="primary"
                        style={{ marginTop: 20 }}
                        onClick={() => navigate("/")}
                    >
                        Về Trang Chủ
                    </Button>
                    <Button onClick={handleReturnToSession}>Quay lại phiên sạc</Button>

                    {paymentId && (
                        <p style={{ marginTop: 10 }}>Mã thanh toán: <b>{paymentId}</b></p>
                    )}
                </div>
            </Modal>
        </div>
    );
};

export default PaymentOptionPage;
