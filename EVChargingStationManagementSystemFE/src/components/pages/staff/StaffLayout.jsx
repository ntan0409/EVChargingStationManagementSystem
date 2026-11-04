import React from "react";
import { Outlet } from "react-router-dom";
import { User } from "lucide-react";
import AdminSidebar from "../admin/AdminSidebar";
import StaffSidebar from "./StaffSidebar";
import "../admin/AdminLayout.css";


const StaffLayout = () => {
    return (
        <div className="admin-layout min-h-screen bg-gray-50 flex">
            {/* --- SIDEBAR (bên trái cố định) --- */}
            <div className="fixed left-0 top-0 h-full w-64 bg-white shadow-lg z-30">
                <StaffSidebar />
            </div>

            {/* CONTENT LỆCH SANG PHẢI */}
            <div className="admin-content">
                {/* Nội dung chính */}
                <main className="flex-1 p-2 bg-gray-50">
                    <Outlet />
                </main>
            </div>
        </div>
    );
};

export default StaffLayout;
