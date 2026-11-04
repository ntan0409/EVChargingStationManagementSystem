import React, { useState, useEffect } from "react";
import { Bell } from "lucide-react";
import { useNotifications } from "./NotificationContext";
import { getAuthStatus } from "../../API/Auth";
import { getNotificattion, getNotificattionUnRead } from "../../API/Notificattion";
import "./NotificationBubble.css";

const NotificationBubble = () => {
  const { notifications, addNotification, clearNotifications, unReadCount, setUnReadCount } =
    useNotifications();

  const [open, setOpen] = useState(false);
  const [loggedIn, setLoggedIn] = useState(getAuthStatus().isAuthenticated);
  const [role, setRole] = useState(getAuthStatus().user?.role);

  // Lắng nghe auth thay đổi
  useEffect(() => {
    const handleAuthChanged = () => {
      const auth = getAuthStatus();
      setLoggedIn(auth.isAuthenticated);
      setRole(auth.user?.role);
    };
    window.addEventListener("auth-changed", handleAuthChanged);
    return () => window.removeEventListener("auth-changed", handleAuthChanged);
  }, []);

  // Load notifications khi login
  useEffect(() => {
    const loadNotifications = async () => {
      if (!loggedIn) return;

      try {
        if (role === "Admin" || role === "Staff") {
          const [allResponse, unreadResponse] = await Promise.all([
            getNotificattion(),
            getNotificattionUnRead(),
          ]);

          const today = new Date().toDateString();

          const notificationsArray =
            (allResponse.data?.data || allResponse.data || []).filter(
              n => new Date(n.createdAt).toDateString() === today
            );

          clearNotifications();

          notificationsArray.forEach(n =>
            addNotification({
              id: n.id,
              title: n.title,
              type: n.type || "System",
              createdAt: n.createdAt,
            })
          );

          // Set unread từ API
          setUnReadCount(unreadResponse?.data?.count || notificationsArray.length);
        } else {
          const today = new Date().toDateString();
          const welcomeSentDay = localStorage.getItem("welcomeNotificationSentDay");

          if (welcomeSentDay !== today) {
            addNotification({
              id: "welcome",
              title: "Chào mừng tài xế xe điện đến với dịch vụ trạm sạc!",
              type: "User",
              createdAt: new Date().toISOString(),
            });

            localStorage.setItem("welcomeNotificationSentDay", today);
          }
        }
      } catch (err) {
        console.error("❌ Load notifications failed:", err);
      }
    };

    loadNotifications();
  }, [loggedIn, role]);

  // Mở panel = đánh dấu đã xem
  const handleOpenPanel = () => {
    setOpen(prev => !prev);

    if (!open) {
      setUnReadCount(0);
      localStorage.setItem("notificationsSeenDay", new Date().toDateString());
    }
  };

  if (!loggedIn) return null;

  return (
    <div className="notification-wrapper">
      <div className="notification-bubble" onClick={handleOpenPanel}>
        <Bell size={24} />
        {unReadCount > 0 && <span className="notification-count">{unReadCount}</span>}
      </div>

      {open && (
        <div className="notification-panel">
          <h4>Thông báo</h4>
          {notifications.length === 0 ? (
            <p className="no-notification">Không có thông báo mới</p>
          ) : (
            <ul>
              {notifications
                .slice()
                .sort((b, a) => new Date(a.createdAt) - new Date(b.createdAt))
                .map(n => (
                  <li key={n.id || n.createdAt}>
                    <strong>{n.title}</strong>
                    {n.message && <p>{n.message}</p>}
                    <div className="noti-meta">
                      <span>{new Date(n.createdAt).toLocaleString()}</span>
                    </div>
                  </li>
                ))}
            </ul>
          )}
        </div>
      )}
    </div>
  );
};

export default NotificationBubble;
