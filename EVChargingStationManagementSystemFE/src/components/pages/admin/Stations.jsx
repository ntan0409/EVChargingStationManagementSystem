import { useEffect, useState } from "react";
import {
    Table,
    Modal,
    Form,
    Input,
    Button,
    Space,
    Card,
    Tooltip,
    Empty,
} from "antd";
import {
    PlusOutlined,
    DeleteOutlined,
    ReloadOutlined,
    InfoCircleOutlined,
    SearchOutlined,
} from "@ant-design/icons";
import { useNavigate } from "react-router-dom";
import { toast } from "react-toastify";
import {
    getChargingStation,
    addChargingStation,
    deleteChargingStation,
} from "../../../API/Station";

const AdminStation = () => {
    const [stations, setStations] = useState([]);
    const [filteredStations, setFilteredStations] = useState([]);
    const [loading, setLoading] = useState(false);
    const [noData, setNoData] = useState(false);
    const [hasError, setHasError] = useState(false);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [searchText, setSearchText] = useState("");
    const [form] = Form.useForm();
    const navigate = useNavigate();

    // 📦 Load danh sách trạm
    const fetchStations = async () => {
        setLoading(true);
        try {
            const response = await getChargingStation();
            const data = response.data || response;
            setStations(data);
            setFilteredStations(data);
            setNoData(false);
            setHasError(false);
        } catch (error) {
            console.log('Full error:', error);

            const status = error?.response?.status;
            const errorMsg = error?.customMessage || error?.response?.data?.message || error?.message || "Đã xảy ra lỗi";

            // Chỉ không bắn toast nếu là lỗi 404 VÀ thông điệp đúng
            const isNoDataError = status === 404 && errorMsg.includes('Không tìm thấy');

            if (isNoDataError) {
                console.log('Không có trạm sạc nào');
                setNoData(true);
                setHasError(false);
            } else {
                toast.error(`Không thể tải danh sách trạm sạc: ${errorMsg}`); // ✅ Bắn toast cho tất cả lỗi khác
                setHasError(true);
                setNoData(false);
            }

            setStations([]);
            setFilteredStations([]);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchStations();
    }, []);

    // Filter stations based on search text
    useEffect(() => {
        if (searchText) {
            const filtered = stations.filter(station =>
                station.stationName?.toLowerCase().includes(searchText.toLowerCase()) ||
                station.location?.toLowerCase().includes(searchText.toLowerCase()) ||
                station.province?.toLowerCase().includes(searchText.toLowerCase())
            );
            setFilteredStations(filtered);
        } else {
            setFilteredStations(stations);
        }
    }, [searchText, stations]);

    // ➕ Mở modal thêm mới
    const openAddModal = () => {
        form.resetFields();
        setIsModalOpen(true);
    };

    // 🟢 Thêm trạm mới
    const handleAddStation = async () => {
        try {
            const values = await form.validateFields();
            await addChargingStation(
                values.stationName,
                values.location,
                values.province,
                values.latitude,
                values.longitude
            );
            toast.success("Thêm trạm mới thành công!");
            setIsModalOpen(false);
            form.resetFields();
            fetchStations();
        } catch (error) {
            const errorMsg = error?.response?.data?.message || error?.message || "Lỗi không xác định";
            toast.error(`Có lỗi xảy ra khi thêm trạm: ${errorMsg}`);
        }
    };

    const handleDelete = async (id) => {
        if (window.confirm("Xác nhận xóa trạm này?")) {
            try {
                await deleteChargingStation(id);
                toast.success("Xóa trạm thành công!");
                fetchStations();
            } catch (err) {
                const errorMsg = err?.response?.data?.message || err?.message || "Lỗi không xác định";
                toast.error(`Lỗi xóa trạm: ${errorMsg}`);
            }
        }
    };

    const handleViewDetail = (stationId) => {
        navigate(`/admin/station/${stationId}`);
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
        // {
        //     title: "Vĩ độ",
        //     dataIndex: "latitude",
        //     key: "latitude",
        // },
        // {
        //     title: "Kinh độ",
        //     dataIndex: "longitude",
        //     key: "longitude",
        // },
        {
            title: "Hành động",
            key: "action",
            render: (_, record) => (
                <Space>
                    <Tooltip title="Chi tiết & chỉnh sửa">
                        <Button
                            icon={<InfoCircleOutlined />}
                            onClick={() => handleViewDetail(record.id)}
                        />
                    </Tooltip>
                    <Tooltip title="Xóa">
                        <Button
                            icon={<DeleteOutlined />}
                            danger
                            onClick={() => handleDelete(record.id)}
                        />
                    </Tooltip>
                </Space>
            ),
        },

    ];

    return (
        <Card
            title="Quản lý trạm sạc"
            extra={
                <Space>
                    <Input
                        placeholder="Tìm kiếm trạm sạc..."
                        prefix={<SearchOutlined />}
                        value={searchText}
                        onChange={(e) => setSearchText(e.target.value)}
                        allowClear
                        style={{ width: 250 }}
                    />
                    <Button
                        icon={<ReloadOutlined />}
                        onClick={fetchStations}
                        loading={loading}
                    >
                        Tải lại
                    </Button>
                    <Button
                        type="primary"
                        icon={<PlusOutlined />}
                        onClick={openAddModal}
                    >
                        Thêm trạm mới
                    </Button>
                </Space>
            }
        >
            {hasError ? (
                <Empty description="Đã xảy ra lỗi khi tải dữ liệu" />
            ) : noData || filteredStations.length === 0 ? (
                <Empty description="Không có trạm sạc nào" />
            ) : (
                <Table
                    columns={columns}
                    dataSource={filteredStations}
                    rowKey="stationId"
                    loading={loading}
                    pagination={false}
                    scroll={{ x: 1000, y: 760 }}
                    sticky
                />
            )}

            {/* Modal thêm trạm */}
            <Modal
                title="Thêm trạm mới"
                open={isModalOpen}
                onOk={handleAddStation}
                onCancel={() => setIsModalOpen(false)}
                okText="Thêm"
                cancelText="Hủy"
            >
                <Form layout="vertical" form={form}>
                    <Form.Item
                        label="Tên trạm"
                        name="stationName"
                        rules={[{ required: true, message: "Nhập tên trạm!" }]}
                    >
                        <Input placeholder="Nhập tên trạm" />
                    </Form.Item>

                    <Form.Item
                        label="Vị trí"
                        name="location"
                        rules={[{ required: true, message: "Nhập vị trí!" }]}
                    >
                        <Input placeholder="VD: Hải Châu, Đà Nẵng" />
                    </Form.Item>

                    <Form.Item
                        label="Tỉnh/Thành phố"
                        name="province"
                        rules={[{ required: true, message: "Nhập tỉnh/thành phố!" }]}
                    >
                        <Input placeholder="VD: Đà Nẵng" />
                    </Form.Item>

                    <Form.Item
                        label="Vĩ độ"
                        name="latitude"
                        rules={[{ required: true, message: "Nhập vĩ độ!" }]}
                    >
                        <Input type="number" placeholder="VD: 16.0471" />
                    </Form.Item>

                    <Form.Item
                        label="Kinh độ"
                        name="longitude"
                        rules={[{ required: true, message: "Nhập kinh độ!" }]}
                    >
                        <Input type="number" placeholder="VD: 108.2068" />
                    </Form.Item>
                </Form>
            </Modal>
        </Card>
    );
};

export default AdminStation;
