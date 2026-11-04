import React from "react";
import { NavLink } from "react-router-dom";
import { Zap, Users, Car, LogOut, BarChart3, Settings, House, CreditCard,ClipboardList } from "lucide-react";
// import "./AdminSidebar.css";
import "./StaffSidebar.css";

const StaffSidebar = () => {
    const menuItems = [
        // { name: "Trang chủ", path: "/", icon: <House size={20} /> },
        // { name: "Dashboard", path: "/admin", icon: <BarChart3 size={20} /> },
        { name: "Trạm sạc", path: "/staff/stations", icon: <Zap size={20} /> },
        // { name: "Xe điện", path: "/staff/vehicles", icon: <Car size={20} /> },
        { name: "Xác nhận thanh toán", path: "confirm-payment-offline", icon: <CreditCard size={20} /> },

        { name: "Quản Lý Đặt Lịch Sạc", path: "/staff/booking-order", icon: <Users size={20} /> },
        { name: "Báo Cáo", path: "/staff/staff-report", icon: <BarChart3 size={20} /> }


    ];

    return (
        <aside className="admin-sidebar">
            {/* Logo Section */}

            <div className="logo-section">
                <div className="logo-container">
                    <div className="logo-icon">
                        <span><ClipboardList size={20}  /></span>
                    </div>
                    <div className="logo-text">
                        <h1>Nhân Viên</h1>
                    </div>
                </div>
            </div>

            {/* Navigation */}
            <nav className="navigation">
                <div className="nav-items">
                    {menuItems.map((item) => (
                        <NavLink
                            key={item.path}
                            to={item.path}
                            className={({ isActive }) =>
                                `nav-item ${isActive ? "active" : ""}`
                            }
                        >
                            <div className="icon">
                                {item.icon}
                            </div>
                            <span>{item.name}</span>
                        </NavLink>
                    ))}
                </div>
            </nav>

            {/* User Section */}
            <div className="user-section">
                <div className="user-info">
                    <div className="user-avatar">
                        NV
                    </div>
                    <div className="user-details">
                        <div className="user-name">Nhân viên</div>
                    </div>
                </div>
                <button
                    className="logout-btn"
                    onClick={() => {
                        if (window.confirm("Bạn có chắc chắn muốn đăng xuất?")) {
                            localStorage.removeItem("token");
                            localStorage.removeItem("user_role");
                            window.location.href = "/login";
                        }
                    }}
                >
                    <LogOut size={18} />
                    <span>Đăng xuất</span>
                </button>
            </div>
        </aside>
    );
};

export default StaffSidebar;
