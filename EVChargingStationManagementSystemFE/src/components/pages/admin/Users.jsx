import { useEffect, useMemo, useState } from "react";
import {
    Table,
    Tag,
    Input,
    Button,
    Space,
    Tooltip,
    Empty,
    Modal,
    Form,
    Select,
    Avatar,
    Badge,
    Spin,
    Divider
} from "antd";
import {
    ReloadOutlined,
    SearchOutlined,
    EyeOutlined,
    EditOutlined
} from "@ant-design/icons";
import dayjs from "dayjs";
import { toast } from "react-toastify";
import {
    getEVDriver,
    updateEVDriver,
    getEVDriverId
} from "../../../API/EVDriver";
import "./Users.css";

const { Search } = Input;

const Users = () => {
    const [drivers, setDrivers] = useState([]);
    const [loading, setLoading] = useState(false);
    const [searchText, setSearchText] = useState("");
    const [statusFilter, setStatusFilter] = useState("all");
    const [detailModalOpen, setDetailModalOpen] = useState(false);
    const [detailData, setDetailData] = useState(null);
    const [detailLoading, setDetailLoading] = useState(false);
    const [editModalOpen, setEditModalOpen] = useState(false);
    const [editingDriver, setEditingDriver] = useState(null);
    const [submitLoading, setSubmitLoading] = useState(false);
    const [form] = Form.useForm();

    const fetchDrivers = async () => {
        setLoading(true);
        try {
            const res = await getEVDriver();
            const data = Array.isArray(res)
                ? res
                : Array.isArray(res?.data)
                    ? res.data
                    : res?.data?.data ?? [];
            setDrivers(data);
        } catch (error) {
            const msg = error?.response?.data?.message || error?.message || "Không thể tải danh sách người dùng";
            toast.error(msg);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchDrivers();
    }, []);

    const filteredDrivers = useMemo(() => {
        return drivers.filter((driver) => {
            const keyword = searchText.trim().toLowerCase();
            const matchesKeyword =
                !keyword ||
                [driver.name, driver.email, driver.phoneNumber]
                    .filter(Boolean)
                    .some((field) => field.toLowerCase().includes(keyword));

            const matchesStatus =
                statusFilter === "all" ||
                (driver.status ?? "").toLowerCase() === statusFilter;

            return matchesKeyword && matchesStatus;
        });
    }, [drivers, searchText, statusFilter]);

    const statusColorMap = (status) => {
        const normalized = (status ?? "").toLowerCase();
        switch (normalized) {
            case "active":
                return "green";
            case "inactive":
            case "suspended":
            case "locked":
                return "red";
            default:
                return "default";
        }
    };

    const formatStatusLabel = (status) => {
        if (!status) return "Không xác định";
        switch (status.toLowerCase()) {
            case "active":
                return "Đang hoạt động";
            case "inactive":
                return "Ngưng hoạt động";
            case "locked":
                return "Bị khóa";
            default:
                return status;
        }
    };

    const handleOpenDetail = async (driverId) => {
        setDetailLoading(true);
        setDetailModalOpen(true);
        try {
            const data = await getEVDriverId(driverId);
            setDetailData(data);
        } catch (error) {
            const msg = error?.response?.data?.message || error?.message || "Không thể tải chi tiết người dùng";
            toast.error(msg);
            setDetailModalOpen(false);
        } finally {
            setDetailLoading(false);
        }
    };

    const handleOpenEdit = async (driverId) => {
        setEditModalOpen(true);
        setDetailLoading(true);
        try {
            const data = await getEVDriverId(driverId);
            setEditingDriver(data);
            form.setFieldsValue({
                name: data?.name,
                phoneNumber: data?.phoneNumber,
                address: data?.address,
                profilePictureUrl: data?.profilePictureUrl,
                vehicleModelIds: data?.vehicleModelIds ?? []
            });
        } catch (error) {
            const msg = error?.response?.data?.message || error?.message || "Không thể tải thông tin chỉnh sửa";
            toast.error(msg);
            setEditModalOpen(false);
        } finally {
            setDetailLoading(false);
        }
    };

    const handleUpdateDriver = async () => {
        try {
            const values = await form.validateFields();
            setSubmitLoading(true);
            await updateEVDriver(
                editingDriver.id,
                values.name ?? "",
                values.phoneNumber ?? "",
                values.address ?? "",
                values.profilePictureUrl ?? "",
                values.vehicleModelIds ?? []
            );
            toast.success("Cập nhật người dùng thành công");
            setEditModalOpen(false);
            setEditingDriver(null);
            form.resetFields();
            fetchDrivers();
        } catch (error) {
            if (error?.errorFields) {
                return;
            }
            const msg = error?.response?.data?.message || error?.message || "Không thể cập nhật người dùng";
            toast.error(msg);
        } finally {
            setSubmitLoading(false);
        }
    };

    const columns = [
        {
            title: "Người dùng",
            dataIndex: "name",
            key: "name",
            render: (_, record) => (
                <div className="user-info">
                    <Badge dot={record.vehicleModelIds?.length > 0} offset={[-2, 2]}>
                        <Avatar size={40} src={record.profilePictureUrl}>
                            {(record.name || record.email || "?").charAt(0).toUpperCase()}
                        </Avatar>
                    </Badge>
                    <div>
                        <div className="user-name">{record.name || "Chưa cập nhật"}</div>
                        <div className="user-email">{record.email || "Không có email"}</div>
                    </div>
                </div>
            )
        },
        {
            title: "Điện thoại",
            dataIndex: "phoneNumber",
            key: "phoneNumber",
            render: (value) => value || "—"
        },
        {
            title: "Điểm",
            dataIndex: "score",
            key: "score",
            width: 100,
            render: (value) => value ?? 0
        },
        // {
        //     title: "Ranking",
        //     dataIndex: "rankingName",
        //     key: "rankingName",
        //     render: (value) => (
        //         <Tag color={value ? "gold" : "default"}>
        //             {value || "Chưa xếp hạng"}
        //         </Tag>
        //     )
        // },
        {
            title: "Trạng thái",
            dataIndex: "status",
            key: "status",
            render: (status) => (
                <Tag color={statusColorMap(status)}>
                    {formatStatusLabel(status)}
                </Tag>
            )
        },
        // {
        //     title: "Số xe liên kết",
        //     dataIndex: "vehicleModelIds",
        //     key: "vehicleModelIds",
        //     render: (ids) => ids?.length || 0
        // },
        {
            title: "Ngày tạo",
            dataIndex: "createdAt",
            key: "createdAt",
            render: (value) => (value ? dayjs(value).format("DD/MM/YYYY HH:mm") : "—")
        },
        // {
        //     title: "Thao tác",
        //     key: "actions",
        //     fixed: "right",
        //     render: (_, record) => (
        //         <Space>
        //             <Tooltip title="Xem chi tiết">
        //                 <Button
        //                     icon={<EyeOutlined />}
        //                     size="small"
        //                     onClick={() => handleOpenDetail(record.id)}
        //                 />
        //             </Tooltip>
        //             <Tooltip title="Chỉnh sửa">
        //                 <Button
        //                     icon={<EditOutlined />}
        //                     size="small"
        //                     type="primary"
        //                     onClick={() => handleOpenEdit(record.id)}
        //                 />
        //             </Tooltip>
        //         </Space>
        //     )
        // }
    ];

    const totalDrivers = drivers.length;
    const activeDrivers = drivers.filter((d) => (d.status ?? "").toLowerCase() === "active").length;
    const withVehicle = drivers.filter((d) => d.vehicleModelIds?.length).length;

    return (
        <div className="users-page">
            <div className="users-page__header">
                <div>
                    <h2>Quản lý người dùng</h2>
                    <p>Theo dõi và cập nhật thông tin tài xế sử dụng hệ thống</p>
                </div>
                <Button icon={<ReloadOutlined />} onClick={fetchDrivers} loading={loading}>
                    Làm mới
                </Button>
            </div>

            <div className="users-page__stats">
                <div className="stat-card">
                    <p>Tổng số tài xế</p>
                    <h3>{totalDrivers}</h3>
                </div>
                <div className="stat-card">
                    <p>Đang hoạt động</p>
                    <h3>{activeDrivers}</h3>
                </div>
                {/* <div className="stat-card">
                    <p>Đã liên kết xe</p>
                    <h3>{withVehicle}</h3>
                </div> */}
            </div>

            <div className="users-page__filters">
                <Search
                    placeholder="Tìm theo tên, email, số điện thoại..."
                    allowClear
                    enterButton={<SearchOutlined />}
                    onSearch={(value) => setSearchText(value)}
                    onChange={(e) => setSearchText(e.target.value)}
                    value={searchText}
                />
                <Select
                    value={statusFilter}
                    onChange={setStatusFilter}
                    options={[
                        { value: "all", label: "Tất cả trạng thái" },
                        { value: "active", label: "Đang hoạt động1" },
                        { value: "inactive", label: "Ngưng hoạt động" },
                        { value: "suspended", label: "Tạm khóa" }
                    ]}
                />
            </div>

            <Table
                rowKey="id"
                columns={columns}
                dataSource={filteredDrivers}
                loading={loading}
                locale={{
                    emptyText: loading ? <Spin /> : <Empty description="Không có dữ liệu" />
                }}
                scroll={{ x: 900 }}
            />

            <Modal
                title="Chi tiết người dùng"
                open={detailModalOpen}
                onCancel={() => setDetailModalOpen(false)}
                footer={null}
                width={600}
            >
                {detailLoading ? (
                    <div className="modal-loading">
                        <Spin />
                    </div>
                ) : detailData ? (
                    <div className="user-detail">
                        <div className="user-detail__header">
                            <Avatar size={64} src={detailData.profilePictureUrl}>
                                {(detailData.name || detailData.email || "?").charAt(0)}
                            </Avatar>
                            <div>
                                <h3>{detailData.name || "Chưa cập nhật"}</h3>
                                <p>{detailData.email}</p>
                                <Tag color={statusColorMap(detailData.status)}>
                                    {formatStatusLabel(detailData.status)}
                                </Tag>
                            </div>
                        </div>
                        <Divider />
                        <div className="user-detail__info">
                            <div>
                                <span>Điện thoại</span>
                                <strong>{detailData.phoneNumber || "—"}</strong>
                            </div>
                            <div>
                                <span>Địa chỉ</span>
                                <strong>{detailData.address || "—"}</strong>
                            </div>
                            <div>
                                <span>Ngày tạo</span>
                                <strong>{detailData.createdAt ? dayjs(detailData.createdAt).format("DD/MM/YYYY HH:mm") : "—"}</strong>
                            </div>
                            <div>
                                <span>Xếp hạng</span>
                                <strong>{detailData.rankingName || "—"}</strong>
                            </div>
                            <div>
                                <span>Điểm tích lũy</span>
                                <strong>{detailData.score ?? 0}</strong>
                            </div>
                        </div>
                        <Divider />
                        <div>
                            <span>Xe đã liên kết</span>
                            {detailData.vehicleModelIds?.length ? (
                                <div className="vehicle-list">
                                    {detailData.vehicleModelIds.map((id) => (
                                        <Tag key={id} color="blue">
                                            {id}
                                        </Tag>
                                    ))}
                                </div>
                            ) : (
                                <p>Chưa liên kết xe</p>
                            )}
                        </div>
                    </div>
                ) : (
                    <Empty description="Không có dữ liệu" />
                )}
            </Modal>

            <Modal
                title="Chỉnh sửa thông tin"
                open={editModalOpen}
                onCancel={() => {
                    setEditModalOpen(false);
                    setEditingDriver(null);
                    form.resetFields();
                }}
                onOk={handleUpdateDriver}
                confirmLoading={submitLoading}
                okText="Lưu thay đổi"
                cancelText="Hủy"
                width={600}
            >
                {detailLoading && !editingDriver ? (
                    <div className="modal-loading">
                        <Spin />
                    </div>
                ) : (
                    <Form layout="vertical" form={form}>
                        <Form.Item label="Tên" name="name" rules={[{ required: true, message: "Vui lòng nhập tên" }]}>
                            <Input placeholder="Nhập tên người dùng" />
                        </Form.Item>
                        <Form.Item label="Số điện thoại" name="phoneNumber">
                            <Input placeholder="Nhập số điện thoại" />
                        </Form.Item>
                        <Form.Item label="Địa chỉ" name="address">
                            <Input placeholder="Nhập địa chỉ" />
                        </Form.Item>
                        <Form.Item label="Ảnh đại diện" name="profilePictureUrl">
                            <Input placeholder="Link ảnh đại diện" />
                        </Form.Item>
                        <Form.Item label="Danh sách Vehicle Model IDs" name="vehicleModelIds">
                            <Select
                                mode="tags"
                                tokenSeparators={[",", " "]}
                                placeholder="Nhập hoặc dán các VehicleModelId"
                            />
                        </Form.Item>
                    </Form>
                )}
            </Modal>
        </div>
    );
};

export default Users;