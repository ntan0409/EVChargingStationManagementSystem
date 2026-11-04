import React, { useState, useEffect } from "react";
import { Bell, X, CheckCircle, AlertCircle, Info, AlertTriangle } from "lucide-react";
import "./AdminNotification.css";

const AdminNotification = () => {
    const [notifications, setNotifications] = useState([
        {
            id: 1,
            type: "success",
            title: "Hệ thống hoạt động bình thường",
            message: "Tất cả trạm sạc đang hoạt động tốt",
            time: "2 phút trước",
            read: false
        },
        {
            id: 2,
            type: "warning",
            title: "Cảnh báo bảo trì",
            message: "Trạm sạc A1 cần bảo trì định kỳ",
            time: "15 phút trước",
            read: false
        },
        {
            id: 3,
            type: "info",
            title: "Cập nhật hệ thống",
            message: "Phiên bản mới đã được triển khai",
            time: "1 giờ trước",
            read: true
        }
    ]);

    const [isOpen, setIsOpen] = useState(false);

    const getIcon = (type) => {
        switch (type) {
            case "success": return <CheckCircle className="text-green-500" size={20} />;
            case "warning": return <AlertTriangle className="text-yellow-500" size={20} />;
            case "error": return <AlertCircle className="text-red-500" size={20} />;
            default: return <Info className="text-blue-500" size={20} />;
        }
    };

    const getBgColor = (type) => {
        switch (type) {
            case "success": return "bg-green-50 border-green-200";
            case "warning": return "bg-yellow-50 border-yellow-200";
            case "error": return "bg-red-50 border-red-200";
            default: return "bg-blue-50 border-blue-200";
        }
    };

    const unreadCount = notifications.filter(n => !n.read).length;

    return (
        <div className="admin-notification">
            <button
                className="notification-btn"
                onClick={() => setIsOpen(!isOpen)}
            >
                <Bell size={20} />
                {unreadCount > 0 && (
                    <span className="notification-badge">
                        {unreadCount}
                    </span>
                )}
            </button>

            {isOpen && (
                <div className="notification-dropdown">
                    <div className="dropdown-header">
                        <div className="header-content">
                            <h3 className="header-title">Thông báo</h3>
                            <button
                                className="close-btn"
                                onClick={() => setIsOpen(false)}
                            >
                                <X size={16} />
                            </button>
                        </div>
                    </div>

                    <div className="notification-list">
                        {notifications.map((notification) => (
                            <div
                                key={notification.id}
                                className={`notification-item ${!notification.read ? 'unread' : ''}`}
                            >
                                <div className="notification-content">
                                    <div className={`notification-icon ${notification.type}`}>
                                        {getIcon(notification.type)}
                                    </div>
                                    <div className="notification-details">
                                        <div className="notification-header">
                                            <h4 className="notification-title">
                                                {notification.title}
                                            </h4>
                                            {!notification.read && (
                                                <div className="unread-indicator"></div>
                                            )}
                                        </div>
                                        <p className="notification-message">
                                            {notification.message}
                                        </p>
                                        <p className="notification-time">
                                            {notification.time}
                                        </p>
                                    </div>
                                </div>
                            </div>
                        ))}
                    </div>

                    <div className="dropdown-footer">
                        <button className="view-all-btn">
                            Xem tất cả thông báo
                        </button>
                    </div>
                </div>
            )}
        </div>
    );
};

export default AdminNotification;
