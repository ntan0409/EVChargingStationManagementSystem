import React, { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { getChargingStationId, updateChargingStationStatus, deleteChargingStation } from "../../../API/Station";
import { getAllChargingPost, deleteChargingPost, addChargingPost, updateChargingPost, updateChargingPostStatus } from "../../../API/ChargingPost";
import { Card, Table, Button, Space, message, Select, Modal, Input, Form } from "antd";
import { ArrowLeftOutlined, EditOutlined, DeleteOutlined, PlusOutlined } from "@ant-design/icons";


const { Option } = Select;

const StaffStationDetail = () => {
    const { stationId } = useParams();
    const navigate = useNavigate();
    const [station, setStation] = useState(null);
    const [posts, setPosts] = useState([]);
    const [loading, setLoading] = useState(false);
    const [modalVisible, setModalVisible] = useState(false);
    const [editingPost, setEditingPost] = useState(null);

    const fetchStationAndPosts = async () => {
        setLoading(true);
        try {
            const stationData = await getChargingStationId(stationId);
            setStation(stationData);

            const postData = await getAllChargingPost(stationId);
            setPosts(postData);
        } catch (error) {
            message.error("Lỗi khi tải dữ liệu trạm sạc!");
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        if (stationId) fetchStationAndPosts();
    }, [stationId]);

    // 🔹 Trạm: Update status
    const handleChangeStationStatus = async (status) => {
        try {
            await updateChargingStationStatus(stationId, status);
            message.success("Cập nhật trạng thái trạm thành công!");
            fetchStationAndPosts();
        } catch (error) {
            message.error("Không thể cập nhật trạng thái trạm!");
        }
    };

    // 🔹 Trạm: Delete
    const handleDeleteStation = async () => {
        Modal.confirm({
            title: "Xác nhận",
            content: "Bạn có chắc muốn xóa trạm này?",
            okText: "Xóa",
            cancelText: "Hủy",
            onOk: async () => {
                try {
                    await deleteChargingStation(stationId);
                    message.success("Xóa trạm thành công!");
                    navigate("/staff/station");
                } catch (error) {
                    message.error("Không thể xóa trạm!");
                }
            },
        });
    };

    // 🔹 Trụ sạc CRUD
    const handleDeletePost = async (postId) => {
        try {
            await deleteChargingPost(postId);
            message.success("Xóa trụ sạc thành công!");
            fetchStationAndPosts();
        } catch (error) {
            message.error("Không thể xóa trụ sạc!");
        }
    };

    const handleEditPost = (post) => {
        setEditingPost(post);
        setModalVisible(true);
    };

    const handleAddPost = () => {
        setEditingPost(null);
        setModalVisible(true);
    };

    const handleSavePost = async (values) => {
        try {
            if (editingPost) {
                await updateChargingPost(editingPost.chargingPostId, { ...values, stationId });
                message.success("Cập nhật trụ sạc thành công!");
            } else {
                await addChargingPost({ ...values, stationId });
                message.success("Thêm trụ sạc thành công!");
            }
            setModalVisible(false);
            fetchStationAndPosts();
        } catch (error) {
            message.error("Lỗi khi lưu trụ sạc!");
        }
    };
    const handleChangePostStatus = async (postId, newStatus) => {
        try {
            await updateChargingPostStatus(postId, newStatus);
            message.success("⚙️ Cập nhật trạng thái trụ sạc thành công!");
            fetchStationAndPosts();
        } catch (error) {
            console.error("updateChargingPostStatus error:", error);
            message.error("Không thể cập nhật trạng thái trụ!");
        }
    };

    const columns = [
        { title: "Tên trụ sạc", dataIndex: "postName", key: "postName" },
        { title: "Kiểu kết nối", dataIndex: "connectorType", key: "connectorType" },
        { title: "Loại xe hỗ trợ", dataIndex: "vehicleTypeSupported", key: "vehicleTypeSupported" },
        { title: "Số cổng", dataIndex: "totalConnectors", key: "totalConnectors" },
        {
            title: "Trạng thái",
            dataIndex: "status",
            key: "status",
            render: (text, record) => (
                <Select
                    value={text}
                    onChange={(value) => handleChangePostStatus(record.id, value)}
                    style={{ width: 150 }}
                >
                    <Option value="Available">Available</Option>
                    {/* <Option value="Busy">Busy</Option> */}
                    <Option value="Maintained">Maintained</Option>
                    <Option value="Inactive">Inactive</Option>
                    {/* <Option value="Faulty">Faulty</Option> */}
                </Select>
            ),
        },
        // {
        //     title: "Hành động",
        //     key: "action",
        //     render: (_, record) => (
        //         <Space>
        //             <Button icon={<EditOutlined />} onClick={() => handleEditPost(record)}>Chi tiết</Button>
        //             {/* <Button icon={<DeleteOutlined />} danger onClick={() => handleDeletePost(record.id)}>Xóa</Button> */}
        //         </Space>
        //     ),
        // },
    ];


    return (
        <div className="p-6">
            <Button type="link" icon={<ArrowLeftOutlined />} onClick={() => navigate("/staff/stations")}>
                Quay lại danh sách trạm
            </Button>

            {station ? (
                <>
                    <Card
                        title={`Thông tin trạm: ${station.stationName}`}
                    // className="mt-3"
                    // extra={
                    //     <Space>
                    //         <Select value={station.status} onChange={handleChangeStationStatus} style={{ width: 150 }}>
                    //             <Option value="active">Active</Option>
                    //             <Option value="inactive">Inactive</Option>
                    //             <Option value="discontinued">Discontinued</Option>
                    //         </Select>
                    //         {/* <Button danger onClick={handleDeleteStation}>Xóa trạm</Button> */}
                    //     </Space>
                    // }
                    >
                        <p><strong>Địa chỉ:</strong> {station.location}</p>
                        <p><strong>Tỉnh/Thành phố:</strong> {station.province}</p>
                        <p><strong>Kinh độ:</strong> {station.longitude}</p>
                        <p><strong>Vĩ độ:</strong> {station.latitude}</p>
                        <p><strong>Nhân viên:</strong> {station.operatorName}</p>
                    </Card>

                    <Card title="Danh sách trụ sạc" className="mt-4" >
                        <Table
                            rowKey="chargingPostId"
                            loading={loading}
                            dataSource={posts}
                            columns={columns}
                            pagination={{ pageSize: 5 }}
                            locale={{ emptyText: "Không có dữ liệu" }}
                        />
                    </Card>

                    <Modal
                        title={editingPost ? "Cập nhật trụ sạc" : "Thêm trụ sạc"}
                        open={modalVisible}
                        onCancel={() => setModalVisible(false)}
                        footer={null}
                    >
                        <Form
                            layout="vertical"
                            initialValues={editingPost || {
                                postName: "",
                                connectorType: "css2",
                                maxPowerKw: 50,
                                vehicleTypeSupported: 1,
                                totalConnectors: 1,
                            }}
                            onFinish={handleSavePost}
                        >
                            <Form.Item
                                name="postName"
                                label="Tên trụ sạc"
                                rules={[{ required: true, message: "Vui lòng nhập tên trụ sạc" }]}
                            >
                                <Input />
                            </Form.Item>

                            <Form.Item
                                name="connectorType"
                                label="Loại cổng sạc"
                                rules={[{ required: true, message: "Vui lòng chọn loại cổng" }]}
                            >
                                <Select>
                                    <Option value="css2">CSS2</Option>
                                    <Option value="ccs1">CCS1</Option>
                                    <Option value="type2">Type2</Option>
                                </Select>
                            </Form.Item>

                            <Form.Item
                                name="maxPowerKw"
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
                                <Button type="primary" htmlType="submit">{editingPost ? "Cập nhật" : "Thêm"}</Button>
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

export default StaffStationDetail;
