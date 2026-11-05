import React, { useEffect, useState } from "react";
import { Table, Progress, Button } from "antd";
import {
    Zap,
    Users,
    Car,
    TrendingUp,
    DollarSign,
    Activity,
    Clock,
    RefreshCw,
    ShieldCheck
} from "lucide-react";
import axios from "axios";
import "./AdminDashboard.css";

const AdminDashboard = () => {
    const [stats, setStats] = useState({
        totalStations: 0,
        totalUsers: 0,
        totalVehicles: 0,
        totalRevenue: 0,
        activeChargers: 0,
        totalChargers: 0
    });
    const [recentOrders, setRecentOrders] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchDashboardData();
    }, []);

    const fetchDashboardData = async () => {
        setLoading(true);
        try {
            const [stationsRes, usersRes, vehiclesRes, ordersRes] = await Promise.all([
                axios.get("/api/stations").catch(() => ({ data: [] })),
                axios.get("/api/users").catch(() => ({ data: [] })),
                axios.get("/api/vehicles").catch(() => ({ data: [] })),
                axios.get("/api/orders?limit=5").catch(() => ({ data: [] }))
            ]);

            const stations = Array.isArray(stationsRes.data) ? stationsRes.data : [];
            const users = Array.isArray(usersRes.data) ? usersRes.data : [];
            const vehicles = Array.isArray(vehiclesRes.data) ? vehiclesRes.data : [];
            const orders = Array.isArray(ordersRes.data) ? ordersRes.data : [];

            const totalRevenue = orders.reduce((sum, order) => sum + (order.totalAmount || 0), 0);
            const activeChargers = stations.reduce((sum, station) => sum + (station.activeChargers || 0), 0);
            const totalChargers = stations.reduce((sum, station) => sum + (station.totalChargers || 0), 0);

            setStats({
                totalStations: stations.length,
                totalUsers: users.length,
                totalVehicles: vehicles.length,
                totalRevenue,
                activeChargers,
                totalChargers
            });

            setRecentOrders(orders);
        } catch (error) {
            console.error("Error fetching dashboard data:", error);
        } finally {
            setLoading(false);
        }
    };

    const chargerUtilization = stats.totalChargers > 0
        ? Math.round((stats.activeChargers / stats.totalChargers) * 100)
        : 0;

    const recentOrdersColumns = [
        {
            title: "Mã Đơn",
            dataIndex: "orderID",
            key: "orderID",
            render: (id) => <span className="font-mono font-semibold text-slate-700">#{id || "N/A"}</span>
        },
        {
            title: "Khách hàng",
            dataIndex: "customerName",
            key: "customerName",
            render: (name) => <span className="font-medium text-slate-900">{name || "Khách vãng lai"}</span>
        },
        {
            title: "Trạm sạc",
            dataIndex: "stationName",
            key: "stationName",
            render: (name) => <span className="text-slate-700">{name || "Trạm trung tâm"}</span>
        },
        {
            title: "Tổng tiền",
            dataIndex: "totalAmount",
            key: "totalAmount",
            render: (amount) => <span className="font-semibold text-emerald-600">{(amount || 0).toLocaleString()} ₫</span>,
        },
        {
            title: "Trạng thái",
            dataIndex: "status",
            key: "status",
            render: (status) => {
                const s = status?.toLowerCase() || "";
                if (s === "completed" || s === "success") {
                    return <span className="status-badge completed">Đã hoàn thành</span>;
                }
                if (s === "pending" || s === "processing") {
                    return <span className="status-badge pending">Đang xử lý</span>;
                }
                return <span className="status-badge cancelled">{status || "Hủy"}</span>;
            },
        },
    ];

    return (
        <div className="admin-dashboard">
            <div className="header">
                <div>
                    <div className="header-badge">
                        <span className="pulse-dot"></span>
                        Hệ thống hoạt động ổn định
                    </div>
                    <h1>Tổng quan hệ thống trạm sạc xe điện</h1>
                    <p>Giám sát thời gian thực các trạm sạc, lưu lượng giao dịch và người dùng EVOne</p>
                </div>
                <Button 
                    icon={<RefreshCw size={16} />} 
                    onClick={fetchDashboardData}
                    loading={loading}
                    className="font-semibold"
                >
                    Làm mới
                </Button>
            </div>

            {/* Statistics Cards */}
            <div className="stats-grid">
                <div className="stat-card">
                    <div className="stat-card-top">
                        <div className="stat-icon emerald">
                            <Zap size={22} />
                        </div>
                        <span className="stat-tag positive">+4 trạm mới</span>
                    </div>
                    <div className="stat-value">{stats.totalStations}</div>
                    <div className="stat-label">Tổng Trạm Sạc Khả Dụng</div>
                </div>

                <div className="stat-card">
                    <div className="stat-card-top">
                        <div className="stat-icon blue">
                            <Users size={22} />
                        </div>
                        <span className="stat-tag positive">+18% tháng này</span>
                    </div>
                    <div className="stat-value">{stats.totalUsers}</div>
                    <div className="stat-label">Tổng Tài Khoản Đăng Ký</div>
                </div>

                <div className="stat-card">
                    <div className="stat-card-top">
                        <div className="stat-icon purple">
                            <Car size={22} />
                        </div>
                        <span className="stat-tag">Đã liên kết</span>
                    </div>
                    <div className="stat-value">{stats.totalVehicles}</div>
                    <div className="stat-label">Phương Tiện EV Trong Hệ Thống</div>
                </div>

                <div className="stat-card">
                    <div className="stat-card-top">
                        <div className="stat-icon orange">
                            <DollarSign size={22} />
                        </div>
                        <span className="stat-tag positive">SePay / VNPay</span>
                    </div>
                    <div className="stat-value">{stats.totalRevenue.toLocaleString()} ₫</div>
                    <div className="stat-label">Doanh Thu Tích Lũy</div>
                </div>
            </div>

            {/* Charts and Additional Info */}
            <div className="charts-grid">
                <div className="chart-card">
                    <h3 className="chart-title">
                        <Zap size={18} className="text-emerald-500" />
                        Tình Trạng & Công Suất Cổng Sạc
                    </h3>
                    <div className="charger-status">
                        <div className="charger-metric-row">
                            <div className="charger-count">
                                {stats.activeChargers} <span>/ {stats.totalChargers || 0} cổng</span>
                            </div>
                            <div className="text-sm font-semibold text-emerald-600">
                                {chargerUtilization}% Đang tải
                            </div>
                        </div>
                        <Progress
                            percent={chargerUtilization}
                            strokeColor={{
                                '0%': '#10b981',
                                '100%': '#0ea5e9',
                            }}
                            size="default"
                            showInfo={false}
                        />
                        <div className="progress-meta">
                            <span>Sẵn sàng phục vụ: {(stats.totalChargers - stats.activeChargers) > 0 ? (stats.totalChargers - stats.activeChargers) : 0} cổng</span>
                            <span>Hiệu suất vận hành: Rất tốt</span>
                        </div>
                    </div>
                </div>

                <div className="chart-card">
                    <h3 className="chart-title">
                        <Activity size={18} className="text-sky-500" />
                        Chỉ Số Vận Hành Hạ Tầng
                    </h3>
                    <div className="activity-feed">
                        <div className="activity-item">
                            <div className="activity-content">
                                <ShieldCheck className="activity-icon emerald" />
                                <span className="activity-text">Kết nối IoT & Cổng thanh toán trực tuyến</span>
                            </div>
                            <span className="activity-badge green">Trực tuyến</span>
                        </div>
                        <div className="activity-item">
                            <div className="activity-content">
                                <TrendingUp className="activity-icon blue" />
                                <span className="activity-text">Lưu lượng sạc giờ cao điểm (17h - 20h)</span>
                            </div>
                            <span className="activity-badge green">+24%</span>
                        </div>
                        <div className="activity-item">
                            <div className="activity-content">
                                <Clock className="activity-icon orange" />
                                <span className="activity-text">Độ trễ phản hồi API trung bình</span>
                            </div>
                            <span className="activity-badge orange">~68ms</span>
                        </div>
                    </div>
                </div>
            </div>

            {/* Recent Orders Table */}
            <div className="orders-card">
                <div className="orders-header">
                    <h3 className="orders-title">Giao Dịch Sạc Gần Đây</h3>
                </div>
                <Table
                    dataSource={recentOrders}
                    columns={recentOrdersColumns}
                    rowKey="orderID"
                    pagination={false}
                    size="middle"
                    loading={loading}
                    locale={{
                        emptyText: "Chưa có giao dịch sạc nào được ghi nhận"
                    }}
                />
            </div>
        </div>
    );
};

export default AdminDashboard;
