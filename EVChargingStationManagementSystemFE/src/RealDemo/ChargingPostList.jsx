// src/components/RealDemo/ChargingPostList.jsx
import { useEffect, useState } from "react";
import { Card, Row, Col, Spin, Modal, Input, Button, message } from "antd";
import { useParams, useNavigate } from "react-router-dom";
import { CheckCircle } from "lucide-react";
import stationAPI from "../API/Station";
import { MyBooking, BookCheckin } from "../API/Booking";

// Mapping trạng thái trụ sạc sang tiếng Việt
const postStatusMap = {
    InActive: "Không hoạt động",
    Available: "Sẵn sàng",
    Busy: "Đang bận",
    Maintained: "Đang bảo trì"
};

// Mapping loại phương tiện sang tiếng Việt
const vehicleTypeMap = {
    Bike: "Xe máy",
    Car: "Ô tô"
};

const ChargingPostList = () => {
    const { stationID } = useParams();
    const [posts, setPosts] = useState([]);
    const [loading, setLoading] = useState(false);
    const [stationName, setStationName] = useState("");
    const [myBookings, setMyBookings] = useState([]);
    const [checkinModal, setCheckinModal] = useState({
        visible: false,
        chargingPostId: null,
        bookingId: null,
        connectorId: null
    });
    const [checkinCode, setCheckinCode] = useState("");
    const [checkinLoading, setCheckinLoading] = useState(false);
    const navigate = useNavigate();

    useEffect(() => {
        const fetchStationData = async () => {
            setLoading(true);
            try {
                // Lấy thông tin trạm và trụ sạc (luôn cần thiết)
                const stationResponse = await stationAPI.getChargingStationId(stationID);
                console.log("Chi tiết trạm:", stationResponse);
                setStationName(stationResponse.stationName || "Trạm không tên");

                const postArray = Array.isArray(stationResponse.chargingPosts) ? stationResponse.chargingPosts : [];
                setPosts(postArray);
            } catch (error) {
                console.error("Lỗi khi lấy thông tin trạm:", error);
                setPosts([]);
            } finally {
                setLoading(false);
            }
        };

        const fetchBookingData = async () => {
            try {
                // Lấy booking của user hiện tại (tùy chọn, không ảnh hưởng đến hiển thị trụ sạc)
                const bookingsResponse = await MyBooking();
                console.log("Booking của tôi:", bookingsResponse);

                const bookings = Array.isArray(bookingsResponse.data) ? bookingsResponse.data :
                    Array.isArray(bookingsResponse) ? bookingsResponse : [];

                // Lọc booking cho trạm hiện tại và trạng thái Confirmed
                const relevantBookings = bookings.filter(booking =>
                    booking.stationId === parseInt(stationID) &&
                    booking.status === 'Confirmed'
                );

                setMyBookings(relevantBookings);
                console.log("Booking của tôi tại trạm này:", relevantBookings);
            } catch (error) {
                console.error("Lỗi khi lấy booking của tôi (có thể chưa đăng nhập):", error);
                setMyBookings([]); // Chỉ reset booking, không reset trụ sạc
            }
        };

        // Gọi song song nhưng không phụ thuộc lẫn nhau
        fetchStationData();
        fetchBookingData();
    }, [stationID]);

    // Tìm booking cho chargingPost cụ thể
    const findBookingForPost = async (chargingPostId) => {
        try {
            // Lấy tất cả connector của chargingPost này
            const post = posts.find(p => p.id === chargingPostId);
            if (!post || !post.connectors) return null;

            // Tìm booking có connectorId trùng với connector của post này
            for (const booking of myBookings) {
                if (booking.connectorId) {
                    // Kiểm tra xem connectorId của booking có thuộc chargingPost này không
                    const connectorInPost = post.connectors.find(c => c.id === booking.connectorId);
                    if (connectorInPost) {
                        return booking;
                    }
                }
            }
            return null;
        } catch (error) {
            console.error("Lỗi khi tìm booking:", error);
            return null;
        }
    };

    // Mở modal checkin
    const handleOpenCheckin = async (chargingPostId) => {
        const booking = await findBookingForPost(chargingPostId);

        if (!booking) {
            message.warning("Bạn chưa có booking cho trụ sạc này!");
            return;
        }

        setCheckinModal({
            visible: true,
            chargingPostId,
            bookingId: booking.id,
            connectorId: booking.connectorId
        });
        setCheckinCode("");
    };

    // Xử lý checkin
    const handleCheckin = async () => {
        if (!checkinCode.trim()) {
            message.error("Vui lòng nhập mã checkin!");
            return;
        }

        setCheckinLoading(true);
        try {
            // Gọi API checkin
            const response = await BookCheckin(checkinModal.bookingId);
            console.log("Checkin thành công:", response);

            message.success("Checkin thành công!");

            // Đóng modal và chuyển đến trang session
            setCheckinModal({ visible: false, chargingPostId: null, bookingId: null, connectorId: null });
            setCheckinCode("");

            // Chuyển đến trang session với connectorId
            navigate(`/session/${checkinModal.connectorId}`);
        } catch (error) {
            console.error("Lỗi checkin:", error);
            message.error("Checkin thất bại! Vui lòng kiểm tra lại mã.");
        } finally {
            setCheckinLoading(false);
        }
    };

    // Đóng modal
    const handleCloseModal = () => {
        setCheckinModal({ visible: false, chargingPostId: null, bookingId: null, connectorId: null });
        setCheckinCode("");
    };

    if (loading) {
        return (
            <div style={{ display: "flex", justifyContent: "center", marginTop: 50 }}>
                <Spin size="large" />
            </div>
        );
    }

    return (
        <div style={{ padding: "20px" }}>
            <h2>Danh sách trụ sạc của: {stationName}</h2>
            {posts.length === 0 ? (
                <p>Chưa có trụ sạc nào.</p>
            ) : (
                <Row gutter={[16, 16]}>
                    {posts.map((post) => {
                        // Kiểm tra xem user có booking cho post này không
                        const hasBooking = myBookings.some(booking => {
                            if (!booking.connectorId || !post.connectors) return false;
                            return post.connectors.some(c => c.id === booking.connectorId);
                        });

                        return (
                            <Col key={post.id} xs={24} sm={12} md={8} lg={6}>
                                <Card
                                    hoverable
                                    title={post.postName || "Trụ không tên"}
                                    onClick={() =>
                                        navigate(`/station-list/${stationID}/posts/${post.id}/connector`)
                                    }
                                    extra={
                                        hasBooking && (
                                            <Button
                                                type="primary"
                                                size="small"
                                                icon={<CheckCircle size={14} />}
                                                onClick={(e) => {
                                                    e.stopPropagation();
                                                    handleOpenCheckin(post.id);
                                                }}
                                            >
                                                Check-in
                                            </Button>
                                        )
                                    }
                                >
                                    <p><strong>Trạng thái:</strong> {postStatusMap[post.status] || post.status || "Chưa có"}</p>
                                    <p><strong>Loại cổng:</strong> {post.connectorType || "Chưa có"}</p>
                                    <p><strong>Hỗ trợ:</strong> {vehicleTypeMap[post.vehicleTypeSupported] || post.vehicleTypeSupported || "Chưa có"}</p>
                                    <p><strong>Công suất tối đa:</strong> {post.maxPowerKw || "Chưa có"} kW</p>
                                    <p><strong>Số cổng:</strong> {post.totalConnectors || "Chưa có"}</p>
                                </Card>
                            </Col>
                        );
                    })}
                </Row>
            )}

            {/* Modal Check-in */}
            <Modal
                title={
                    <div className="flex items-center gap-2">
                        <CheckCircle className="text-green-500" size={20} />
                        <span>Check-in tại trụ sạc</span>
                    </div>
                }
                open={checkinModal.visible}
                onCancel={handleCloseModal}
                footer={[
                    <Button key="cancel" onClick={handleCloseModal}>
                        Hủy
                    </Button>,
                    <Button
                        key="checkin"
                        type="primary"
                        loading={checkinLoading}
                        onClick={handleCheckin}
                    >
                        Check-in
                    </Button>
                ]}
                width={400}
            >
                <div className="py-4">
                    <p className="mb-4 text-gray-600">
                        Bạn có booking đang chờ check-in tại trụ sạc này. Vui lòng nhập mã check-in để xác nhận và bắt đầu phiên sạc.
                    </p>

                    <div className="mb-4">
                        <label className="block text-sm font-medium text-gray-700 mb-2">
                            Mã Check-in:
                        </label>
                        <Input.Password
                            placeholder="Nhập mã check-in"
                            value={checkinCode}
                            onChange={(e) => setCheckinCode(e.target.value)}
                            onPressEnter={handleCheckin}
                            size="large"
                        />
                    </div>

                    {checkinModal.bookingId && (
                        <div className="p-3 bg-blue-50 rounded-lg">
                            <p className="text-sm text-gray-600">
                                <strong>Booking ID:</strong> {checkinModal.bookingId}
                            </p>
                            <p className="text-sm text-gray-600">
                                <strong>Connector ID:</strong> {checkinModal.connectorId}
                            </p>
                        </div>
                    )}
                </div>
            </Modal>
        </div>
    );
};

export default ChargingPostList;
