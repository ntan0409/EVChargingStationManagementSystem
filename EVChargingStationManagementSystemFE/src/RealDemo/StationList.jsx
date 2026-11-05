// src/components/RealDemo/StationList.jsx
import { useEffect, useState } from "react";
import { Card, Row, Col, Spin, Button, Alert } from "antd";
import { useNavigate } from "react-router-dom";
import stationAPI from "../API/Station";

// Mapping trạng thái sang tiếng Việt
const statusMap = {
    Inactive: "Không hoạt động",
    Active: "Hoạt động",
    Maintenance: "Bảo trì",
    Busy: "Đang bận"
};

const StationList = () => {
    const [stations, setStations] = useState([]);
    const [loading, setLoading] = useState(false);
    const [errorMsg, setErrorMsg] = useState("");
    const navigate = useNavigate();

    const fetchStations = async () => {
        setLoading(true);
        setErrorMsg("");
        try {
            const response = await stationAPI.getChargingStation();
            const list = Array.isArray(response)
                ? response
                : Array.isArray(response?.data)
                ? response.data
                : Array.isArray(response?.data?.data)
                ? response.data.data
                : [];
            setStations(list);
            if (list.length === 0) {
                console.warn("Không có trạm sạc nào hoặc dữ liệu không khớp:", response);
            }
        } catch (error) {
            console.error("Lỗi khi lấy danh sách trạm:", error);
            setErrorMsg(error?.customMessage || error?.message || "Không thể tải danh sách trạm sạc. Vui lòng thử lại.");
            setStations([]);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchStations();
    }, []);

    if (loading) {
        return (
            <div style={{ display: "flex", justifyContent: "center", marginTop: 50 }}>
                <Spin size="large" />
            </div>
        );
    }

    return (
        <div style={{ padding: "20px" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 20 }}>
                <h2 style={{ margin: 0 }}>Danh sách trạm sạc</h2>
                <Button onClick={fetchStations} type="primary" ghost>
                    Làm mới danh sách
                </Button>
            </div>

            {errorMsg && (
                <Alert
                    message="Lỗi kết nối"
                    description={errorMsg}
                    type="error"
                    showIcon
                    style={{ marginBottom: 20 }}
                />
            )}

            {stations.length === 0 && !errorMsg ? (
                <p>Chưa có trạm sạc nào.</p>
            ) : (
                <Row gutter={[16, 16]}>
                    {stations.map((station) => {
                        const stationKey = station.id;
                        return (
                            <Col key={stationKey} xs={24} sm={12} md={8} lg={6}>
                                <Card
                                    hoverable
                                    title={station.stationName || "Trạm không tên"}
                                    onClick={() =>
                                        navigate(`/station-list/${stationKey}/posts`)
                                    }
                                >
                                    <p><strong>Địa chỉ:</strong> {station.location || "Chưa có"}</p>
                                    <p><strong>Tỉnh/TP:</strong> {station.province || "Chưa có"}</p>
                                    <p><strong>Trạng thái:</strong> {statusMap[station.status] || station.status || "Chưa có"}</p>
                                </Card>
                            </Col>
                        );
                    })}
                </Row>
            )}
        </div>
    );
};

export default StationList;
