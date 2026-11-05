import { useEffect, useState } from "react";
import {
    Button, Table, Modal, Input, Form,
    Space, Tooltip, Select, Empty, Avatar
} from "antd";
import {
    EditOutlined, DeleteOutlined, PlusOutlined,
    SearchOutlined, UserOutlined, MailOutlined,
    PhoneOutlined, HomeOutlined, LockOutlined
} from "@ant-design/icons";
import { toast } from "react-toastify";
import {
    getAllStaff, createStaffAccount, updateStaffInfo,
    updateStaffStatus, deleteStaff
} from "../../../API/Staff";
import "./Staff.css";

const AdminStaff = () => {
    const [form] = Form.useForm();
    const [loading, setLoading] = useState(false);
    const [noData, setNoData] = useState(false);
    const [hasError, setHasError] = useState(false);
    const [staffList, setStaffList] = useState([]);
    const [filteredStaff, setFilteredStaff] = useState([]);
    const [searchText, setSearchText] = useState("");
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingStaff, setEditingStaff] = useState(null);

    /* ==================== FETCH ==================== */
    const fetchStaff = async () => {
        setLoading(true);
        try {
            const res = await getAllStaff();
            const list = Array.isArray(res.data) ? res.data : [];
            setStaffList(list);
            setFilteredStaff(list);
            setNoData(false);
            setHasError(false);
        } catch (err) {
            console.log('Full error:', err);

            const status = err?.response?.status;
            const errorMsg = err?.customMessage || err?.response?.data?.message || err?.message || "Đã xảy ra lỗi";

            // Chỉ không bắn toast nếu là lỗi 404 VÀ thông điệp đúng
            const isNoDataError = status === 404 && errorMsg.includes('Không tìm thấy');

            if (isNoDataError) {
                console.log('Không có nhân viên nào');
                setNoData(true);
                setHasError(false);
            } else {
                toast.error(errorMsg); // ✅ Bắn toast cho tất cả lỗi khác
                setHasError(true);
                setNoData(false);
            }

            setStaffList([]);
            setFilteredStaff([]);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => { fetchStaff(); }, []);

    /* ==================== SEARCH ==================== */
    useEffect(() => {
        const kw = searchText.trim().toLowerCase();
        const filtered = staffList.filter(s =>
            s.name?.toLowerCase().includes(kw) ||
            s.email?.toLowerCase().includes(kw) ||
            s.phoneNumber?.includes(searchText)
        );
        setFilteredStaff(filtered);
    }, [searchText, staffList]);

    /* ==================== SUBMIT ==================== */
    const handleSubmit = async (values) => {
        try {
            if (editingStaff) {
                // 🟢 Cập nhật nhân viên
                const payload = {
                    staffId: editingStaff.id, // id = profileId
                    name: values.name,
                    email: values.email,
                    phoneNumber: values.phoneNumber,
                    address: values.address,
                    profilePictureUrl: values.profilePictureUrl || "",
                    workingLocation: values.workingLocation || "",
                };
                const res = await updateStaffInfo(payload);
                toast.success(res.message || "Cập nhật nhân viên thành công");
            } else {
                // 🟢 Thêm mới nhân viên
                const payload = {
                    email: values.email,
                    password: values.password,
                    confirmPassword: values.confirmPassword,
                    name: values.name,
                    phoneNumber: values.phoneNumber,
                    address: values.address,
                    profilePictureUrl: values.profilePictureUrl || "",
                    workingLocation: values.workingLocation || "",
                };
                const res = await createStaffAccount(payload);
                toast.success(res.message || "Tạo tài khoản nhân viên thành công");
            }
            closeModal();
            fetchStaff();
        } catch (err) {
            const errorMsg = err.response?.data?.message || err.message || "Thao tác thất bại";
            toast.error(errorMsg);
        }
    };

    const closeModal = () => {
        setIsModalOpen(false);
        form.resetFields();
        setEditingStaff(null);
    };

    /* ==================== STATUS & DELETE ==================== */
    const handleChangeStatus = async (staffId, status) => {
        try {
            const res = await updateStaffStatus(staffId, status);
            toast.success(res.message || "Cập nhật trạng thái thành công");
            fetchStaff();
        } catch (err) {
            const errorMsg = err.response?.data?.message || err.message || "Cập nhật thất bại";
            toast.error(errorMsg);
        }
    };

    const handleDelete = async (staffId) => {
        if (!window.confirm("Xóa nhân viên này?")) return;
        try {
            await deleteStaff(staffId);
            toast.success("Xóa nhân viên thành công");
            fetchStaff();
        } catch (err) {
            const errorMsg = err.response?.data?.message || err.message || "Xóa thất bại";
            toast.error(errorMsg);
        }
    };

    const handleEdit = (record) => {
        setEditingStaff(record);
        form.setFieldsValue({
            name: record.name,
            email: record.email,
            phoneNumber: record.phoneNumber,
            address: record.address,
            profilePictureUrl: record.profilePictureUrl,
            workingLocation: record.workingLocation,
        });
        setIsModalOpen(true);
    };

    const columns = [
        {
            title: "Nhân viên",
            key: "info",
            render: (_, r) => (
                <div className="staff-info">
                    <Avatar size={40} style={{ backgroundColor: '#3b82f6' }}>
                        {(r.name || "?").charAt(0).toUpperCase()}
                    </Avatar>
                    <div className="staff-details">
                        <div className="staff-name">{r.name || "Chưa cập nhật"}</div>
                        <div className="staff-email">{r.email || "Không có email"}</div>
                    </div>
                </div>
            ),
        },
        { title: "SĐT", dataIndex: "phoneNumber", render: t => t || "—" },
        { title: "Địa chỉ", dataIndex: "address", render: t => t || "—" },
        {
            title: "Trạng thái",
            dataIndex: "status",
            render: (s, r) => (
                <Select
                    size="small"
                    value={s}
                    style={{ width: 150 }}
                    onChange={v => handleChangeStatus(r.id, v)}
                    options={[
                        { value: "Active", label: "Hoạt động" },
                        { value: "Inactive", label: "Không hoạt động" },
                    ]}
                />
            ),
        },
        {
            title: "Ngày tạo",
            dataIndex: "createdAt",
            render: d => d ? new Date(d).toLocaleDateString("vi-VN") : "—",
        },
        {
            title: "Thao tác",
            key: "actions",
            render: (_, r) => (
                <Space>
                    <Tooltip title="Sửa">
                        <Button size="small" icon={<EditOutlined />} onClick={() => handleEdit(r)} />
                    </Tooltip>
                    <Tooltip title="Xóa">
                        <Button
                            danger
                            size="small"
                            icon={<DeleteOutlined />}
                            onClick={() => handleDelete(r.id)}
                        />
                    </Tooltip>
                </Space>
            ),
        },
    ];

    return (
        <div className="admin-staff">
            <div className="header">
                <h1>Quản lý nhân viên</h1>
                <p>Quản lý thông tin, trạng thái và tài khoản nhân viên</p>
            </div>

            <div className="actions-card">
                <div className="actions-container">
                    <Input
                        placeholder="Tìm tên, email, SĐT..."
                        prefix={<SearchOutlined />}
                        value={searchText}
                        onChange={e => setSearchText(e.target.value)}
                        allowClear
                        style={{ width: '60%' }}
                    />
                    <Button
                        type="primary"
                        icon={<PlusOutlined />}
                        onClick={() => {
                            setEditingStaff(null);
                            form.resetFields();
                            setIsModalOpen(true);
                        }}
                        className="add-btn"
                    >
                        Thêm nhân viên
                    </Button>
                </div>
            </div>

            <div className="table-card">
                {hasError ? (
                    <Empty description="Đã xảy ra lỗi khi tải dữ liệu" />
                ) : noData || filteredStaff.length === 0 ? (
                    <Empty description="Không có nhân viên nào" />
                ) : (
                    <Table
                        columns={columns}
                        dataSource={filteredStaff}
                        rowKey="id"
                        loading={loading}
                        pagination={false}
                        scroll={{ x: 1200, y: 600 }}
                        sticky
                    />
                )}
            </div>

            {/* Modal thêm/sửa */}
            <Modal
                title={editingStaff ? "Cập nhật nhân viên" : "Thêm nhân viên mới"}
                open={isModalOpen}
                onCancel={closeModal}
                footer={null}
            >
                <Form form={form} layout="vertical" onFinish={handleSubmit}>
                    <Form.Item
                        name="email"
                        label="Email"
                        rules={[
                            { required: true, message: "Vui lòng nhập email" },
                            { type: "email", message: "Email không hợp lệ" },
                        ]}
                    >
                        <Input prefix={<MailOutlined />} placeholder="Nhập email nhân viên" />
                    </Form.Item>

                    {!editingStaff && (
                        <>
                            <Form.Item
                                name="password"
                                label="Mật khẩu"
                                rules={[{ required: true, message: "Vui lòng nhập mật khẩu" }]}
                                hasFeedback
                            >
                                <Input.Password prefix={<LockOutlined />} placeholder="Nhập mật khẩu" />
                            </Form.Item>

                            <Form.Item
                                name="confirmPassword"
                                label="Xác nhận mật khẩu"
                                dependencies={["password"]}
                                hasFeedback
                                rules={[
                                    { required: true, message: "Vui lòng xác nhận mật khẩu" },
                                    ({ getFieldValue }) => ({
                                        validator(_, value) {
                                            if (!value || getFieldValue("password") === value) return Promise.resolve();
                                            return Promise.reject(new Error("Mật khẩu không khớp!"));
                                        },
                                    }),
                                ]}
                            >
                                <Input.Password prefix={<LockOutlined />} placeholder="Nhập lại mật khẩu" />
                            </Form.Item>
                        </>
                    )}

                    <Form.Item name="name" label="Họ và tên" rules={[{ required: true, message: "Vui lòng nhập họ tên" }]}>
                        <Input prefix={<UserOutlined />} placeholder="VD: Nguyễn Văn A" />
                    </Form.Item>

                    <Form.Item
                        name="phoneNumber"
                        label="Số điện thoại"
                        rules={[{ required: true, message: "Vui lòng nhập số điện thoại" }]}
                    >
                        <Input prefix={<PhoneOutlined />} placeholder="VD: 0912345678" />
                    </Form.Item>

                    <Form.Item name="address" label="Địa chỉ">
                        <Input prefix={<HomeOutlined />} placeholder="Nhập địa chỉ cư trú" />
                    </Form.Item>

                    <Form.Item name="profilePictureUrl" label="Ảnh đại diện (tuỳ chọn)">
                        <Input prefix={<UserOutlined />} placeholder="Nhập URL ảnh hoặc để trống" />
                    </Form.Item>

                    <Form.Item>
                        <Button type="primary" htmlType="submit" block icon={<PlusOutlined />}>
                            {editingStaff ? "Lưu thay đổi" : "Tạo tài khoản nhân viên"}
                        </Button>
                    </Form.Item>
                </Form>
            </Modal>
        </div>
    );
};

export default AdminStaff;
