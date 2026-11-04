import React from "react";
import { Navigate } from "react-router-dom";

const AdminPrivateRoute = ({ children }) => {
    // Kiểm tra xem user có đăng nhập và có quyền admin không
    const isAuthenticated = localStorage.getItem("token");
    const userRole = localStorage.getItem("user_role");

    if (!isAuthenticated) {
        return <Navigate to="/login" replace />;
    }

    if (userRole !== "Admin") {
        return <Navigate to="/" replace />;
    }

    return children;
};

export default AdminPrivateRoute;
