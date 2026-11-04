// src/components/RealDemo/ConnectorList.jsx
import React, { useEffect, useState } from "react";
import { Card, Row, Col, Spin, Tag, message } from "antd";
import { useParams, useNavigate } from "react-router-dom";
import { getChargingPostId } from "../API/ChargingPost";

const ConnectorList = () => {
    const { stationID, postID } = useParams(); // lấy ID trạm và ID trụ sạc từ URL
    const [connectors, setConnectors] = useState([]);
    const [postInfo, setPostInfo] = useState(null);
    const [loading, setLoading] = useState(false);
    const navigate = useNavigate();

    useEffect(() => {
        const fetchConnectors = async () => {
            setLoading(true);
            try {
                const response = await getChargingPostId(postID);
                console.log("Chi tiết trụ sạc:", response);

                const data = response?.data || {};
                setPostInfo(data);
                setConnectors(Array.isArray(data.connectors) ? data.connectors : []);
            } catch (error) {
                console.error("Lỗi khi lấy danh sách connector:", error);
                message.error("Không thể tải danh sách súng sạc!");
                setConnectors([]);
            } finally {
                setLoading(false);
            }
        };

        fetchConnectors();
    }, [postID]);

    if (loading) {
        return (
            <div style={{ display: "flex", justifyContent: "center", marginTop: 50 }}>
                <Spin size="large" />
            </div>
        );
    }

    const handleConnectorClick = (connectorId) => {
        // Khi click vào 1 súng sạc -> điều hướng đến trang phiên sạc
        navigate(`/station-list/${stationID}/posts/${postID}/connector/${connectorId}/session/`);
    };

    return (
        <div style={{ padding: "20px" }}>
            <h2>Danh sách súng sạc của: {postInfo?.postName || "Trụ sạc"}</h2>

            {/* Thông tin tổng quan trụ sạc */}
            {postInfo && (
                <Card style={{ marginBottom: 20 }}>
                    <p><strong>Loại cổng:</strong> {postInfo.connectorType}</p>
                    <p><strong>Phương tiện hỗ trợ:</strong> {postInfo.vehicleTypeSupported}</p>
                    <p><strong>Công suất tối đa:</strong> {postInfo.maxPowerKw} kW</p>
                    <p><strong>Tổng số cổng:</strong> {postInfo.totalConnectors}</p>
                    <p><strong>Số cổng khả dụng:</strong> {postInfo.availableConnectors}</p>
                    <p><strong>Trạng thái trụ:</strong> <Tag color="blue">{postInfo.status}</Tag></p>
                </Card>
            )}

            {/* Danh sách súng sạc */}
            {connectors.length === 0 ? (
                <p>Chưa có súng sạc nào.</p>
            ) : (
                <Row gutter={[16, 16]}>
                    {connectors.map((connector) => (
                        <Col key={connector.id} xs={24} sm={12} md={8} lg={6}>
                            <Card
                                hoverable
                                title={connector.connectorName || "Súng không tên"}
                                onClick={() => handleConnectorClick(connector.id)}
                                style={{ borderRadius: 10, border: "1px solid #ffd6e7" }}
                            >
                                <p>
                                    <strong>Trạng thái:</strong>{" "}
                                    <Tag color={
                                        connector.status === "Available"
                                            ? "green"
                                            : connector.status === "InUse"
                                                ? "orange"
                                                : "red"
                                    }>
                                        {connector.status}
                                    </Tag>
                                </p>
                                <p><strong>Công suất:</strong> {postInfo.maxPowerKw} kW</p>
                            </Card>
                        </Col>
                    ))}
                </Row>
            )}
        </div>
    );
};

export default ConnectorList;
