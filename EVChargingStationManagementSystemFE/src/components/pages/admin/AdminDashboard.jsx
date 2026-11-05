import React, { useEffect, useState } from "react";
import { Card, Row, Col, Statistic, Table, Progress } from "antd";
import {
    Zap,
    Users,
    Car,
    TrendingUp,
    DollarSign,
    Activity,
    Clock
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
        try {
            // Fetch statistics
            const [stationsRes, usersRes, vehiclesRes, ordersRes] = await Promise.all([
                axios.get("/api/stations"),
                axios.get("/api/users"),
                axios.get("/api/vehicles"),
                axios.get("/api/orders?limit=5")
            ]);

            const stations = Array.isArray(stationsRes.data) ? stationsRes.data : [];
            const users = Array.isArray(usersRes.data) ? usersRes.data : [];
            const vehicles = Array.isArray(vehiclesRes.data) ? vehiclesRes.data : [];
            const orders = Array.isArray(ordersRes.data) ? ordersRes.data : [];

            // Calculate statistics
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
            // Set default values on error
            setStats({
                totalStations: 0,
                totalUsers: 0,
                totalVehicles: 0,
                totalRevenue: 0,
                activeChargers: 0,
                totalChargers: 0
            });
            setRecentOrders([]);
        } finally {
            setLoading(false);
        }
    };

    const chargerUtilization = stats.totalChargers > 0
        ? Math.round((stats.activeChargers / stats.totalChargers) * 100)
        : 0;

    const recentOrdersColumns = [
        {
            title: "ID Đơn hàng",
            dataIndex: "orderID",
            key: "orderID",
        },
        {
            title: "Khách hàng",
            dataIndex: "customerName",
            key: "customerName",
        },
        {
            title: "Trạm sạc",
            dataIndex: "stationName",
            key: "stationName",
        },
        {
            title: "Tổng tiền",
            dataIndex: "totalAmount",
            key: "totalAmount",
            render: (amount) => `${amount?.toLocaleString()} VNĐ`,
        },
        {
            title: "Trạng thái",
            dataIndex: "status",
            key: "status",
            render: (status) => (
                <span className={`px-2 py-1 rounded text-xs ${status === "Completed" ? "bg-green-100 text-green-800" :
                    status === "Pending" ? "bg-yellow-100 text-yellow-800" :
                        "bg-red-100 text-red-800"
                    }`}>
                    {status === "Completed" ? "Hoàn thành" :
                        status === "Pending" ? "Đang xử lý" : "Hủy"}
                </span>
            ),
        },
    ];

    if (loading) {
        return (
            <div className="flex items-center justify-center h-64">
                <div className="text-lg">Đang tải dữ liệu...</div>
            </div>
        );
    }

    return (
        <div className="admin-dashboard">
            <div className="header">
                <h1>Tổng quan hệ thống trạm sạc xe điện</h1>
            </div>

            {/* Statistics Cards */}
            <div className="stats-grid">
                <div className="stat-card">
                    <div className="stat-icon blue">
                        <Zap size={24} />
                    </div>
                    <div className="stat-value">{stats.totalStations}</div>
                    <div className="stat-label">Tổng Trạm Sạc</div>
                </div>

                <div className="stat-card">
                    <div className="stat-icon green">
                        <Users size={24} />
                    </div>
                    <div className="stat-value">{stats.totalUsers}</div>
                    <div className="stat-label">Tổng Người Dùng</div>
                </div>

                <div className="stat-card">
                    <div className="stat-icon purple">
                        <Car size={24} />
                    </div>
                    <div className="stat-value">{stats.totalVehicles}</div>
                    <div className="stat-label">Tổng Xe Điện</div>
                </div>

                <div className="stat-card">
                    <div className="stat-icon orange">
                        <DollarSign size={24} />
                    </div>
                    <div className="stat-value">{stats.totalRevenue.toLocaleString()}</div>
                    <div className="stat-label">Doanh Thu (VNĐ)</div>
                </div>
            </div>

            {/* Charts and Additional Info */}
            <div className="charts-grid">
                <div className="chart-card">
                    <h3 className="chart-title">Tình Trạng Cổng Sạc</h3>
                    <div className="charger-status">
                        <div className="charger-count">
                            {stats.activeChargers}/{stats.totalChargers}
                        </div>
                        <div className="charger-label">Cổng đang hoạt động</div>
                        <Progress
                            percent={chargerUtilization}
                            strokeColor="#4facfe"
                            size="large"
                            style={{ marginBottom: '1rem' }}
                        />
                        <div className="progress-text">
                            Tỷ lệ sử dụng: {chargerUtilization}%
                        </div>
                    </div>
                </div>

                <div className="chart-card">
                    <h3 className="chart-title">Hoạt Động Gần Đây</h3>
                    <div className="activity-feed">
                        <div className="activity-item blue">
                            <div className="activity-content">
                                <Activity className="activity-icon blue" size={20} />
                                <span className="activity-text">Hệ thống hoạt động bình thường</span>
                            </div>
                            <span className="activity-badge green">
                                Online
                            </span>
                        </div>
                        <div className="activity-item green">
                            <div className="activity-content">
                                <TrendingUp className="activity-icon green" size={20} />
                                <span className="activity-text">Tăng trưởng người dùng: +12%</span>
                            </div>
                            <span className="activity-badge green">
                                Tháng này
                            </span>
                        </div>
                        <div className="activity-item orange">
                            <div className="activity-content">
                                <Clock className="activity-icon orange" size={20} />
                                <span className="activity-text">Thời gian phản hồi: 0.8s</span>
                            </div>
                            <span className="activity-badge orange">
                                Tốt
                            </span>
                        </div>
                    </div>
                </div>
            </div>

            {/* Recent Orders Table */}
            <div className="orders-card">
                <h3 className="orders-title">Đơn Hàng Gần Đây</h3>
                <Table
                    dataSource={recentOrders}
                    columns={recentOrdersColumns}
                    rowKey="orderID"
                    pagination={false}
                    size="small"
                    style={{ background: 'transparent' }}
                    locale={{
                        emptyText: "Không có đơn hàng nào"
                    }}
                />
            </div>
        </div>
    );
};

export default AdminDashboard;
