import React, { useState } from "react";
import { Card, Form, Input, Button, Switch, Select, message, Divider } from "antd";
import { Save, RefreshCw, Shield, Bell, Globe, Database } from "lucide-react";
import "./AdminSettings.css";

const AdminSettings = () => {
    const [form] = Form.useForm();
    const [loading, setLoading] = useState(false);

    const handleSave = async (values) => {
        setLoading(true);
        try {
            // Simulate API call
            await new Promise(resolve => setTimeout(resolve, 1000));
            message.success("Cài đặt đã được lưu thành công!");
        } catch (error) {
            message.error("Có lỗi xảy ra khi lưu cài đặt!");
        } finally {
            setLoading(false);
        }
    };

    const handleReset = () => {
        form.resetFields();
        message.info("Đã khôi phục cài đặt mặc định");
    };

    return (
        <div className="admin-settings">
            <div className="header">
                <h1>Cài Đặt Hệ Thống</h1>
                <p>Quản lý cấu hình và thiết lập hệ thống</p>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                {/* General Settings */}
                <Card
                    title={
                        <div className="flex items-center gap-2">
                            <Globe className="text-blue-500" size={20} />
                            <span>Cài Đặt Chung</span>
                        </div>
                    }
                    className="h-fit"
                >
                    <Form form={form} layout="vertical" onFinish={handleSave}>
                        <Form.Item label="Tên hệ thống" name="systemName" initialValue="EV Charging Station">
                            <Input placeholder="Nhập tên hệ thống" />
                        </Form.Item>

                        <Form.Item label="Email hỗ trợ" name="supportEmail" initialValue="support@evcharging.com">
                            <Input type="email" placeholder="Nhập email hỗ trợ" />
                        </Form.Item>

                        <Form.Item label="Số điện thoại hỗ trợ" name="supportPhone" initialValue="1900-1234">
                            <Input placeholder="Nhập số điện thoại" />
                        </Form.Item>

                        <Form.Item label="Địa chỉ công ty" name="companyAddress">
                            <Input.TextArea rows={3} placeholder="Nhập địa chỉ công ty" />
                        </Form.Item>

                        <Form.Item label="Múi giờ" name="timezone" initialValue="Asia/Ho_Chi_Minh">
                            <Select
                                options={[
                                    { value: "Asia/Ho_Chi_Minh", label: "Việt Nam (GMT+7)" },
                                    { value: "UTC", label: "UTC (GMT+0)" },
                                    { value: "America/New_York", label: "New York (GMT-5)" },
                                ]}
                            />
                        </Form.Item>
                    </Form>
                </Card>

                {/* Notification Settings */}
                <Card
                    title={
                        <div className="flex items-center gap-2">
                            <Bell className="text-green-500" size={20} />
                            <span>Cài Đặt Thông Báo</span>
                        </div>
                    }
                    className="h-fit"
                >
                    <div className="space-y-4">
                        <div className="flex items-center justify-between">
                            <div>
                                <div className="font-medium">Thông báo email</div>
                                <div className="text-sm text-gray-500">Gửi thông báo qua email</div>
                            </div>
                            <Switch defaultChecked />
                        </div>

                        <div className="flex items-center justify-between">
                            <div>
                                <div className="font-medium">Thông báo SMS</div>
                                <div className="text-sm text-gray-500">Gửi thông báo qua SMS</div>
                            </div>
                            <Switch />
                        </div>

                        <div className="flex items-center justify-between">
                            <div>
                                <div className="font-medium">Thông báo đẩy</div>
                                <div className="text-sm text-gray-500">Thông báo trên trình duyệt</div>
                            </div>
                            <Switch defaultChecked />
                        </div>

                        <div className="flex items-center justify-between">
                            <div>
                                <div className="font-medium">Thông báo sự cố</div>
                                <div className="text-sm text-gray-500">Cảnh báo khi có sự cố</div>
                            </div>
                            <Switch defaultChecked />
                        </div>
                    </div>
                </Card>

                {/* Security Settings */}
                <Card
                    title={
                        <div className="flex items-center gap-2">
                            <Shield className="text-red-500" size={20} />
                            <span>Bảo Mật</span>
                        </div>
                    }
                    className="h-fit"
                >
                    <div className="space-y-4">
                        <div className="flex items-center justify-between">
                            <div>
                                <div className="font-medium">Xác thực 2FA</div>
                                <div className="text-sm text-gray-500">Yêu cầu xác thực 2 bước</div>
                            </div>
                            <Switch />
                        </div>

                        <div className="flex items-center justify-between">
                            <div>
                                <div className="font-medium">Đăng nhập tự động</div>
                                <div className="text-sm text-gray-500">Ghi nhớ đăng nhập</div>
                            </div>
                            <Switch defaultChecked />
                        </div>

                        <div className="flex items-center justify-between">
                            <div>
                                <div className="font-medium">Giới hạn IP</div>
                                <div className="text-sm text-gray-500">Chỉ cho phép IP nhất định</div>
                            </div>
                            <Switch />
                        </div>

                        <div className="flex items-center justify-between">
                            <div>
                                <div className="font-medium">Ghi log đăng nhập</div>
                                <div className="text-sm text-gray-500">Theo dõi hoạt động đăng nhập</div>
                            </div>
                            <Switch defaultChecked />
                        </div>
                    </div>
                </Card>

                {/* Database Settings */}
                <Card
                    title={
                        <div className="flex items-center gap-2">
                            <Database className="text-purple-500" size={20} />
                            <span>Cơ Sở Dữ Liệu</span>
                        </div>
                    }
                    className="h-fit"
                >
                    <div className="space-y-4">
                        <div className="flex items-center justify-between">
                            <div>
                                <div className="font-medium">Sao lưu tự động</div>
                                <div className="text-sm text-gray-500">Tự động sao lưu hàng ngày</div>
                            </div>
                            <Switch defaultChecked />
                        </div>

                        <div className="flex items-center justify-between">
                            <div>
                                <div className="font-medium">Nén dữ liệu</div>
                                <div className="text-sm text-gray-500">Nén dữ liệu để tiết kiệm dung lượng</div>
                            </div>
                            <Switch defaultChecked />
                        </div>

                        <div className="flex items-center justify-between">
                            <div>
                                <div className="font-medium">Xóa log cũ</div>
                                <div className="text-sm text-gray-500">Tự động xóa log sau 30 ngày</div>
                            </div>
                            <Switch defaultChecked />
                        </div>

                        <div className="flex items-center justify-between">
                            <div>
                                <div className="font-medium">Tối ưu hóa</div>
                                <div className="text-sm text-gray-500">Tối ưu hóa database</div>
                            </div>
                            <Switch />
                        </div>
                    </div>
                </Card>
            </div>

            {/* Action Buttons */}
            <div className="mt-8 flex justify-end gap-4">
                <Button
                    icon={<RefreshCw size={16} />}
                    onClick={handleReset}
                    className="flex items-center gap-2"
                >
                    Khôi phục mặc định
                </Button>
                <Button
                    type="primary"
                    icon={<Save size={16} />}
                    onClick={() => form.submit()}
                    loading={loading}
                    className="flex items-center gap-2"
                >
                    Lưu cài đặt
                </Button>
            </div>
        </div>
    );
};

export default AdminSettings;
