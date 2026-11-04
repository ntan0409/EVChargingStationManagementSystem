// src/pages/Admin/Station/AdminStationDetail.jsx
import { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { toast } from "react-toastify";
import {
    getChargingStationId,
    updateChargingStationStatus,
    updateChargingStation,
} from "../../../API/Station";
import {
    getAllChargingPost,
    deleteChargingPost,
    addChargingPost,
    updateChargingPost,
    updateChargingPostStatus,
} from "../../../API/ChargingPost";
import { getMyAccountStaff } from "../../../API/Staff";
import {
    Card,
    Table,
    Button,
    Space,
    Select,
    Modal,
    Input,
    Form,
    Empty,
} from "antd";
import {
    ArrowLeftOutlined,
    EditOutlined,
    DeleteOutlined,
    PlusOutlined,
    UserSwitchOutlined,
} from "@ant-design/icons";

const { Option } = Select;

// Mapping trạng thái sang tiếng Việt
const statusMapping = {
    // Trạng thái trạm sạc
    'Active': 'Hoạt động',
    'InActive': 'Không hoạt động',
    'Maintenance': 'Bảo trì',
    'Busy': 'Bận',
    'Unknown': 'Không xác định',

    // Trạng thái charging post
    'Maintained': 'Đã bảo trì',
    'Available': 'Sẵn sàng',

    // Trạng thái connector
    'Reserved': 'Đã đặt',
    'InUse': 'Đang sử dụng',
    'Charging': 'Đang sạc',
    'Preparing': 'Đang chuẩn bị',
    'Faulted': 'Lỗi',
    'Unavailable': 'Không khả dụng'
};

// Hàm helper để dịch trạng thái, nếu không có trong mapping thì trả về text gốc
const translateStatus = (status) => {
    return statusMapping[status] || status;
};

const AdminStationDetail = () => {
    const { stationId } = useParams();
    const navigate = useNavigate();

    const [station, setStation] = useState(null);
    const [posts, setPosts] = useState([]);
    const [loading, setLoading] = useState(false);
    const [noData, setNoData] = useState(false);
    const [hasError, setHasError] = useState(false);
    const [modalVisible, setModalVisible] = useState(false);
    const [editingPost, setEditingPost] = useState(null);
    const [staffModalVisible, setStaffModalVisible] = useState(false);
    const [selectedOperatorId, setSelectedOperatorId] = useState("");
    const [staffList, setStaffList] = useState([]);
    const [loadingStaff, setLoadingStaff] = useState(false);

    // 🔹 Load trạm & trụ
    const fetchStationAndPosts = async () => {
        setLoading(true);
        try {
            const stationRes = await getChargingStationId(stationId);
            // API này trả về có thể có dạng { data: {...} }
            const stationData = stationRes?.data || stationRes;
            setStation(stationData);

            const postRes = await getAllChargingPost(stationId);
            setPosts(Array.isArray(postRes) ? postRes : postRes?.data || []);
            setNoData(false);
            setHasError(false);
        } catch (error) {
            console.log('Full error:', error);

            const status = error?.response?.status;
            const errorMsg = error?.customMessage || error?.response?.data?.message || error?.message || "Đã xảy ra lỗi";

            // Chỉ không bắn toast nếu là lỗi 404 VÀ thông điệp đúng
            const isNoDataError = status === 404 && errorMsg.includes('Không tìm thấy');

            if (isNoDataError) {
                console.log('Không có dữ liệu trạm sạc');
                setNoData(true);
                setHasError(false);
            } else {
                toast.error(`Không thể tải dữ liệu trạm sạc: ${errorMsg}`); // ✅ Bắn toast cho tất cả lỗi khác
                setHasError(true);
                setNoData(false);
            }
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        if (stationId) fetchStationAndPosts();
    }, [stationId]);

    // Load danh sách nhân viên khi mở modal
    useEffect(() => {
        if (staffModalVisible) {
            fetchStaffList();
        }
    }, [staffModalVisible]);

    // 🔹 Cập nhật trạng thái trạm (không ảnh hưởng trụ)
    const handleChangeStationStatus = async (status) => {
        try {
            await updateChargingStationStatus(stationId, status);
            toast.success("Cập nhật trạng thái trạm thành công!");
            fetchStationAndPosts();
        } catch (error) {
            const errorMsg = error?.response?.data?.message || error?.message || "Lỗi không xác định";
            toast.error(`Không thể cập nhật trạng thái trạm: ${errorMsg}`);
        }
    };

    // 🔹 Load danh sách nhân viên
    const fetchStaffList = async () => {
        setLoadingStaff(true);
        try {
            const response = await getMyAccountStaff();
            const allStaff = response?.data || [];
            // Chỉ lấy nhân viên có status = "Active"
            const activeStaff = allStaff.filter(staff => staff.status === "Active");
            setStaffList(activeStaff);
        } catch (error) {
            const errorMsg = error?.response?.data?.message || error?.message || "Lỗi không xác định";
            toast.error(`Không thể tải danh sách nhân viên: ${errorMsg}`);
        } finally {
            setLoadingStaff(false);
        }
    };

    // 🔹 Cập nhật nhân viên phụ trách
    const handleUpdateStaff = async () => {
        if (!selectedOperatorId) {
            toast.warning("Vui lòng chọn nhân viên!");
            return;
        }
        try {
            await updateChargingStation(stationId, { operatorId: selectedOperatorId });
            toast.success("Cập nhật nhân viên phụ trách thành công!");
            setStaffModalVisible(false);
            setSelectedOperatorId("");
            fetchStationAndPosts();
        } catch (error) {
            const errorMsg = error?.response?.data?.message || error?.message || "Lỗi không xác định";
            toast.error(`Không thể cập nhật nhân viên: ${errorMsg}`);
        }
    };

    const handleDeletePost = async (postId, postName) => {
        const confirmDelete = window.confirm(`Bạn có chắc muốn xóa trụ sạc "${postName}" không? Hành động này không thể hoàn tác!`);
        if (!confirmDelete) return;

        try {
            await deleteChargingPost(postId);
            toast.success("Xóa trụ sạc thành công!");
            fetchStationAndPosts();
        } catch (error) {
            if (error.response) {
                const status = error.response.status;
                const msg = error.response.data?.message || "Không xác định";
                switch (status) {
                    case 404:
                        toast.error("Không tìm thấy trụ sạc để xóa!");
                        break;
                    case 400:
                        toast.error(`Yêu cầu không hợp lệ: ${msg}`);
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
                toast.error(`Có lỗi xảy ra khi xóa trụ sạc: ${errorMsg}`);
            }
        }
    };


    // 🔹 Sửa trụ sạc
    const handleEditPost = (post) => {
        setEditingPost(post);
        setModalVisible(true);
    };

    // 🔹 Thêm trụ sạc
    const handleAddPost = () => {
        setEditingPost(null);
        setModalVisible(true);
    };

    // 🔹 Lưu trụ sạc (add / update)
    const handleSavePost = async (values) => {
        try {
            const payload = {
                postName: values.postName,
                connectorType: values.connectorType,
                maxPowerKw: Number(values.maxPowerKW),
                vehicleTypeSupported: Number(values.vehicleTypeSupported),
                totalConnectors: Number(values.totalConnectors),
                status: values.status || "Available",
                stationId: stationId,
            };

            if (editingPost) {
                await updateChargingPost(editingPost.id, payload);
                toast.success("Cập nhật trụ sạc thành công!");
            } else {
                await addChargingPost(payload);
                toast.success("Thêm trụ sạc thành công!");
            }

            setModalVisible(false);
            fetchStationAndPosts();
        } catch (error) {
            const errorMsg = error?.response?.data?.message || error?.message || "Lỗi không xác định";
            toast.error(`Không thể lưu trụ sạc: ${errorMsg}`);
        }
    };

    // 🔹 Cập nhật trạng thái trụ sạc
    const handleChangePostStatus = async (postId, newStatus) => {
        try {
            await updateChargingPostStatus(postId, newStatus);
            toast.success("Cập nhật trạng thái trụ sạc thành công!");
            fetchStationAndPosts();
        } catch (error) {
            const errorMsg = error?.response?.data?.message || error?.message || "Lỗi không xác định";
            toast.error(`Không thể cập nhật trạng thái trụ: ${errorMsg}`);
        }
    };

    const columns = [
        { title: "Tên trụ sạc", dataIndex: "postName", key: "postName" },
        { title: "Kiểu kết nối", dataIndex: "connectorType", key: "connectorType" },
        { title: "Loại xe hỗ trợ", dataIndex: "vehicleTypeSupported", key: "vehicleTypeSupported", render: (v) => (Number(v) === 0 ? "Xe máy" : "Ô tô") },
        { title: "Số cổng", dataIndex: "totalConnectors", key: "totalConnectors" },
        {
            title: "Trạng thái",
            dataIndex: "status",
            key: "status",
            render: (text, record) => (
                <Select
                    value={text}
                    onChange={(value) => handleChangePostStatus(record.id, value)}
                    style={{ width: 180 }}
                >
                    <Option value="InActive">Không hoạt động</Option>
                    <Option value="Available">Sẵn sàng</Option>
                    <Option value="Maintained">Đã bảo trì</Option>
                </Select>
            ),
        },
        {
            title: "Hành động",
            key: "action",
            render: (_, record) => (
                <Space>
                    <Button icon={<EditOutlined />} onClick={() => handleEditPost(record)}>
                        Sửa
                    </Button>
                    <Button
                        icon={<DeleteOutlined />}
                        danger
                        onClick={() => handleDeletePost(record.id, record.postName)}
                    >
                        Xóa
                    </Button>

                </Space>
            ),
        },
    ];

    return (
        <div className="p-6">
            <Button
                type="link"
                icon={<ArrowLeftOutlined />}
                onClick={() => navigate("/admin/station")}
            >
                Quay lại danh sách trạm
            </Button>

            {station ? (
                <>
                    <Card
                        title={`Thông tin trạm: ${station.stationName}`}
                        className="mt-3"
                        extra={
                            <Space>
                                <Select
                                    value={station.status}
                                    onChange={handleChangeStationStatus}
                                    style={{ width: 180 }}
                                >
                                    <Option value="Inactive">Không hoạt động</Option>
                                    <Option value="Active">Hoạt động</Option>
                                    <Option value="Maintenance">Bảo trì</Option>
                                </Select>
                                <Button
                                    icon={<UserSwitchOutlined />}
                                    onClick={() => setStaffModalVisible(true)}
                                >
                                    Cập nhật nhân viên
                                </Button>
                            </Space>
                        }
                    >
                        <p><strong>Địa chỉ:</strong> {station.location}</p>
                        <p><strong>Tỉnh/Thành phố:</strong> {station.province}</p>
                        <p><strong>Nhân viên:</strong> {station.operatorName || "Chưa có"}</p>
                        <p><strong>Mã nhân viên:</strong> {station.operatorId || "Chưa có"}</p>
                    </Card>

                    <Card
                        title="Danh sách trụ sạc"
                        className="mt-4"
                        extra={<Button icon={<PlusOutlined />} onClick={handleAddPost}>Thêm trụ</Button>}
                    >
                        {hasError ? (
                            <Empty description="Đã xảy ra lỗi khi tải dữ liệu" />
                        ) : noData || posts.length === 0 ? (
                            <Empty description="Không có trụ sạc nào" />
                        ) : (
                            <Table
                                rowKey="id"
                                loading={loading}
                                dataSource={posts}
                                columns={columns}
                                pagination={{ pageSize: 5 }}
                            />
                        )}
                    </Card>

                    {/* Modal thêm/sửa trụ */}
                    <Modal
                        title={editingPost ? "Cập nhật trụ sạc" : "Thêm trụ sạc"}
                        open={modalVisible}
                        onCancel={() => setModalVisible(false)}
                        footer={null}
                    >
                        <Form
                            layout="vertical"
                            initialValues={
                                editingPost
                                    ? {
                                        ...editingPost,
                                        maxPowerKW: editingPost.maxPowerKW ?? editingPost.maxPowerKw ?? 50,
                                        vehicleTypeSupported: Number(editingPost.vehicleTypeSupported),
                                        totalConnectors: Number(editingPost.totalConnectors ?? 1),
                                        status: editingPost.status || "Available",
                                    }
                                    : {
                                        postName: "",
                                        connectorType: "css2",
                                        maxPowerKW: 50,
                                        vehicleTypeSupported: 1,
                                        totalConnectors: 1,
                                        status: "Available",
                                    }
                            }
                            onFinish={handleSavePost}
                        >
                            <Form.Item
                                name="postName"
                                label="Tên trụ sạc"
                                rules={[{ required: true, message: "Vui lòng nhập tên trụ sạc" }]}
                            >
                                <Input />
                            </Form.Item>

                            <Form.Item name="connectorType" label="Loại cổng sạc">
                                <Select>
                                    <Option value="css2">CSS2</Option>
                                    <Option value="ccs1">CCS1</Option>
                                    <Option value="type2">Type2</Option>
                                </Select>
                            </Form.Item>

                            <Form.Item
                                name="maxPowerKW"
                                label="Công suất tối đa (KW)"
                                rules={[{ required: true, message: "Vui lòng nhập công suất" }]}
                            >
                                <Input type="number" min={1} />
                            </Form.Item>

                            <Form.Item
                                name="vehicleTypeSupported"
                                label="Loại xe hỗ trợ"
                                rules={[{ required: true, message: "Vui lòng chọn loại xe" }]}
                            >
                                <Select>
                                    <Option value={0}>Xe máy</Option>
                                    <Option value={1}>Ô tô</Option>
                                </Select>
                            </Form.Item>

                            <Form.Item
                                name="totalConnectors"
                                label="Tổng số cổng"
                                rules={[{ required: true, message: "Vui lòng nhập số cổng" }]}
                            >
                                <Input type="number" min={1} />
                            </Form.Item>



                            <Form.Item>
                                <Button type="primary" htmlType="submit">
                                    {editingPost ? "Cập nhật" : "Thêm"}
                                </Button>
                            </Form.Item>
                        </Form>
                    </Modal>

                    {/* Modal cập nhật nhân viên */}
                    <Modal
                        title="Cập nhật nhân viên phụ trách"
                        open={staffModalVisible}
                        onCancel={() => {
                            setStaffModalVisible(false);
                            setSelectedOperatorId("");
                        }}
                        onOk={handleUpdateStaff}
                        okText="Lưu"
                        cancelText="Hủy"
                    >
                        <Form layout="vertical">
                            <Form.Item label="Chọn nhân viên">
                                <Select
                                    placeholder="Chọn nhân viên phụ trách"
                                    value={selectedOperatorId || undefined}
                                    onChange={(value) => setSelectedOperatorId(value)}
                                    loading={loadingStaff}
                                    showSearch
                                    filterOption={(input, option) =>
                                        option.children.toLowerCase().includes(input.toLowerCase())
                                    }
                                    style={{ width: "100%" }}
                                >
                                    {staffList.map((staff) => (
                                        <Option key={staff.id} value={staff.id}>
                                            {staff.name} - {staff.email}
                                        </Option>
                                    ))}
                                </Select>
                                {staffList.length === 0 && !loadingStaff && (
                                    <p className="text-gray-500 text-sm mt-2">
                                        Không có nhân viên Active nào
                                    </p>
                                )}
                            </Form.Item>
                        </Form>
                    </Modal>
                </>
            ) : (
                <p>Đang tải dữ liệu...</p>
            )}
        </div>
    );
};

export default AdminStationDetail;
