import { useState, useEffect } from "react";
import { Card, Button, message, List, Select } from "antd";
import { PatchPaymentOfflineStatus, getPaymentThatHaveSend } from "../../../API/Payment";
import { ToastContainer, toast } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";
const { Option } = Select;

const ConfirmPaymentOffline = () => {
    const [payments, setPayments] = useState([]);
    const [filteredPayments, setFilteredPayments] = useState([]);
    const [loading, setLoading] = useState(false);
    const [statusFilter, setStatusFilter] = useState("All");

    // Lấy danh sách payment đã gửi
    const fetchPayments = async () => {
        try {
            setLoading(true);
            const res = await getPaymentThatHaveSend();
            const data = res?.data || [];
            // Sắp xếp Initiated lên đầu, mới nhất trước
            data.sort((a, b) => {
                if (a.status === "Initiated" && b.status !== "Initiated") return -1;
                if (a.status !== "Initiated" && b.status === "Initiated") return 1;
                return new Date(b.createdAt) - new Date(a.createdAt);
            });
            setPayments(data);
            filterPayments(data, statusFilter);
        } catch (error) {
            console.log('ErrorGetPayment', error);
            message.error("❌ Lỗi khi lấy danh sách thanh toán.");
        } finally {
            setLoading(false);
        }
    };
    const statusVietnamese = {
        Successed: "Thành Công",
        Failed: "Thất Bại",
        Initiated: "Đang Chờ Xác Nhận",
    };

    useEffect(() => {
        fetchPayments();
    }, []);

    // Filter payment theo status và giữ sắp xếp
    const filterPayments = (data, status) => {
        let filtered = status === "All" ? [...data] : data.filter(p => p.status === status);

        // Sort Initiated lên trước, mới nhất trước
        filtered.sort((a, b) => {
            if (a.status === "Initiated" && b.status !== "Initiated") return -1;
            if (a.status !== "Initiated" && b.status === "Initiated") return 1;
            return new Date(b.createdAt) - new Date(a.createdAt);
        });

        setFilteredPayments(filtered);
    };

    // Khi đổi filter
    const handleStatusChange = (value) => {
        setStatusFilter(value);
        filterPayments(payments, value);
    };

    // Cập nhật trạng thái offline
    const handleUpdateOfflineStatus = async (paymentId) => {
        if (!paymentId) {
            message.warning("Vui lòng chọn paymentId.");
            return;
        }
        try {
            setLoading(true);
            await PatchPaymentOfflineStatus(paymentId);
            message.success(`Cập nhật trạng thái thanh toán thành công!`);
            toast.success("Xác Nhận Thanh Toán Thành Công");
            fetchPayments(); // Làm mới danh sách
        } catch (error) {
            message.error("❌ Lỗi khi cập nhật trạng thái thanh toán.");
            toast.error("Xác Nhận Thất Bại");
            console.error(error);
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="flex justify-center items-start min-h-screen bg-pink-50 py-10">
            <Card
                title="Xác nhận thanh toán Offline"
                bordered={false}
                className="shadow-lg w-[600px] rounded-2xl"
            >
                <div className="mb-4 flex justify-between items-center">
                    <Button type="primary" onClick={fetchPayments} loading={loading}>
                        Tải lại danh sách
                    </Button>
                    <Select
                        value={statusFilter}
                        style={{ width: 180 }}
                        onChange={handleStatusChange}
                    >
                        <Option value="All">Tất cả trạng thái</Option>
                        <Option value="Successed">Thành Công</Option>
                        <Option value="Failed">Thất Bại</Option>
                        <Option value="Initiated">Đang Chờ Xác Nhận</Option>
                    </Select>
                </div>

                <List
                    loading={loading}
                    dataSource={filteredPayments}
                    locale={{ emptyText: "Không có thanh toán nào" }}
                    renderItem={(item) => (
                        <List.Item
                            actions={
                                item.status === "Initiated"
                                    ? [
                                        <Button
                                            type="default"
                                            size="small"
                                            onClick={() => handleUpdateOfflineStatus(item.id)}
                                            loading={loading}
                                        >
                                            Xác Nhận Thanh Toán
                                        </Button>
                                    ]
                                    : []
                            }
                        >
                            <div>
                                <p><b>Số Tiền:</b> {item.amount}</p>
                                <p><b>Số Tiền Chưa Thuế:</b> {item.beforeVatAmount}</p>
                                <p><b>Số Thuế:</b> {item.taxRate}%</p>
                                <p><b>Phương Thức Thanh Toán:</b> {item.paymentMethod}</p>
                                <p><b>Tạo Ngày:</b> {new Date(item.createdAt).toLocaleString()}</p>
                                <p><b>Trạng Thái:</b> {statusVietnamese[item.status] || item.status}</p>
                            </div>
                        </List.Item>
                    )}
                />
            </Card>
            <ToastContainer position="top-right" autoClose={2000} />
        </div>
    );
};

export default ConfirmPaymentOffline;
