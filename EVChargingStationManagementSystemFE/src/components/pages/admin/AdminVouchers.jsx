import { useEffect, useState } from "react";
import {
    Card,
    Table,
    Button,
    Space,
    Modal,
    Form,
    Input,
    InputNumber,
    DatePicker,
    Switch,
    message,
    Tag,
    Tooltip,
    Empty
} from "antd";
import {
    PlusOutlined,
    EditOutlined,
    DeleteOutlined,
    ReloadOutlined
} from "@ant-design/icons";
import { GetVoucher, PostVoucher, UpdateVoucher, DeleteVoucher } from "../../../API/Voucher";
import dayjs from "dayjs";
import "./AdminVouchers.css";

const { TextArea } = Input;
const { RangePicker } = DatePicker;

const AdminVouchers = () => {
    const [vouchers, setVouchers] = useState([]);
    const [loading, setLoading] = useState(false);
    const [noData, setNoData] = useState(false);
    const [hasError, setHasError] = useState(false);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingVoucher, setEditingVoucher] = useState(null);
    const [form] = Form.useForm();

    useEffect(() => {
        fetchVouchers();
    }, []);

    const fetchVouchers = async () => {
        setLoading(true);
        try {
            const response = await GetVoucher();
            const data = response?.data || [];
            setVouchers(data);
            setNoData(false);
            setHasError(false);
        } catch (error) {
            console.log('Full error:', error);

            const status = error?.response?.status;
            const errorMessage =
                error?.customMessage ||
                error?.response?.data?.message ||
                error?.message ||
                'Đã xảy ra lỗi';

            // Chỉ không bắn toast nếu là lỗi 404 VÀ thông điệp đúng
            const isNoDataError = status === 404 && errorMessage.includes('Không tìm thấy');

            if (isNoDataError) {
                console.log('Không có voucher nào');
                setNoData(true);
                setHasError(false);
            } else {
                message.error(errorMessage); // ✅ Bắn toast cho tất cả lỗi khác
                setHasError(true);
                setNoData(false);
            }

            setVouchers([]);
        } finally {
            setLoading(false);
        }
    };

    const handleAdd = () => {
        setEditingVoucher(null);
        form.resetFields();
        setIsModalOpen(true);
    };

    const handleEdit = (record) => {
        setEditingVoucher(record);
        form.setFieldsValue({
            name: record.name,
            description: record.description,
            requiredPoints: record.requiredPoints,
            value: record.value,
            voucherType: record.voucherType,
            dateRange: [dayjs(record.validFrom), dayjs(record.validTo)],
            isActive: record.isActive
        });
        setIsModalOpen(true);
    };

    const handleDelete = async (id) => {
        Modal.confirm({
            title: "Xác nhận xóa",
            content: "Bạn có chắc chắn muốn xóa voucher này?",
            okText: "Xóa",
            cancelText: "Hủy",
            okButtonProps: { danger: true },
            onOk: async () => {
                try {
                    await DeleteVoucher(id);
                    message.success("Xóa voucher thành công!");
                    fetchVouchers();
                } catch (error) {
                    console.error("Lỗi khi xóa:", error);
                    message.error("Không thể xóa voucher!");
                }
            }
        });
    };

    const handleSubmit = async () => {
        try {
            const values = await form.validateFields();
            const payload = {
                name: values.name,
                description: values.description,
                requiredPoints: values.requiredPoints,
                value: values.value,
                voucherType: values.voucherType,
                validFrom: values.dateRange[0].toISOString(),
                validTo: values.dateRange[1].toISOString(),
                isActive: values.isActive ?? true
            };

            if (editingVoucher) {
                await UpdateVoucher(editingVoucher.id, payload);
                message.success("Cập nhật voucher thành công!");
            } else {
                await PostVoucher(payload);
                message.success("Thêm voucher thành công!");
            }

            setIsModalOpen(false);
            form.resetFields();
            fetchVouchers();
        } catch (error) {
            console.error("Lỗi khi lưu voucher:", error);
            message.error("Có lỗi xảy ra!");
        }
    };

    const columns = [
        {
            title: "Tên voucher",
            dataIndex: "name",
            key: "name",
            width: 150
        },
        {
            title: "Mô tả",
            dataIndex: "description",
            key: "description",
            width: 200
        },
        {
            title: "Loại",
            dataIndex: "voucherType",
            key: "voucherType",
            width: 180,
            render: (type) => <Tag color="blue">{type}</Tag>
        },
        {
            title: "Giá trị",
            dataIndex: "value",
            key: "value",
            width: 120,
            align: "right",
            render: (value) => (
                <span className="font-semibold text-green-600">
                    {value?.toLocaleString('vi-VN')} VNĐ
                </span>
            )
        },
        {
            title: "Điểm yêu cầu",
            dataIndex: "requiredPoints",
            key: "requiredPoints",
            width: 120,
            align: "center"
        },
        {
            title: "Hiệu lực từ",
            dataIndex: "validFrom",
            key: "validFrom",
            width: 120,
            render: (date) => dayjs(date).format("DD/MM/YYYY")
        },
        {
            title: "Hiệu lực đến",
            dataIndex: "validTo",
            key: "validTo",
            width: 120,
            render: (date) => dayjs(date).format("DD/MM/YYYY")
        },
        {
            title: "Trạng thái",
            dataIndex: "isActive",
            key: "isActive",
            width: 100,
            align: "center",
            render: (isActive) => (
                <Tag color={isActive ? "success" : "default"}>
                    {isActive ? "Hoạt động" : "Tạm dừng"}
                </Tag>
            )
        },
        {
            title: "Thao tác",
            key: "action",
            width: 120,
            fixed: "right",
            render: (_, record) => (
                <Space>
                    <Tooltip title="Chỉnh sửa">
                        <Button
                            type="link"
                            icon={<EditOutlined />}
                            onClick={() => handleEdit(record)}
                        />
                    </Tooltip>
                    <Tooltip title="Xóa">
                        <Button
                            type="link"
                            danger
                            icon={<DeleteOutlined />}
                            onClick={() => handleDelete(record.id)}
                        />
                    </Tooltip>
                </Space>
            )
        }
    ];

    return (
        <div className="admin-vouchers-container">
            <Card
                title={<span className="card-title">🎟️ Quản Lý Voucher</span>}
                extra={
                    <Space>
                        <Button
                            icon={<ReloadOutlined />}
                            onClick={fetchVouchers}
                            loading={loading}
                        >
                            Tải lại
                        </Button>
                        <Button
                            type="primary"
                            icon={<PlusOutlined />}
                            onClick={handleAdd}
                        >
                            Thêm voucher
                        </Button>
                    </Space>
                }
            >
                {hasError ? (
                    <Empty description="Đã xảy ra lỗi khi tải dữ liệu" />
                ) : noData || vouchers.length === 0 ? (
                    <Empty description="Không có voucher nào" />
                ) : (
                    <Table
                        columns={columns}
                        dataSource={vouchers}
                        rowKey="id"
                        loading={loading}
                        pagination={false}
                        scroll={{ x: 1200, y: 500 }}
                        sticky
                    />
                )}
            </Card>

            <Modal
                title={editingVoucher ? "Chỉnh sửa voucher" : "Thêm voucher mới"}
                open={isModalOpen}
                onOk={handleSubmit}
                onCancel={() => {
                    setIsModalOpen(false);
                    form.resetFields();
                }}
                okText={editingVoucher ? "Cập nhật" : "Thêm"}
                cancelText="Hủy"
                width={600}
            >
                <Form form={form} layout="vertical">
                    <Form.Item
                        label="Tên voucher"
                        name="name"
                        rules={[{ required: true, message: "Vui lòng nhập tên voucher!" }]}
                    >
                        <Input placeholder="VD: Giảm 10%" />
                    </Form.Item>

                    <Form.Item
                        label="Mô tả"
                        name="description"
                        rules={[{ required: true, message: "Vui lòng nhập mô tả!" }]}
                    >
                        <TextArea rows={3} placeholder="Mô tả chi tiết về voucher" />
                    </Form.Item>

                    <Form.Item
                        label="Loại voucher"
                        name="voucherType"
                        rules={[{ required: true, message: "Vui lòng nhập loại voucher!" }]}
                    >
                        <Input placeholder="VD: Tặng khách hàng mới" />
                    </Form.Item>

                    <Form.Item
                        label="Giá trị (VNĐ)"
                        name="value"
                        rules={[{ required: true, message: "Vui lòng nhập giá trị!" }]}
                    >
                        <InputNumber
                            min={0}
                            style={{ width: "100%" }}
                            formatter={value => `${value}`.replace(/\B(?=(\d{3})+(?!\d))/g, ',')}
                            parser={value => value.replace(/\$\s?|(,*)/g, '')}
                        />
                    </Form.Item>

                    <Form.Item
                        label="Điểm yêu cầu"
                        name="requiredPoints"
                        rules={[{ required: true, message: "Vui lòng nhập điểm yêu cầu!" }]}
                    >
                        <InputNumber min={0} style={{ width: "100%" }} />
                    </Form.Item>

                    <Form.Item
                        label="Thời gian hiệu lực"
                        name="dateRange"
                        rules={[{ required: true, message: "Vui lòng chọn thời gian!" }]}
                    >
                        <RangePicker
                            style={{ width: "100%" }}
                            format="DD/MM/YYYY"
                            placeholder={["Từ ngày", "Đến ngày"]}
                        />
                    </Form.Item>

                    <Form.Item
                        label="Trạng thái"
                        name="isActive"
                        valuePropName="checked"
                        initialValue={true}
                    >
                        <Switch checkedChildren="Hoạt động" unCheckedChildren="Tạm dừng" />
                    </Form.Item>
                </Form>
            </Modal>
        </div>
    );
};

export default AdminVouchers;
