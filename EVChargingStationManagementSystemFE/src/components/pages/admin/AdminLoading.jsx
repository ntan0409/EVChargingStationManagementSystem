import React from "react";

const AdminLoading = () => {
    return (
        <div className="min-h-screen flex items-center justify-center admin-layout">
            <div className="text-center">
                <div className="relative">
                    <div className="w-20 h-20 border-4 border-white border-opacity-20 rounded-full animate-spin border-t-white"></div>
                    <div className="absolute inset-0 w-20 h-20 border-4 border-transparent border-t-blue-500 rounded-full animate-spin" style={{ animationDirection: 'reverse', animationDuration: '1.5s' }}></div>
                </div>
                <div className="mt-6">
                    <h2 className="text-2xl font-bold text-white mb-2">Đang tải...</h2>
                    <p className="text-white text-opacity-80">Vui lòng chờ trong giây lát</p>
                </div>
                <div className="mt-4 flex justify-center space-x-1">
                    <div className="w-2 h-2 bg-white rounded-full animate-bounce" style={{ animationDelay: '0ms' }}></div>
                    <div className="w-2 h-2 bg-white rounded-full animate-bounce" style={{ animationDelay: '150ms' }}></div>
                    <div className="w-2 h-2 bg-white rounded-full animate-bounce" style={{ animationDelay: '300ms' }}></div>
                </div>
            </div>
        </div>
    );
};

export default AdminLoading;
