import { useState, useEffect } from "react";
import { Card, Table, Tag, message, Button, Empty } from "antd";
import { ReloadOutlined } from "@ant-design/icons";
import { Receipt, CreditCard, ArrowLeft } from "lucide-react";
import { GetEVDriverTransaction } from "../../API/Transaction";
import { useNavigate } from "react-router-dom";
import "./PaymentHistory.css";



const PaymentHistory = () => {
    const navigate = useNavigate();
    const [payments, setPayments] = useState([]);
    const [loading, setLoading] = useState(false);

    const fetchPaymentHistory = async () => {
        setLoading(true);
        try {
            const response = await GetEVDriverTransaction();
            const data = response?.data || [];
            setPayments(data);
        } catch (error) {
            console.error("Lỗi khi tải lịch sử thanh toán:", error);
            message.error("Không thể tải lịch sử thanh toán!");
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchPaymentHistory();
    }, []);

    const getStatusColor = (status) => {
        switch (status) {
            case "Completed":
            case "Successed":
                return "success";
            case "Failed":
                return "error";
            case "Initiated":
            case "Pending":
                return "warning";
            default:
                return "default";
        }
    };

    const getStatusText = (status) => {
        switch (status) {
            case "Completed":
            case "Successed":
                return "Thành công";
            case "Failed":
                return "Thất bại";
            case "Initiated":
                return "Đang chờ";
            case "Pending":
                return "Chờ xử lý";
            default:
                return status;
        }
    };

    const getTransactionTypeText = (type) => {
        switch (type) {
            case "OnlinePayment":
                return "Thanh toán Online";
            case "OfflinePayment":
                return "Thanh toán Offline";
            default:
                return type;
        }
    };

    const getTransactionTypeIcon = (type) => {
        switch (type) {
            case "OnlinePayment":
                return <CreditCard size={16} />;
            case "OfflinePayment":
                return <Receipt size={16} />;
            default:
                return <Receipt size={16} />;
        }
    };

    const columns = [
        {
            title: "Mã giao dịch",
            dataIndex: "referenceCode",
            key: "referenceCode",
            render: (text) => (
                <span style={{ fontFamily: "monospace", fontWeight: 600 }}>
                    {text}
                </span>
            ),
        },
        {
            title: "Số tiền",
            dataIndex: "amount",
            key: "amount",
            render: (amount) => (
                <span style={{ fontWeight: 600, color: "#00b09b" }}>
                    {Math.round(amount)?.toLocaleString()} VNĐ
                </span>
            ),
        },
        {
            title: "Loại giao dịch",
            dataIndex: "transactionType",
            key: "transactionType",
            render: (type) => (
                <div style={{ display: "flex", alignItems: "center", gap: "6px" }}>
                    {getTransactionTypeIcon(type)}
                    <span>{getTransactionTypeText(type)}</span>
                </div>
            ),
        },
        {
            title: "Trạng thái",
            dataIndex: "status",
            key: "status",
            render: (status) => (
                <Tag color={getStatusColor(status)}>
                    {getStatusText(status)}
                </Tag>
            ),
        },
    ];

    return (
        <div className="payment-history-container">
            <div className="payment-history-header">
                <Button
                    icon={<ArrowLeft size={18} />}
                    onClick={() => navigate(-1)}
                    style={{ marginBottom: "16px" }}
                >
                    Quay lại
                </Button>
            </div>

            <Card
                title={
                    <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
                        <Receipt size={24} />
                        <span>Lịch sử thanh toán</span>
                    </div>
                }
                extra={
                    <Button
                        icon={<ReloadOutlined />}
                        onClick={fetchPaymentHistory}
                        loading={loading}
                    >
                        Tải lại
                    </Button>
                }
                className="payment-history-card"
            >
                {payments.length === 0 && !loading ? (
                    <Empty
                        description="Chưa có giao dịch nào"
                        image={Empty.PRESENTED_IMAGE_SIMPLE}
                    />
                ) : (
                    <Table
                        columns={columns}
                        dataSource={payments}
                        rowKey="id"
                        loading={loading}
                        pagination={false}
                        scroll={{ y: 500 }}
                        locale={{
                            emptyText: "Không có dữ liệu"
                        }}
                    />
                )}
            </Card>
        </div>
    );
};

export default PaymentHistory;
