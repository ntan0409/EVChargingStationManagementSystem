import { useEffect, useState } from "react";
import { Button, Table, Modal, Input, Form, Select, Space, Tooltip, Empty } from "antd";
import { EditOutlined, DeleteOutlined, PlusOutlined, SearchOutlined } from "@ant-design/icons";
import { toast } from "react-toastify";
import {
    GetVehicleModel,
    GetVehicleModelById,
    DeleteVehicleModel,
    PostVehicleModel,
    UpdateVehicleModel,
    VehicleStatus,
    UpdateVehicleModelStatus
} from "../../../API/VehicleModel";
import "./AdminVehicles.css";

const AdminVehicles = () => {
    const [models, setModels] = useState([]);
    const [filteredModels, setFilteredModels] = useState([]);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingModel, setEditingModel] = useState(null);
    const [loading, setLoading] = useState(false);
    const [noData, setNoData] = useState(false);
    const [hasError, setHasError] = useState(false);
    const [searchText, setSearchText] = useState("");
    const [deletingId, setDeletingId] = useState(null);
    const [updatingStatusId, setUpdatingStatusId] = useState(null);
    const [form] = Form.useForm();

    const fetchModels = async () => {
        setLoading(true);
        try {
            const res = await GetVehicleModel();
            // console.log("Vehicle models response:", res);

            const data = Array.isArray(res) ? res : (res?.data ?? res?.data?.data ?? []);
            // console.log("Processed data:", data);

            // Kiểm tra xem data có chứa status không, nếu không thì lấy từ API riêng
            const modelsWithStatus = await Promise.all(
                data.map(async (m) => {
                    try {
                        // Nếu đã có status trong data thì dùng luôn
                        if (m.status !== undefined && m.status !== null) {
                            return { ...m, status: m.status };
                        }

                        // Nếu chưa có status thì gọi API để lấy
                        const statusRes = await VehicleStatus(m.vehicleModelId ?? m.id);
                        return {
                            ...m,
                            status: statusRes?.status ?? statusRes?.data?.status ?? 2 // mặc định Inactive
                        };
                    } catch (statusError) {
                        const errorMsg = statusError?.response?.data?.message || statusError?.message || "Không thể lấy trạng thái";
                        toast.warning(`Không thể lấy trạng thái cho xe ${m.vehicleModelId ?? m.id}: ${errorMsg}`);
                        return { ...m, status: 2 }; // mặc định Inactive
                    }
                })
            );

            setModels(modelsWithStatus);
            setFilteredModels(modelsWithStatus);
            setNoData(false);
            setHasError(false);
        } catch (error) {
            console.log('Full error:', error);

            const status = error?.response?.status;
            const errorMsg = error?.customMessage || error?.response?.data?.message || error?.message || "Đã xảy ra lỗi";

            // Chỉ không bắn toast nếu là lỗi 404 VÀ thông điệp đúng
            const isNoDataError = status === 404 && errorMsg.includes('Không tìm thấy');

            if (isNoDataError) {
                console.log('Không có mẫu xe nào');
                setNoData(true);
                setHasError(false);
            } else {
                toast.error(`Không thể tải danh sách mẫu xe: ${errorMsg}`); // ✅ Bắn toast cho tất cả lỗi khác
                setHasError(true);
                setNoData(false);
            }

            setModels([]);
            setFilteredModels([]);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchModels();
    }, []);

    useEffect(() => {
        if (Array.isArray(models)) {
            const filtered = models.filter((m) =>
                (m.modelName ?? "").toString().toLowerCase().includes(searchText.toLowerCase()) ||
                (m.modelYear ?? "").toString().includes(searchText)
            );
            setFilteredModels(filtered);
        }
    }, [searchText, models]);

    const handleSave = async (values) => {
        try {
            if (editingModel) {
                // Lấy ID từ record hiện tại
                const id = editingModel.id;

                // Gọi API để lấy thông tin xe trước khi update
                const vehicle = await GetVehicleModelById(id);

                if (!vehicle) {
                    toast.error("Không tìm thấy xe để cập nhật!");
                    return;
                }

                // Chuyển đổi vehicleType từ string sang number
                const vehicleTypeValue = values.vehicleType === "Car" ? 1 : values.vehicleType === "Bike" ? 0 : Number(values.vehicleType);

                // Chuyển đổi status từ string sang number
                const statusValue = values.status === "Active" ? 1 : values.status === "Discontinued" ? 2 : values.status === "Unknown" ? 3 : Number(values.status);

                await UpdateVehicleModel(id, {
                    modelName: values.modelName,
                    modelYear: Number(values.modelYear),
                    vehicleType: vehicleTypeValue,
                    batteryCapacityKWh: Number(values.batteryCapacityKWh),
                    recommendedChargingPowerKW: Number(values.recommendedChargingPowerKW),
                    imageUrl: values.imageUrl ?? null,
                    status: statusValue
                });
                toast.success("Cập nhật mẫu xe thành công!");
            } else {
                // Chuyển đổi vehicleType cho tạo mới
                const vehicleTypeValue = values.vehicleType === "Car" ? 1 : values.vehicleType === "Bike" ? 0 : Number(values.vehicleType);
                const statusValue = values.status === "Active" ? 1 : values.status === "Discontinued" ? 2 : values.status === "Unknown" ? 3 : 2;

                await PostVehicleModel(
                    values.modelName,
                    Number(values.modelYear),
                    vehicleTypeValue,
                    Number(values.batteryCapacityKWh),
                    Number(values.recommendedChargingPowerKW),
                    values.imageUrl ?? null,
                    statusValue
                );
                toast.success("Thêm mẫu xe thành công!");
            }

            setIsModalOpen(false);
            form.resetFields();
            setEditingModel(null);
            fetchModels();
        } catch (error) {
            const errorMsg = error?.response?.data?.message || error?.message || "Lỗi không xác định";
            const statusCode = error?.response?.status;

            if (statusCode === 404) {
                toast.error("Không tìm thấy mẫu xe để cập nhật!");
            } else if (statusCode === 400) {
                toast.error(`Dữ liệu không hợp lệ: ${errorMsg}`);
            } else if (statusCode === 500) {
                toast.error("Lỗi máy chủ! Vui lòng thử lại sau.");
            } else {
                toast.error(`Lỗi khi lưu mẫu xe: ${errorMsg}`);
            }
        }
    };

    const handleDelete = async (id, modelName) => {
        if (window.confirm(`Bạn có chắc chắn muốn xóa mẫu xe "${modelName}"? Hành động này không thể hoàn tác.`)) {
            setDeletingId(id);
            try {
                await DeleteVehicleModel(id);
                toast.success("Xóa mẫu xe thành công!");
                fetchModels();
            } catch (error) {
                if (error.response) {
                    const status = error.response.status;
                    const msg = error.response.data?.message || error.response.data?.error || "Lỗi không xác định";
                    switch (status) {
                        case 404:
                            toast.error("Không tìm thấy mẫu xe để xóa!");
                            break;
                        case 400:
                            toast.error(`Dữ liệu không hợp lệ: ${msg}`);
                            break;
                        case 500:
                            toast.error("Lỗi máy chủ! Vui lòng thử lại sau.");
                            break;
                        default:
                            toast.error(`Lỗi ${status}: ${msg}`);
                    }
                } else if (error.request) {
                    toast.error("Không thể kết nối đến máy chủ!");
                } else {
                    const errorMsg = error?.message || "Lỗi không xác định";
                    toast.error(`Có lỗi xảy ra khi xóa mẫu xe: ${errorMsg}`);
                }
            } finally {
                setDeletingId(null);
            }
        }
    };


    const handleUpdateStatus = async (id, newStatus) => {
        setUpdatingStatusId(id);
        try {
            await UpdateVehicleModelStatus(id, newStatus);
            toast.success("Cập nhật trạng thái thành công!");
            fetchModels();
        } catch (error) {
            // Xử lý các loại lỗi khác nhau
            if (error.response) {
                const status = error.response.status;
                const errorMessage = error.response.data?.message || error.response.data?.error || "Lỗi không xác định";

                switch (status) {
                    case 404:
                        toast.error("Không tìm thấy mẫu xe để cập nhật!");
                        break;
                    case 400:
                        toast.error(`Dữ liệu không hợp lệ: ${errorMessage}`);
                        break;
                    case 500:
                        toast.error("Lỗi máy chủ! Vui lòng thử lại sau.");
                        break;
                    default:
                        toast.error(`Lỗi ${status}: ${errorMessage}`);
                }
            } else if (error.request) {
                toast.error("Không thể kết nối đến máy chủ!");
            } else {
                const errorMsg = error?.message || "Lỗi không xác định";
                toast.error(`Có lỗi xảy ra khi cập nhật trạng thái: ${errorMsg}`);
            }
        } finally {
            setUpdatingStatusId(null);
        }
    };

    const getStatusLabel = (status) => {
        // Xử lý null/undefined
        if (status === null || status === undefined) {
            return "Không rõ";
        }

        // Xử lý string - thêm case cho chữ hoa đầu
        if (typeof status === 'string') {
            const lowerStatus = status.toLowerCase();
            switch (lowerStatus) {
                case "inactive":
                case "0":
                    return "Ngừng hoạt động";
                case "active":
                case "1":
                    return "Hoạt động";
                case "discontinued":
                case "2":
                    return "Ngừng sản xuất";
                case "unknown":
                case "3":
                    return "Không rõ";
                default:
                    // Nếu không match, thử convert sang number
                    const num = Number(status);
                    if (!isNaN(num)) {
                        switch (num) {
                            case 0: return "Ngừng hoạt động";
                            case 1: return "Hoạt động";
                            case 2: return "Ngừng sản xuất";
                            case 3: return "Không rõ";
                        }
                    }
                    return status; // Trả về nguyên gốc nếu không match
            }
        }

        // Xử lý number
        const numStatus = Number(status);
        if (!isNaN(numStatus)) {
            switch (numStatus) {
                case 0: return "Ngừng hoạt động";
                case 1: return "Hoạt động";
                case 2: return "Ngừng sản xuất";
                case 3: return "Không rõ";
                default: return `Trạng thái ${numStatus}`;
            }
        }

        return "Không rõ";
    };

    const getStatusColor = (status) => {
        // Xử lý null/undefined
        if (status === null || status === undefined) {
            return "geekblue";
        }

        // Xử lý string
        if (typeof status === 'string') {
            const lowerStatus = status.toLowerCase();
            switch (lowerStatus) {
                case "active":
                case "1":
                    return "green";
                case "inactive":
                case "2":
                    return "volcano";
                case "Discontinued":
                case "3":
                    return "gray";
                default:
                    return "geekblue";
            }
        }

        // Xử lý number
        const numStatus = Number(status);
        switch (numStatus) {
            case 0: return "geekblue";
            case 1: return "green";
            case 2: return "volcano";
            case 3: return "gray";
            default: return "geekblue";
        }
    };

    const columns = [
        { title: "Tên mẫu", dataIndex: "modelName", key: "modelName" },
        { title: "Năm", dataIndex: "modelYear", key: "modelYear" },
        {
            title: "Loại xe",
            dataIndex: "vehicleType",
            key: "vehicleType",
            render: (t) => {
                if (typeof t === 'string') {
                    return t === "Car" ? "Xe ô tô" : t === "Bike" ? "Xe máy" : t;
                }
                return t === 0 ? "Xe máy" : t === 1 ? "Xe ô tô" : "Không xác định";
            }
        },
        {
            title: "Dung lượng pin (kWh)",
            dataIndex: "batteryCapacityKWh",
            key: "batteryCapacityKWh",
            render: (c) => (c ? `${c} kWh` : "—")
        },
        {
            title: "Công suất sạc (kW)",
            dataIndex: "recommendedChargingPowerKW",
            key: "recommendedChargingPowerKW",
            render: (p) => (p ? `${p} kW` : "—")
        },
        {
            title: "Tình trạng",
            dataIndex: "status",
            key: "status",
            render: (status, record) => {
                const id = record.vehicleModelId ?? record.id;
                const isUpdating = updatingStatusId === id;

                // Convert status sang number để hiển thị trong Select
                let normalizedStatus = status;
                if (typeof status === 'string') {
                    const lowerStatus = status.toLowerCase();
                    if (lowerStatus === 'inactive' || lowerStatus === '0') normalizedStatus = 0;
                    else if (lowerStatus === 'active' || lowerStatus === '1') normalizedStatus = 1;
                    else if (lowerStatus === 'discontinued' || lowerStatus === '2') normalizedStatus = 2;
                    else if (lowerStatus === 'unknown' || lowerStatus === '3') normalizedStatus = 3;
                    else normalizedStatus = Number(status);
                } else {
                    normalizedStatus = Number(status);
                }

                return (
                    <Select
                        value={normalizedStatus}
                        onChange={(newStatus) => handleUpdateStatus(id, newStatus)}
                        loading={isUpdating}
                        disabled={isUpdating}
                        style={{ minWidth: 150 }}
                        size="small"
                        placeholder="Thay đổi"
                    >
                        <Select.Option value={0}>Ngừng hoạt động</Select.Option>
                        <Select.Option value={1}>Hoạt động</Select.Option>
                        <Select.Option value={2}>Ngừng sản xuất</Select.Option>
                    </Select>
                );
            }
        },
        {
            title: "Hình ảnh",
            dataIndex: "imageUrl",
            key: "imageUrl",
            render: (u) =>
                u ? (
                    <img
                        src={u}
                        alt="model"
                        style={{
                            width: 80,
                            height: 48,
                            objectFit: "cover",
                            borderRadius: 6
                        }}
                    />
                ) : (
                    "—"
                )
        },
        {
            title: "Thao tác",
            key: "actions",
            render: (_, record) => {
                const id = record.vehicleModelId ?? record.id;
                return (
                    <Space>
                        <Tooltip title="Chỉnh sửa">
                            <Button
                                type="primary"
                                size="small"
                                icon={<EditOutlined />}
                                onClick={() => {
                                    setEditingModel(record);
                                    setIsModalOpen(true);
                                    form.setFieldsValue({
                                        modelName: record.modelName,
                                        modelYear: record.modelYear,
                                        vehicleType: record.vehicleType,
                                        batteryCapacityKWh: record.batteryCapacityKWh,
                                        recommendedChargingPowerKW: record.recommendedChargingPowerKW,
                                        imageUrl: record.imageUrl,
                                        status: record.status
                                    });
                                }}
                            />
                        </Tooltip>
                        <Tooltip title="Xóa">
                            <Button
                                danger
                                size="small"
                                icon={<DeleteOutlined />}
                                loading={deletingId === id}
                                disabled={deletingId === id}
                                onClick={() => handleDelete(id, record.modelName)}
                            />
                        </Tooltip>

                    </Space>
                );
            }
        }
    ];

    return (
        <div className="admin-vehicles">
            {/* Header */}
            <div className="header">
                <h1>Quản lý mẫu xe</h1>
                <p>Thêm, sửa, xóa và xem tình trạng các mẫu xe điện</p>
            </div>

            {/* Actions Card */}
            <div className="actions-card">
                <div className="actions-container">
                    <div className="search-container">
                        <Input
                            placeholder="Tìm kiếm theo tên hoặc năm..."
                            prefix={<SearchOutlined />}
                            value={searchText}
                            onChange={(e) => setSearchText(e.target.value)}
                            allowClear
                            style={{ width: '100%' }}
                        />
                    </div>
                    <Button
                        type="primary"
                        icon={<PlusOutlined />}
                        onClick={() => {
                            setIsModalOpen(true);
                            setEditingModel(null);
                            form.resetFields();
                            form.setFieldsValue({ status: "Inactive" }); // mặc định Inactive
                        }}
                        className="add-btn"
                    >
                        Thêm mẫu
                    </Button>
                </div>
            </div>


            {/* Table Card */}
            <div className="table-card">
                {hasError ? (
                    <Empty description="Đã xảy ra lỗi khi tải dữ liệu" />
                ) : noData || filteredModels.length === 0 ? (
                    <Empty description="Không có mẫu xe nào" />
                ) : (
                    <Table
                        dataSource={filteredModels}
                        columns={columns}
                        rowKey={(r) => r.vehicleModelId ?? r.id}
                        loading={loading}
                        pagination={false}
                        scroll={{ x: 1200, y: 600 }}
                        sticky
                    />
                )}
            </div>

            <Modal
                title={editingModel ? "Chỉnh sửa mẫu xe" : "Thêm mẫu xe"}
                open={isModalOpen}
                onCancel={() => {
                    setIsModalOpen(false);
                    form.resetFields();
                    setEditingModel(null);
                }}
                footer={null}
                width={620}
            >
                <Form form={form} layout="vertical" onFinish={handleSave}>
                    <Form.Item name="modelName" label="Tên mẫu" rules={[{ required: true, message: "Nhập tên mẫu!" }]}>
                        <Input />
                    </Form.Item>

                    <Form.Item name="modelYear" label="Năm sản xuất" rules={[{ required: true, message: "Nhập năm!" }]}>
                        <Input type="number" />
                    </Form.Item>

                    <Form.Item name="vehicleType" label="Loại xe" rules={[{ required: true, message: "Chọn loại xe!" }]}>
                        <Select>
                            <Select.Option value="Bike">Xe máy</Select.Option>
                            <Select.Option value="Car">Xe ô tô</Select.Option>
                        </Select>
                    </Form.Item>

                    <Form.Item name="batteryCapacityKWh" label="Dung lượng pin (kWh)" rules={[{ required: true }]}>
                        <Input type="number" />
                    </Form.Item>

                    <Form.Item name="recommendedChargingPowerKW" label="Công suất sạc khuyến nghị (kW)" rules={[{ required: true }]}>
                        <Input type="number" />
                    </Form.Item>

                    <Form.Item name="imageUrl" label="Hình ảnh (URL)">
                        <Input placeholder="https://..." />
                    </Form.Item>

                    <div style={{ textAlign: "right" }}>
                        <Button onClick={() => { setIsModalOpen(false); form.resetFields(); }} style={{ marginRight: 8 }}>
                            Hủy
                        </Button>
                        <Button type="primary" htmlType="submit">
                            {editingModel ? "Cập nhật" : "Thêm mới"}
                        </Button>
                    </div>
                </Form>
            </Modal>
        </div>
    );
};

export default AdminVehicles;
