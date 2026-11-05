import { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { Button, message, Card, Space, Progress, Row, Col, Divider, Modal, Input } from "antd";
import { toast } from "react-toastify";
import { StartSession, Stop } from "../API/ChargingSession";
import { getChargingPostId } from "../API/ChargingPost";
import { PatchConnectorToggle, GetConnectorId } from "../API/Connector";
import { GetVAT, GetPrice } from "../API/SystemConfiguration";
import { BookCheckin } from "../API/Booking";
import { PostPayment, GetSessionPayment } from "../API/Payment";

import {
    PlugZap,
    Power,
    StopCircle,
    Plug,
    CreditCard,
    Battery,
    Clock,
    Zap,
    Gauge,
    Banknote
} from "lucide-react";

const Session = () => {
    const [sessionId, setSessionId] = useState(() => {
        try {
            const savedConn = sessionStorage.getItem('payment.connectorId');
            if (savedConn && String(savedConn).toLowerCase() === String(connectorID).toLowerCase()) {
                return sessionStorage.getItem('payment.sessionId') || null;
            }
        } catch { }
        return null;
    });
    const [connectorStatus, setConnectorStatus] = useState("Available"); // Available, InUse, Charging, Faulted
    const [isCharging, setIsCharging] = useState(false);
    const [loading, setLoading] = useState(false);
    const [isPaid, setIsPaid] = useState(false);
    const [isPhoneModalVisible, setIsPhoneModalVisible] = useState(false);
    const [phoneNumber, setPhoneNumber] = useState("");
    const [bookingId, setBookingId] = useState(null);
    const [vehicleModelId, setVehicleModelId] = useState(null);
    const [showCheckinModal, setShowCheckinModal] = useState(false);
    const [otpValues, setOtpValues] = useState(["", "", "", ""]);
    const [otpError, setOtpError] = useState(false);
    const [chargingData, setChargingData] = useState({
        batteryLevel: 20,
        energyDelivered: 0,
        chargingPower: 0,
        estimatedTime: 0,
        cost: 0,
        startTime: null
    });
    const [pricingData, setPricingData] = useState({
        pricePerKWh: 0,
        vatRate: 0,
        maxPowerKw: 0,
        loading: true
    });
    const [connectorInfo, setConnectorInfo] = useState({
        id: null,
        name: null,
        type: null,
        maxPower: null
    });
    const [stationInfo, setStationInfo] = useState({
        name: "Trạm Sạc Xe Điện",
        address: "123 Đường ABC, Quận XYZ, TP.HCM",
        phone: "0123-456-789"
    });
    const [vehicleInfo, setVehicleInfo] = useState({
        model: "Tesla Model 3",
        licensePlate: "30A-12345",
        batteryCapacity: "75 kWh"
    });
    const [sessionInfo, setSessionInfo] = useState({
        startTime: null,
        endTime: null,
        duration: "00:00:00"
    });
    const [paymentInfo, setPaymentInfo] = useState({
        subtotal: 0,
        vat: 0,
        total: 0,
        vatRate: 10
    });
    const [timer, setTimer] = useState(0);
    const { connectorID } = useParams();
    const navigate = useNavigate();

    // Hàm tính toán thời gian sạc còn lại
    const calculateEstimatedTime = (currentBatteryLevel, maxPower) => {
        const batteryCapacityKWh = 80; // Pin xe 80kWh
        const currentBatteryKWh = (currentBatteryLevel / 100) * batteryCapacityKWh;
        const remainingCapacity = batteryCapacityKWh - currentBatteryKWh;
        return (remainingCapacity / maxPower) * 3600; // giây
    };


    useEffect(() => {
        // Nếu vừa thanh toán xong, bật quyền rút sạc rồi dọn state lưu tạm
        try {
            const paid = sessionStorage.getItem('payment.paid') === 'true';
            if (paid) {
                setIsPaid(true);
                message.success('Thanh toán thành công! Bạn có thể rút sạc.');
            }
        } catch { }
        return () => { };
    }, []);

    // Kiểm tra connector status khi component mount
    useEffect(() => {
        const checkConnectorStatus = async () => {
            try {
                const connectorResponse = await GetConnectorId(connectorID);
                const connectorData = connectorResponse?.data || connectorResponse;
                const status = connectorData?.status;

                // Lưu thông tin connector
                setConnectorInfo({
                    id: connectorData?.id || connectorID,
                    name: connectorData?.connectorName || `Connector ${connectorID}`,
                    type: connectorData?.type || "Type 2",
                    maxPower: connectorData?.maxPower || "22 kW"
                });

                if (status === "Reserved") {
                    setShowCheckinModal(true);
                }
            } catch (error) {
                toast.error("Không thể kiểm tra trạng thái connector");
            }
        };

        if (connectorID) {
            checkConnectorStatus();
        }
    }, [connectorID]);

    // Lấy giá điện và thuế VAT khi component mount
    useEffect(() => {
        const fetchPricingData = async () => {
            try {
                setPricingData(prev => ({ ...prev, loading: true }));

                // Bước 1: Lấy thông tin connector để có chargingPostId và status
                const connectorResponse = await GetConnectorId(connectorID);
                console.log("🔌 Thông tin connector:", connectorResponse);

                const connectorData = connectorResponse?.data || connectorResponse;
                const chargingPostId = connectorData?.chargingPostId;
                const status = connectorData?.status || "Available";

                // Cập nhật thông tin connector
                setConnectorInfo({
                    id: connectorData?.id || connectorID,
                    name: connectorData?.connectorName || `Connector ${connectorID}`,
                    type: connectorData?.type || "Type 2",
                    maxPower: connectorData?.maxPower || "22 kW"
                });

                // Cập nhật trạng thái connector
                setConnectorStatus(status);
                console.log("📊 Trạng thái connector:", status);

                // Bước 2: Lấy giá điện, VAT và thông tin trạm sạc song song
                const [priceResponse, vatResponse, chargingPostResponse] = await Promise.all([
                    GetPrice(),
                    GetVAT(),
                    chargingPostId ? getChargingPostId(chargingPostId) : Promise.resolve(null)
                ]);

                console.log("💰 Giá điện:", priceResponse);
                console.log("📊 VAT:", vatResponse);
                console.log("⚡ Thông tin trạm sạc:", chargingPostResponse);

                // Sửa lại cách parse dữ liệu dựa trên cấu trúc thực tế
                const pricePerKWh = parseFloat(priceResponse?.data?.minValue || priceResponse?.minValue || 0);
                const vatRate = parseFloat(vatResponse?.data?.minValue || vatResponse?.minValue || 0);
                const maxPowerKw = parseFloat(chargingPostResponse?.data?.maxPowerKw || chargingPostResponse?.maxPowerKw || 22);

                setPricingData({
                    pricePerKWh,
                    vatRate,
                    maxPowerKw,
                    loading: false
                });

                message.success(`Đã tải thông tin: Giá ${pricePerKWh.toLocaleString()} VNĐ/kWh, VAT ${vatRate}%, Công suất tối đa ${maxPowerKw}kW`);
            } catch (error) {
                console.error(" Lỗi khi lấy thông tin:", error);
                message.error("Không thể lấy thông tin hệ thống!");
                setPricingData(prev => ({ ...prev, loading: false }));
            }
        };

        fetchPricingData();
    }, [connectorID]);

    // Timer cho phiên sạc với tính toán chi phí thực tế
    useEffect(() => {
        let interval;
        if (isCharging && !pricingData.loading) {
            interval = setInterval(() => {
                setTimer(prev => prev + 1);
                // Mô phỏng dữ liệu sạc thực tế
                setChargingData(prev => {
                    // Sử dụng công suất tối đa thực tế từ API
                    const maxPower = pricingData.maxPowerKw || 22;
                    const powerVariation = maxPower * 0.1; // Dao động 10%
                    const newChargingPower = maxPower - powerVariation + Math.random() * (powerVariation * 2);
                    const newEnergyDelivered = prev.energyDelivered + (newChargingPower / 3600); // kWh/second

                    // Tính toán % pin thực tế dựa trên dung lượng pin
                    const batteryCapacityKWh = 80; // Pin xe 80kWh
                    const currentBatteryKWh = (prev.batteryLevel / 100) * batteryCapacityKWh; // kWh hiện tại
                    const newBatteryKWh = currentBatteryKWh + (newChargingPower / 3600); // Thêm năng lượng sạc được
                    const newBatteryPercent = Math.min(100, (newBatteryKWh / batteryCapacityKWh) * 100);

                    // Tính chi phí thực tế dựa trên API
                    const baseCost = newEnergyDelivered * pricingData.pricePerKWh;
                    const vatAmount = baseCost * (pricingData.vatRate / 100);
                    const totalCost = baseCost + vatAmount;

                    // Tính thời gian còn lại thực tế
                    const remainingCapacity = batteryCapacityKWh - newBatteryKWh; // kWh còn lại cần sạc
                    const estimatedTimeSeconds = (remainingCapacity / newChargingPower) * 3600; // giây

                    return {
                        ...prev,
                        batteryLevel: newBatteryPercent,
                        energyDelivered: newEnergyDelivered,
                        chargingPower: newChargingPower,
                        cost: totalCost,
                        estimatedTime: Math.max(0, estimatedTimeSeconds)
                    };
                });
            }, 1000);
        }
        return () => clearInterval(interval);
    }, [isCharging, pricingData]);

    // Tự động dừng sạc khi đạt 100%
    useEffect(() => {
        if (isCharging && chargingData.batteryLevel >= 100) {
            message.success("🎉 Pin đã đầy 100%! Phiên sạc đã tự động dừng.");
            handleStopSession();
        }
    }, [chargingData.batteryLevel, isCharging]);

    const handleCheckin = async () => {
        const checkinCode = otpValues.join("");

        if (checkinCode.length !== 4) {
            setOtpError(true);
            toast.error("Vui lòng nhập đủ 4 số!");
            setTimeout(() => setOtpError(false), 1000);
            return;
        }

        setOtpError(false);
        setLoading(true);

        try {
            const response = await BookCheckin(checkinCode);

            // Debug: Log toàn bộ response để xem cấu trúc
            console.log("🔍 Full BookCheckin response:", response);
            console.log("🔍 response.data:", response?.data);

            // Tự động import bookingId và phone từ response
            const checkinData = response?.data || response;
            console.log("🔍 checkinData:", checkinData);
            console.log("🔍 checkinData.bookingId:", checkinData?.bookingId);
            // console.log("🔍 checkinData.phone:", checkinData?.phone);
            // console.log("🔍 checkinData.phoneNumber:", checkinData?.phoneNumber);

            // Lấy thông tin từ response theo Swagger:
            // - id → bookingId
            // - phone → driverPhone
            // - vehicleModelId → vehicleModelId
            const bookingIdValue = checkinData?.id || checkinData?.bookingId;
            const driverPhone = checkinData?.phone || checkinData?.driverPhone;
            const vehicleModelIdValue = checkinData?.vehicleModelId;

            console.log("🔍 bookingIdValue (id):", bookingIdValue);
            console.log("🔍 phoneValue (phone):", driverPhone);
            console.log("🔍 vehicleModelIdValue:", vehicleModelIdValue);

            if (bookingIdValue) {
                setBookingId(bookingIdValue);
                toast.success(`✅ Check-in thành công! Booking ID: ${bookingIdValue}`);
            } else {
                toast.success("✅ Check-in thành công! Bạn có thể bắt đầu sạc.");
            }

            if (driverPhone) {
                setPhoneNumber(driverPhone);
                toast.info(`📱 Số điện thoại: ${driverPhone}`);
            }

            if (vehicleModelIdValue) {
                setVehicleModelId(vehicleModelIdValue);
                toast.info(`🚗 Thông tin xe đã được tự động điền`);
            }

            setShowCheckinModal(false);
            setOtpValues(["", "", "", ""]);

            const connectorResponse = await GetConnectorId(connectorID);
            const newStatus = connectorResponse?.data?.status || connectorResponse?.status;
            setConnectorStatus(newStatus);

        } catch (error) {
            setOtpError(true);
            const errorMsg = error.response?.data?.message || error.response?.data?.title || "Mã check-in không đúng!";
            toast.error(errorMsg);
            setTimeout(() => setOtpError(false), 1000);
        } finally {
            setLoading(false);
        }
    };

    const handlePlugToCar = async () => {
        // Kiểm tra status trước khi cắm - cho phép Available hoặc Preparing
        if (connectorStatus !== "Available" && connectorStatus !== "Preparing") {
            message.warning("⚠️ Connector không ở trạng thái sẵn sàng!");
            return;
        }

        setLoading(true);
        try {
            console.log("🔄 Cắm sạc vào xe - Toggle false (đang sử dụng):", connectorID);
            // toggle = false nghĩa là đang sử dụng (cắm vào xe)
            await PatchConnectorToggle(false, connectorID);
            setConnectorStatus("InUse");
            message.success(" Đã cắm sạc vào xe!");
        } catch (error) {
            console.error(" Lỗi khi cắm sạc:", error);
            message.error("Không thể cắm sạc!");
        } finally {
            setLoading(false);
        }
    };

    const handleStartSession = async () => {
        // Nếu đã có số điện thoại từ check-in, bỏ qua modal và bắt đầu luôn
        if (phoneNumber) {
            await handleConfirmPhone();
        } else {
            setIsPhoneModalVisible(true);
        }
    };

    const handleConfirmPhone = async () => {
        setLoading(true);
        try {
            const params = {
                connectorId: connectorID,
                batteryCapacityKWh: 80,
                initialBatteryLevelPercent: 20,
                expectedEnergiesKWh: 100
            };

            // Chỉ thêm phone nếu có giá trị
            if (phoneNumber?.trim()) {
                params.phone = phoneNumber.trim();
            }

            // Chỉ thêm bookingId nếu có giá trị
            if (bookingId) {
                params.bookingId = bookingId;
            }

            // Chỉ thêm vehicleModelId nếu có giá trị
            if (vehicleModelId) {
                params.vehicleModelId = vehicleModelId;
            }

            // Gọi API - truyền undefined cho các field không có
            const response = await StartSession(
                params.bookingId,
                params.batteryCapacityKWh,
                params.initialBatteryLevelPercent,
                params.expectedEnergiesKWh,
                params.phone,
                params.connectorId,
                params.vehicleModelId
            );


            const id = response?.data?.id || response?.id;
            if (id) setSessionId(id);

            // Cập nhật status sang Charging
            setConnectorStatus("Charging");

            setIsCharging(true);
            setTimer(0);
            setChargingData(prev => ({
                ...prev,
                startTime: new Date(),
                estimatedTime: calculateEstimatedTime(prev.batteryLevel, pricingData.maxPowerKw || 22),
                chargingPower: pricingData.maxPowerKw || 22,
                energyDelivered: 0,
                cost: 0
            }));

            if (bookingId) {
                toast.success(`✅ Phiên sạc đã bắt đầu! Booking ID: ${bookingId}`);
            } else {
                toast.success("✅ Phiên sạc đã bắt đầu!");
            }
        } catch (error) {
            const errorMsg = error?.response?.data?.message || error?.message || "Lỗi không xác định";
            toast.error(`Không thể bắt đầu phiên sạc: ${errorMsg}`);
        } finally {
            setLoading(false);
            setIsPhoneModalVisible(false);
            // Không reset phoneNumber để giữ lại cho lần sau
        }
    };

    // Xử lý khi người dùng nhấn "Không" trong modal
    const handleCancelPhone = async () => {
        setIsPhoneModalVisible(false);
        setPhoneNumber("");
        // Bắt đầu sạc bình thường - không truyền phone, bookingId, vehicleModelId
        setLoading(true);
        try {
            // Chỉ truyền các tham số bắt buộc, không truyền undefined cho các field optional
            const response = await StartSession(
                undefined, // bookingId
                80,        // batteryCapacityKWh
                20,        // initialBatteryLevelPercent
                100,       // expectedEnergiesKWh
                undefined, // phone - không gửi
                connectorID, // connectorId
                undefined  // vehicleModelId
            );

            const id = response?.data?.id || response?.id;
            if (id) setSessionId(id);

            // Cập nhật status sang Charging (chỉ local state vì API không hỗ trợ)
            setConnectorStatus("Charging");

            setIsCharging(true);
            setTimer(0);
            setChargingData(prev => ({
                ...prev,
                startTime: new Date(),
                estimatedTime: calculateEstimatedTime(prev.batteryLevel, pricingData.maxPowerKw || 22),
                chargingPower: pricingData.maxPowerKw || 22,
                energyDelivered: 0,
                cost: 0
            }));

            message.success("Phiên sạc đã bắt đầu!");
        } catch (error) {
            console.error("Lỗi khi bắt đầu phiên sạc:", error);
            message.error("Không thể bắt đầu phiên sạc!");
        } finally {
            setLoading(false);
        }
    };



    // Dừng phiên sạc
    const handleStopSession = async () => {
        setLoading(true);
        try {
            if (!sessionId) {
                message.warning("⚠️ Chưa có session để dừng!");
                return;
            }

            await Stop(sessionId, chargingData.energyDelivered);

            // Chuyển status về InUse (đã cắm nhưng không sạc) - chỉ local state
            setConnectorStatus("InUse");

            setIsCharging(false);
            message.success("🛑 Phiên sạc đã dừng! Vui lòng thanh toán trước khi rút sạc khỏi xe.");
        } catch (error) {
            console.error("❌ Lỗi khi dừng phiên sạc:", error);
            message.error("Lỗi khi dừng phiên sạc!");
        } finally {
            setLoading(false);
        }
    };

    const handlePayment = async () => {
        console.log("🔍 handlePayment - sessionId:", sessionId);

        if (!sessionId) {
            message.error("Không tìm thấy mã phiên sạc!");
            return;
        }
        try {
            message.info("Đang chuyển đến trang thanh toán...");

            // Lấy data từ state
            const totalCost = chargingData.cost || 0;
            const energyDelivered = chargingData.energyDelivered || 0;
            const pricePerKWh = pricingData.pricePerKWh || 0;
            const vatRate = pricingData.vatRate || 10;

            // Chuẩn bị data để truyền qua state
            const paymentData = {
                sessionId: sessionId,
                connectorId: connectorID,
                totalCost: totalCost,
                energyDelivered: energyDelivered,
                pricePerKWh: pricePerKWh,
                vatRate: vatRate,
                chargingTime: formatTime(timer),
                stationInfo: stationInfo,
                vehicleInfo: vehicleInfo,
                connectorInfo: connectorInfo
            };

            console.log("📦 Payment data:", paymentData);
            console.log("🔗 Navigate to:", `/payment-method/${sessionId}`);

            // Backup vào sessionStorage
            try {
                sessionStorage.setItem('payment.sessionId', String(sessionId));
                sessionStorage.setItem('payment.connectorId', String(connectorID));
                sessionStorage.setItem('payment.returnPath', window.location.pathname);
                sessionStorage.setItem('payment.amount', String(totalCost));
                sessionStorage.setItem('payment.energy', String(energyDelivered));
                sessionStorage.setItem('payment.pricePerKWh', String(pricePerKWh));
                sessionStorage.setItem('payment.vatRate', String(vatRate));
                sessionStorage.setItem('payment.chargingTime', formatTime(timer));
            } catch { }

            // Navigate đến trang chọn phương thức thanh toán
            navigate(`/payment-method/${sessionId}`, { state: paymentData });
        } catch (error) {
            console.error("Lỗi khi điều hướng:", error);
        }
    };


    const hasActiveOrUnpaidSession = Boolean(sessionId || timer > 0 || chargingData.energyDelivered > 0);
    const canUnplug = connectorStatus === "InUse" && !isCharging && (!hasActiveOrUnpaidSession || isPaid);

    // Rút sạc khỏi xe (sau khi thanh toán hoặc chưa sạc)
    const handleUnplugFromCar = async () => {
        if (!canUnplug) {
            message.warning("⚠️ Vui lòng hoàn tất thanh toán trước khi rút sạc khỏi xe!");
            return;
        }

        setLoading(true);
        try {
            console.log("🔄 Rút sạc khỏi xe - Toggle true (có sẵn):", connectorID);
            await PatchConnectorToggle(true, connectorID);
            setConnectorStatus("Available");
            setIsPaid(false);
            setSessionId(null);
            try {
                sessionStorage.removeItem('payment.paid');
                sessionStorage.removeItem('payment.sessionId');
                sessionStorage.removeItem('payment.amount');
                sessionStorage.removeItem('payment.energy');
                sessionStorage.removeItem('payment.connectorId');
            } catch { }
            message.success("🔋 Đã rút sạc khỏi xe!");
        } catch (error) {
            console.error("❌ Lỗi khi rút sạc:", error);
            message.error("Không thể rút sạc! Vui lòng kiểm tra trạng thái thanh toán.");
        } finally {
            setLoading(false);
        }
    };

    // Hàm format thời gian
    const formatTime = (seconds) => {
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        const secs = seconds % 60;
        return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    };

    return (
        <div className="min-h-screen bg-gradient-to-br from-green-50 via-white to-emerald-50 p-4 md:p-6">
            <style>{`
                @keyframes pulse-ring {
                    0% { box-shadow: 0 0 0 0 rgba(0, 176, 155, 0.7); }
                    70% { box-shadow: 0 0 0 10px rgba(0, 176, 155, 0); }
                    100% { box-shadow: 0 0 0 0 rgba(0, 176, 155, 0); }
                }
                .charging-pulse {
                    animation: pulse-ring 2s cubic-bezier(0.455, 0.03, 0.515, 0.955) infinite;
                }
            `}</style>
            <div className="max-w-7xl mx-auto">
                {/* Header - Simple */}
                <div className="text-center mb-6">
                    <h1 className="text-3xl font-bold text-gray-800 mb-2">
                        Phiên Sạc
                    </h1>
                    <div className="flex items-center justify-center gap-2">
                        <span className="text-gray-600">Súng sạc: </span>
                        <span className="font-bold text-gray-800">
                            {connectorInfo.name || `#${connectorID}`}
                        </span>
                    </div>
                </div>

                <Modal
                    title="Nhập số điện thoại để tích điểm"
                    open={isPhoneModalVisible}
                    onOk={handleConfirmPhone}
                    onCancel={handleCancelPhone}
                    okText="Xác nhận"
                    cancelText="Không"
                >
                    {phoneNumber ? (
                        <div style={{ marginBottom: '16px' }}>
                            <div style={{
                                padding: '12px',
                                backgroundColor: '#e6f7f5',
                                borderRadius: '8px',
                                border: '1px solid #00b09b',
                                marginBottom: '12px'
                            }}>
                                <p style={{ margin: 0, color: '#00b09b', fontWeight: '600' }}>
                                    ✅ Số điện thoại đã được tự động điền từ booking
                                </p>
                            </div>
                            <p style={{ marginBottom: '8px' }}>Số điện thoại của bạn:</p>
                        </div>
                    ) : (
                        <p style={{ marginBottom: '8px' }}>Bạn có muốn nhập số điện thoại để tích điểm không?</p>
                    )}
                    <Input
                        placeholder="Nhập số điện thoại"
                        value={phoneNumber}
                        onChange={(e) => setPhoneNumber(e.target.value)}
                        maxLength={10}
                        style={{
                            borderColor: phoneNumber ? '#00b09b' : undefined,
                            borderWidth: phoneNumber ? '2px' : '1px'
                        }}
                    />
                    {bookingId && (
                        <div style={{
                            marginTop: '12px',
                            padding: '8px',
                            backgroundColor: '#f3f4f6',
                            borderRadius: '6px',
                            fontSize: '12px',
                            color: '#6b7280'
                        }}>
                            📋 Booking ID: <strong>{bookingId}</strong>
                        </div>
                    )}
                </Modal>

                {/* Modal Check-in */}
                <Modal
                    title={<div style={{ textAlign: 'center', fontSize: '20px' }}>🎫 Nhập mã Check-in</div>}
                    open={showCheckinModal}
                    onOk={handleCheckin}
                    onCancel={() => {
                        // Nếu connector vẫn Reserved, đưa user về trang trước (danh sách connector)
                        if (connectorStatus === "Reserved") {
                            message.info("Quay về danh sách connector");
                            navigate(-1);
                        } else {
                            // Nếu không còn Reserved, chỉ đóng modal
                            setShowCheckinModal(false);
                            setOtpValues(["", "", "", ""]);
                        }
                    }}
                    okText="Xác nhận"
                    cancelText="Hủy"
                    okButtonProps={{ loading: loading }}
                    closable={true}
                    maskClosable={false}
                    centered
                    width={500}
                >
                    <div style={{ padding: '20px 0' }}>
                        <div style={{
                            padding: '20px',
                            backgroundColor: '#eff6ff',
                            borderRadius: '8px',
                            border: '1px solid #bfdbfe',
                            marginBottom: '30px',
                            textAlign: 'center'
                        }}>
                            <p style={{
                                color: '#1f2937',
                                marginBottom: '8px',
                                fontSize: '16px',
                                fontWeight: '600'
                            }}>
                                ⚠️ Connector đang được đặt trước
                            </p>
                            <p style={{
                                color: '#6b7280',
                                fontSize: '14px',
                                margin: 0
                            }}>
                                Vui lòng nhập mã check-in 4 số để xác nhận và bắt đầu sạc
                            </p>
                        </div>

                        <div>
                            <label style={{
                                display: 'block',
                                color: '#374151',
                                fontWeight: '600',
                                marginBottom: '20px',
                                textAlign: 'center',
                                fontSize: '16px'
                            }}>
                                Mã Check-in (4 số)
                            </label>
                            <div
                                style={{
                                    display: 'flex',
                                    justifyContent: 'center',
                                    gap: '12px',
                                    marginBottom: '20px',
                                    animation: otpError ? 'shake 0.5s' : 'none'
                                }}
                            >
                                <style>{`
                                    @keyframes shake {
                                        0%, 100% { transform: translateX(0); }
                                        10%, 30%, 50%, 70%, 90% { transform: translateX(-10px); }
                                        20%, 40%, 60%, 80% { transform: translateX(10px); }
                                    }
                                `}</style>
                                {otpValues.map((value, index) => (
                                    <Input
                                        key={index}
                                        id={`otp-${index}`}
                                        value={value}
                                        onChange={(e) => {
                                            const val = e.target.value.replace(/\D/g, '');
                                            if (val.length <= 1) {
                                                const newOtpValues = [...otpValues];
                                                newOtpValues[index] = val;
                                                setOtpValues(newOtpValues);
                                                setOtpError(false); // Reset error khi user nhập

                                                // Auto focus next input
                                                if (val && index < 3) {
                                                    document.getElementById(`otp-${index + 1}`)?.focus();
                                                }
                                            }
                                        }}
                                        onKeyDown={(e) => {
                                            // Backspace: focus previous input
                                            if (e.key === 'Backspace' && !value && index > 0) {
                                                document.getElementById(`otp-${index - 1}`)?.focus();
                                            }
                                        }}
                                        maxLength={1}
                                        style={{
                                            width: '70px',
                                            height: '70px',
                                            fontSize: '32px',
                                            textAlign: 'center',
                                            fontWeight: 'bold',
                                            borderRadius: '8px',
                                            border: otpError ? '2px solid #ef4444' : '2px solid #d1d5db',
                                            backgroundColor: otpError ? '#fee2e2' : 'white',
                                            transition: 'all 0.3s ease'
                                        }}
                                    />
                                ))}
                            </div>
                            {/* <p style={{
                                color: '#9ca3af',
                                fontSize: '12px',
                                textAlign: 'center',
                                margin: 0
                            }}>
                                Mã này được gửi qua email/SMS khi bạn đặt chỗ
                            </p> */}
                        </div>
                    </div>
                </Modal>

                <Row gutter={[16, 16]}>
                    {/* Cột trái - Thông tin sạc */}
                    <Col xs={24} lg={14}>
                        {/* Mức pin - Clean Card */}
                        <Card className="mb-5 shadow-xl border-0" style={{
                            borderRadius: '20px',
                            background: 'linear-gradient(180deg, #ffffff 0%, #f0fdf4 100%)'
                        }}>
                            <div className="text-center mb-4">
                                <div className="inline-flex items-center gap-3 mb-3">
                                    <div className="p-3 rounded-full" style={{
                                        background: 'linear-gradient(135deg, #e6f7f5, #d1fae5)'
                                    }}>
                                        <Battery size={32} style={{ color: '#00b09b' }} />
                                    </div>
                                    <h3 className="text-2xl font-bold m-0" style={{ color: '#1f2937' }}>
                                        Mức Pin
                                    </h3>
                                </div>
                            </div>
                            <div className="text-center mb-5">
                                <span
                                    className="font-bold"
                                    style={{
                                        fontSize: '72px',
                                        background: 'linear-gradient(135deg, #00b09b, #96c93d)',
                                        WebkitBackgroundClip: 'text',
                                        WebkitTextFillColor: 'transparent',
                                        backgroundClip: 'text'
                                    }}
                                >
                                    {chargingData.batteryLevel.toFixed(1)}
                                </span>
                                <span className="text-4xl font-semibold text-gray-400">%</span>
                            </div>
                            <Progress
                                percent={chargingData.batteryLevel.toFixed(1)}
                                strokeColor={{
                                    '0%': '#ef4444',
                                    '30%': '#f59e0b',
                                    '50%': '#00b09b',
                                    '100%': '#96c93d'
                                }}
                                strokeWidth={16}
                                status={isCharging ? 'active' : 'normal'}
                            />
                        </Card>

                        {/* Thống kê - Grid 2x2 Clean Cards */}
                        <Row gutter={[12, 12]} className="mb-5">
                            <Col xs={12}>
                                <Card className="shadow-lg border-0 hover:shadow-xl transition-all" style={{
                                    borderRadius: '16px',
                                    background: 'linear-gradient(135deg, #fef3c7 0%, #fde68a 100%)'
                                }}>
                                    <div className="text-center py-3">
                                        <Zap size={32} style={{ color: '#f59e0b' }} className="mx-auto mb-2" />
                                        <div className="text-3xl font-bold" style={{ color: '#92400e' }}>
                                            {chargingData.energyDelivered.toFixed(2)}
                                        </div>
                                        <div className="text-sm font-medium" style={{ color: '#78350f' }}>kWh đã sạc</div>
                                    </div>
                                </Card>
                            </Col>
                            <Col xs={12}>
                                <Card className="shadow-lg border-0 hover:shadow-xl transition-all" style={{
                                    borderRadius: '16px',
                                    background: 'linear-gradient(135deg, #dbeafe 0%, #bfdbfe 100%)'
                                }}>
                                    <div className="text-center py-3">
                                        <Gauge size={32} style={{ color: '#3b82f6' }} className="mx-auto mb-2" />
                                        <div className="text-3xl font-bold" style={{ color: '#1e3a8a' }}>
                                            {isCharging ? chargingData.chargingPower.toFixed(1) : '0.0'}
                                        </div>
                                        <div className="text-sm font-medium" style={{ color: '#1e40af' }}>kW công suất</div>
                                    </div>
                                </Card>
                            </Col>
                            <Col xs={12}>
                                <Card className="shadow-lg border-0 hover:shadow-xl transition-all" style={{
                                    borderRadius: '16px',
                                    background: 'linear-gradient(135deg, #e9d5ff 0%, #d8b4fe 100%)'
                                }}>
                                    <div className="text-center py-3">
                                        <Clock size={32} style={{ color: '#a855f7' }} className="mx-auto mb-2" />
                                        <div className="text-3xl font-bold" style={{ color: '#581c87' }}>
                                            {formatTime(timer)}
                                        </div>
                                        <div className="text-sm font-medium" style={{ color: '#6b21a8' }}>
                                            {isCharging && chargingData.estimatedTime > 0
                                                ? `Còn ${formatTime(Math.floor(chargingData.estimatedTime))}`
                                                : 'Thời gian sạc'}
                                        </div>
                                    </div>
                                </Card>
                            </Col>
                            <Col xs={12}>
                                <Card className="shadow-lg border-0 hover:shadow-xl transition-all" style={{
                                    borderRadius: '16px',
                                    background: 'linear-gradient(135deg, #d1fae5 0%, #a7f3d0 100%)'
                                }}>
                                    <div className="text-center py-3">
                                        <Banknote size={32} style={{ color: '#10b981' }} className="mx-auto mb-2" />
                                        <div className="text-3xl font-bold" style={{ color: '#064e3b' }}>
                                            {chargingData.cost.toLocaleString('vi-VN', { maximumFractionDigits: 0 })}
                                        </div>
                                        <div className="text-sm font-medium" style={{ color: '#065f46' }}>VNĐ</div>
                                    </div>
                                </Card>
                            </Col>
                        </Row>


                    </Col>

                    {/* Cột phải - Điều khiển Clean */}
                    <Col xs={24} lg={10}>
                        <Card className="shadow-2xl border-0 sticky top-4" style={{
                            borderRadius: '20px',
                            background: 'linear-gradient(180deg, #ffffff 0%, #f0fdf4 100%)'
                        }}>
                            <h3 className="text-xl font-bold mb-3 text-center" style={{ color: '#1f2937' }}>
                                🎮 Bảng Điều Khiển
                            </h3>

                            {/* Trạng thái Connector - Outlined Style */}
                            <div className="mb-4" style={{
                                height: '60px',
                                fontSize: '15px',
                                background: 'white',
                                borderWidth: '2px',
                                borderStyle: 'solid',
                                borderColor: connectorStatus === "Charging"
                                    ? '#00b09b'
                                    : connectorStatus === "InUse"
                                        ? '#10b981'
                                        : connectorStatus === "Available"
                                            ? '#d1d5db'
                                            : '#ef4444',
                                color: connectorStatus === "Charging"
                                    ? '#00b09b'
                                    : connectorStatus === "InUse"
                                        ? '#10b981'
                                        : connectorStatus === "Available"
                                            ? '#9ca3af'
                                            : '#ef4444',
                                borderRadius: '16px',
                                boxShadow: connectorStatus === "Charging"
                                    ? '0 4px 12px rgba(0, 176, 155, 0.2)'
                                    : connectorStatus === "InUse"
                                        ? '0 4px 12px rgba(16, 185, 129, 0.2)'
                                        : connectorStatus === "Available"
                                            ? 'none'
                                            : '0 4px 12px rgba(239, 68, 68, 0.2)',
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'center',
                                gap: '8px',
                                padding: '0 20px'
                            }}>
                                <span style={{ fontSize: '18px' }}>
                                    {connectorStatus === "Charging" && "⚡"}
                                    {connectorStatus === "InUse" && "🔌"}
                                    {connectorStatus === "Available" && "⏸️"}
                                    {connectorStatus === "Reserved" && "�"}
                                    {connectorStatus === "Preparing" && "🔄"}
                                    {connectorStatus !== "Charging" && connectorStatus !== "InUse" && connectorStatus !== "Available" && connectorStatus !== "Reserved" && connectorStatus !== "Preparing" && "⚠️"}
                                </span>
                                <span className="font-bold">
                                    {connectorStatus === "Charging" && "Đang sạc"}
                                    {connectorStatus === "InUse" && "Đã cắm - Sẵn sàng"}
                                    {connectorStatus === "Available" && "Chưa kết nối"}
                                    {connectorStatus === "Reserved" && "Đã đặt trước"}
                                    {connectorStatus === "Preparing" && "Sẵn sàng sạc"}
                                    {connectorStatus !== "Charging" && connectorStatus !== "InUse" && connectorStatus !== "Available" && connectorStatus !== "Reserved" && connectorStatus !== "Preparing" && connectorStatus}
                                </span>
                                {connectorStatus === "Charging" && (
                                    <div className="ml-2 px-3 py-1.5 rounded-full" style={{
                                    }}>
                                        <span className="font-bold text-white text-sm">{formatTime(timer)}</span>
                                    </div>
                                )}
                            </div>

                            <Row gutter={[12, 12]}>
                                {/* Nút cắm sạc */}
                                <Col span={24}>
                                    <Button
                                        size="large"
                                        onClick={handlePlugToCar}
                                        disabled={(connectorStatus !== "Available" && connectorStatus !== "Preparing") || loading}
                                        className="w-full font-bold hover:scale-105 transition-all"
                                        icon={<PlugZap size={20} />}
                                        style={{
                                            height: '60px',
                                            fontSize: '15px',
                                            width: '40%',
                                            background: 'white',
                                            borderWidth: '2px',
                                            borderStyle: 'solid',
                                            borderColor: (connectorStatus === "Available" || connectorStatus === "Preparing") && !loading ? '#00b09b' : '#d1d5db',
                                            color: (connectorStatus === "Available" || connectorStatus === "Preparing") && !loading ? '#00b09b' : '#9ca3af',
                                            borderRadius: '16px',
                                            boxShadow: (connectorStatus === "Available" || connectorStatus === "Preparing") && !loading
                                                ? '0 4px 12px rgba(0, 176, 155, 0.2)'
                                                : 'none',
                                            display: 'flex',
                                            alignItems: 'center',
                                            justifyContent: 'center',
                                            gap: '8px'
                                        }}
                                    >
                                        <span style={{ fontSize: '18px' }}>🔌</span>
                                        <span>Cắm sạc vào xe</span>
                                    </Button>
                                </Col>

                                {/* Nút bắt đầu phiên sạc */}
                                <Col span={24}>
                                    <Button
                                        size="large"
                                        onClick={handleStartSession}
                                        disabled={connectorStatus !== "InUse" || isCharging || loading || pricingData.loading || sessionId}
                                        className="w-full font-bold hover:scale-105 transition-all"
                                        icon={<Power size={20} />}
                                        style={{
                                            height: '60px',
                                            fontSize: '15px',
                                            width: '40%',
                                            background: 'white',
                                            borderWidth: '2px',
                                            borderStyle: 'solid',
                                            borderColor: connectorStatus === "InUse" && !isCharging && !loading && !pricingData.loading && !sessionId ? '#10b981' : '#d1d5db',
                                            color: connectorStatus === "InUse" && !isCharging && !loading && !pricingData.loading && !sessionId ? '#10b981' : '#9ca3af',
                                            borderRadius: '16px',
                                            boxShadow: connectorStatus === "InUse" && !isCharging && !loading && !pricingData.loading && !sessionId
                                                ? '0 4px 12px rgba(16, 185, 129, 0.2)'
                                                : 'none',
                                            display: 'flex',
                                            alignItems: 'center',
                                            justifyContent: 'center',
                                            gap: '8px'
                                        }}
                                    >
                                        <span style={{ fontSize: '18px' }}>⚡</span>
                                        <span>{pricingData.loading ? 'Đang tải...' : 'Bắt đầu sạc'}</span>
                                    </Button>
                                </Col>

                                {/* Nút dừng phiên sạc */}
                                <Col span={24}>
                                    <Button
                                        size="large"
                                        onClick={handleStopSession}
                                        disabled={connectorStatus !== "Charging" || loading}
                                        className="w-full font-bold hover:scale-105 transition-all"
                                        icon={<StopCircle size={20} />}
                                        style={{
                                            height: '60px',
                                            fontSize: '15px',
                                            width: '40%',
                                            background: 'white',
                                            borderWidth: '2px',
                                            borderStyle: 'solid',
                                            borderColor: connectorStatus === "Charging" && !loading ? '#ef4444' : '#d1d5db',
                                            color: connectorStatus === "Charging" && !loading ? '#ef4444' : '#9ca3af',
                                            borderRadius: '16px',
                                            boxShadow: connectorStatus === "Charging" && !loading
                                                ? '0 4px 12px rgba(239, 68, 68, 0.2)'
                                                : 'none',
                                            display: 'flex',
                                            alignItems: 'center',
                                            justifyContent: 'center',
                                            gap: '8px'
                                        }}
                                    >
                                        <span style={{ fontSize: '18px' }}>🛑</span>
                                        <span>Dừng sạc</span>
                                    </Button>
                                </Col>

                                <Col span={24}>
                                    <div style={{ height: '1px', background: '#e5e7eb' }} />
                                </Col>

                                {/* Nút thanh toán */}
                                <Col span={24}>
                                    <Button
                                        size="large"
                                        onClick={handlePayment}
                                        disabled={connectorStatus === "Charging" || loading || !sessionId}
                                        className="w-full font-bold hover:scale-105 transition-all"
                                        icon={<CreditCard size={20} />}
                                        style={{
                                            height: '60px',
                                            fontSize: '15px',
                                            width: '40%',
                                            background: 'white',
                                            borderWidth: '2px',
                                            borderStyle: 'solid',
                                            borderColor: connectorStatus !== "Charging" && !loading && sessionId ? '#f59e0b' : '#d1d5db',
                                            color: connectorStatus !== "Charging" && !loading && sessionId ? '#f59e0b' : '#9ca3af',
                                            borderRadius: '16px',
                                            boxShadow: connectorStatus !== "Charging" && !loading && sessionId
                                                ? '0 4px 12px rgba(245, 158, 11, 0.2)'
                                                : 'none',
                                            display: 'flex',
                                            alignItems: 'center',
                                            justifyContent: 'center',
                                            gap: '8px'
                                        }}
                                    >
                                        <span style={{ fontSize: '18px' }}>💳</span>
                                        <span>Thanh toán</span>
                                    </Button>
                                </Col>

                                {/* Nút rút sạc */}
                                <Col span={24}>
                                    <Button
                                        size="large"
                                        onClick={handleUnplugFromCar}
                                        disabled={!canUnplug}
                                        className={`w-full font-bold transition-all ${canUnplug ? 'hover:scale-105 cursor-pointer' : 'cursor-not-allowed opacity-60'}`}
                                        icon={<Plug size={20} />}
                                        style={{
                                            height: '60px',
                                            fontSize: '15px',
                                            width: '40%',
                                            background: 'white',
                                            borderWidth: '2px',
                                            borderStyle: 'solid',
                                            borderColor: canUnplug ? '#00b09b' : '#d1d5db',
                                            color: canUnplug ? '#00b09b' : '#9ca3af',
                                            borderRadius: '16px',
                                            boxShadow: canUnplug
                                                ? '0 4px 12px rgba(0, 176, 155, 0.2)'
                                                : 'none',
                                            display: 'flex',
                                            alignItems: 'center',
                                            justifyContent: 'center',
                                            gap: '8px'
                                        }}
                                    >
                                        <span style={{ fontSize: '18px' }}>🔋</span>
                                        <span>Rút sạc khỏi xe</span>
                                    </Button>
                                </Col>
                            </Row>

                            {/* Thông tin chi tiết */}
                            <div className="mt-4">
                                <h4 className="text-base font-bold mb-3" style={{ color: '#1f2937' }}>
                                    📋 Thông tin chi tiết
                                </h4>

                                {!pricingData.loading ? (
                                    <div className="space-y-2">
                                        <div className="flex justify-between items-center">
                                            <span className="text-sm text-gray-600">Giá điện: </span>
                                            <span className="text-sm font-bold text-gray-800">
                                                {pricingData.pricePerKWh.toLocaleString()} VNĐ/kWh
                                            </span>
                                        </div>
                                        <div className="flex justify-between items-center">
                                            <span className="text-sm text-gray-600">Thuế VAT: </span>
                                            <span className="text-sm font-bold text-gray-800">{pricingData.vatRate}%</span>
                                        </div>
                                        <div className="flex justify-between items-center">
                                            <span className="text-sm font-bold" style={{ color: '#00b09b' }}>Công suất tối đa: </span>
                                            <span className="text-base font-bold" style={{ color: '#00b09b' }}>
                                                {pricingData.maxPowerKw} kW
                                            </span>
                                        </div>
                                        {chargingData.energyDelivered > 0 && (
                                            <div className="flex justify-between items-center">
                                                <span className="text-sm text-gray-600">Tiền điện: </span>
                                                <span className="text-sm font-bold text-gray-800">
                                                    {(chargingData.energyDelivered * pricingData.pricePerKWh).toFixed(0).toLocaleString()} VNĐ
                                                </span>
                                            </div>
                                        )}
                                        {sessionId && (
                                            <div className="flex justify-between items-center pt-2" style={{
                                                borderTop: '1px solid #e5e7eb'
                                            }}>
                                                <span className="text-sm font-bold" style={{ color: '#00b09b' }}>Mã phiên: </span>
                                                <span className="text-sm font-mono font-bold" style={{ color: '#00b09b' }}>{sessionId}</span>
                                            </div>
                                        )}
                                    </div>
                                ) : (
                                    <div className="text-center py-3 text-sm text-gray-500">Đang tải thông tin...</div>
                                )}
                            </div>
                        </Card>
                    </Col>
                </Row>
            </div>
        </div>
    );
};

export default Session;