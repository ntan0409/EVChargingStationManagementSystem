import { Outlet } from "react-router-dom";
import AdminSidebar from "./AdminSidebar";
import "./AdminLayout.css";

const AdminLayout = () => {
    return (
        <div className="admin-layout min-h-screen bg-gray-50 flex">
            {/* --- SIDEBAR (bên trái cố định) --- */}
            <div className="fixed left-0 top-0 h-full w-64 bg-white shadow-lg z-30">
                <AdminSidebar />
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

export default AdminLayout;
