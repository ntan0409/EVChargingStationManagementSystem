import React from "react";
import { Result, Button } from "antd";
import { useNavigate } from "react-router-dom";
import { HomeOutlined, ArrowLeftOutlined } from "@ant-design/icons";

const AdminNotFound = () => {
    const navigate = useNavigate();

    return (
        <div className="min-h-screen flex items-center justify-center bg-gray-50">
            <Result
                status="404"
                title="404"
                subTitle="Xin lỗi, trang bạn truy cập không tồn tại."
                extra={[
                    <Button
                        type="primary"
                        icon={<HomeOutlined />}
                        onClick={() => navigate("/admin")}
                        key="home"
                    >
                        Về Dashboard
                    </Button>,
                    <Button
                        icon={<ArrowLeftOutlined />}
                        onClick={() => navigate(-1)}
                        key="back"
                    >
                        Quay lại
                    </Button>,
                ]}
            />
        </div>
    );
};

export default AdminNotFound;
