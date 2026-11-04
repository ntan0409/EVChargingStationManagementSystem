import React, { useEffect, useState } from "react";
import {
    Table, Button, Modal, Form, Input, Select, message, Popconfirm
} from "antd";
import { GetConnector, PostConnector } from "../../../API/Connector";
import { useParams } from "react-router-dom";

const StaffConnector = () => {
    const { postId } = useParams(); // lấy id của trụ sạc
    const [connectors, setConnectors] = useState([]);
    const [loading, setLoading] = useState(false);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingConnector, setEditingConnector] = useState(null);
    const [form] = Form.useForm();

    const fetchData = async () => {
        try {
            setLoading(true);
            const data = await getConnectors(postId);
            setConnectors(data);
        } catch (err) {
            message.error("Không thể tải danh sách súng sạc!");
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        if (postId) fetchData();
    }, [postId]);

    const handleSave = async () => {
        try {
            const values = await form.validateFields();
            if (editingConnector) {
                await updateConnector(editingConnector.id, { ...values, postId });
                message.success("Cập nhật súng sạc thành công!");
            } else {
                await addConnector({ ...values, postId });
                message.success("Thêm súng sạc mới thành công!");
            }
            setIsModalOpen(false);
            fetchData();
        } catch (err) {
            message.error("Lưu thất bại!");
        }
    };

    const handleDelete = async (id) => {
        try {
            await deleteConnector(id);
            message.success("Xóa súng sạc thành công!");
            fetchData();
        } catch {
            message.error("Không thể xóa!");
        }
    };

    const columns = [
        { title: "Mã Connector", dataIndex: "id", key: "id" },
        { title: "Tên Connector", dataIndex: "connectorName", key: "connectorName" },
        { title: "Công suất (kW)", dataIndex: "powerKw", key: "powerKw" },
        { title: "Trạng thái", dataIndex: "status", key: "status" },
        {
            title: "Thao tác",
            render: (_, record) => (
                <>
                    <Button
                        type="link"
                        onClick={() => {
                            setEditingConnector(record);
                            form.setFieldsValue(record);
                            setIsModalOpen(true);
                        }}
                    >
                        Sửa
                    </Button>
                    <Popconfirm
                        title="Xác nhận xóa connector này?"
                        onConfirm={() => handleDelete(record.id)}
                    >
                        <Button type="link" danger>
                            Xóa
                        </Button>
                    </Popconfirm>
                </>
            ),
        },
    ];

    return (
        <div className="p-6 bg-white rounded-lg shadow-md">
            <h2 className="text-xl font-semibold mb-4">Quản lý súng sạc</h2>
            <Button
                type="primary"
                onClick={() => {
                    setEditingConnector(null);
                    form.resetFields();
                    setIsModalOpen(true);
                }}
                style={{ marginBottom: 16 }}
            >
                + Thêm Connector
            </Button>

            <Table
                loading={loading}
                dataSource={connectors}
                columns={columns}
                rowKey="id"
                locale={{ emptyText: "Không có dữ liệu" }}
            />

            <Modal
                title={editingConnector ? "Chỉnh sửa Connector" : "Thêm Connector mới"}
                open={isModalOpen}
                onCancel={() => setIsModalOpen(false)}
                onOk={handleSave}
            >
                <Form layout="vertical" form={form}>
                    <Form.Item
                        name="connectorName"
                        label="Tên Connector"
                        rules={[{ required: true, message: "Nhập tên Connector!" }]}
                    >
                        <Input />
                    </Form.Item>

                    <Form.Item
                        name="powerKw"
                        label="Công suất (kW)"
                        rules={[{ required: true, message: "Nhập công suất!" }]}
                    >
                        <Input type="number" />
                    </Form.Item>

                    <Form.Item name="status" label="Trạng thái">
                        <Select>
                            <Select.Option value="Active">Active</Select.Option>
                            <Select.Option value="InActive">InActive</Select.Option>
                        </Select>
                    </Form.Item>
                </Form>
            </Modal>
        </div>
    );
};

export default StaffConnector;
