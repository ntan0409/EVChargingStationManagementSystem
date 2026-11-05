import { useEffect, useState } from "react";
import {
    Table,
    Card,
    Space,
    Button,
    message,
    Tooltip,
} from "antd";
import { ReloadOutlined, InfoCircleOutlined } from "@ant-design/icons";
import { useNavigate } from "react-router-dom";
import {
    getStaffWorkingStation,
    updateChargingStationStatus,
} from "../../../API/Station";

const StaffStation = () => {
    const [stations, setStations] = useState([]);
    const [loading, setLoading] = useState(false);
    const navigate = useNavigate();

    // 📦 Load trạm nhân viên đang phục vụ
    const fetchStations = async () => {
        setLoading(true);
        try {
            const response = await getStaffWorkingStation();
            const data = response.data
                ? Array.isArray(response.data)
                    ? response.data
                    : [response.data]
                : [];
            setStations(data);
        } catch (error) {
            console.error("Error loading stations:", error);
            message.error("Không thể tải danh sách trạm sạc!");
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchStations();
    }, []);

    // � Xem chi titết (chỉ xem)
    const handleViewDetail = (stationId) => {
        console.log("Station ID:", stationId); // kiểm tra log
        navigate(`/staff/station/${stationId}`); // 🔹 dùng đúng route bạn đã khai báo
    };

    const columns = [
        {
            title: "Tên trạm",
            dataIndex: "stationName",
            key: "stationName",
        },
        {
            title: "Vị trí",
            dataIndex: "location",
            key: "location",
        },
        {
            title: "Tỉnh/Thành phố",
            dataIndex: "province",
            key: "province",
        },

        {
            title: "Hành động",
            key: "action",
            render: (_, record) => (
                <Space>
                    <Tooltip title="Chi tiết">
                        <Button
                            icon={<InfoCircleOutlined />}
                            onClick={() => handleViewDetail(record.id)}
                        />
                    </Tooltip>
                </Space>
            ),
        },
    ];

    return (
        <Card
            title="Trạm sạc bạn đang phục vụ"
            extra={
                <Button
                    icon={<ReloadOutlined />}
                    onClick={fetchStations}
                    loading={loading}
                >
                    Tải lại
                </Button>
            }
        >
            <Table
                columns={columns}
                dataSource={stations}
                rowKey="stationId"
                loading={loading}
                pagination={{ pageSize: 6 }}
                locale={{
                    emptyText: "Không có dữ liệu"
                }}
            />
        </Card>
    );
};

export default StaffStation;
