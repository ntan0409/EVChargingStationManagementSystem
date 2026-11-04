import { useEffect, useState } from "react";
import { Card, Button, Input, Spin, Empty } from "antd";
import { SaveOutlined, UndoOutlined, SettingOutlined } from "@ant-design/icons";
import { toast } from "react-toastify";
import { GetList, Update } from "../../../API/SystemConfiguration";
import "./SystemConfiguration.css";

export default function SystemConfigEditor() {
    const [items, setItems] = useState([]); // mảng các cấu hình
    const [loading, setLoading] = useState(false);
    const [noData, setNoData] = useState(false);
    const [hasError, setHasError] = useState(false);
    const [savingIds, setSavingIds] = useState([]); // id đang lưu
    const [error, setError] = useState("");

    useEffect(() => {
        (async () => {
            setLoading(true);
            try {
                const res = await GetList();
                // GetList có thể trả về: array OR { data: [...], message } OR { data: { data: [...] } }
                const list = Array.isArray(res)
                    ? res
                    : res?.data ?? res?.data?.data ?? [];
                setItems(list);
                setNoData(false);
                setHasError(false);
            } catch (err) {
                console.log('Full error:', err);

                const status = err?.response?.status;
                const errorMsg = err?.customMessage || err?.response?.data?.message || err?.message || "Đã xảy ra lỗi";

                // Chỉ không bắn toast nếu là lỗi 404 VÀ thông điệp đúng
                const isNoDataError = status === 404 && errorMsg.includes('Không tìm thấy');

                if (isNoDataError) {
                    console.log('Không có cấu hình nào');
                    setNoData(true);
                    setHasError(false);
                } else {
                    toast.error(`Không tải được cấu hình: ${errorMsg}`); // ✅ Bắn toast cho tất cả lỗi khác
                    setHasError(true);
                    setNoData(false);
                }

                setError("Không tải được cấu hình.");
                setItems([]);
            } finally {
                setLoading(false);
            }
        })();
    }, []);

    if (loading) return (
        <div className="syscfg-container">
            <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '400px' }}>
                <Spin size="large" tip="Đang tải cấu hình..." />
            </div>
        </div>
    );

    if (hasError) return (
        <div className="syscfg-container">
            <Empty description="Đã xảy ra lỗi khi tải dữ liệu" />
        </div>
    );

    if (noData || !items || items.length === 0) return (
        <div className="syscfg-container">
            <Empty description="Không có cấu hình để hiển thị" />
        </div>
    );

    const toDateTimeLocal = (iso) => {
        if (!iso) return "";
        try {
            const d = new Date(iso);
            if (Number.isNaN(d.getTime())) return "";
            // remove seconds and milliseconds for datetime-local
            return d.toISOString().slice(0, 16);
        } catch {
            return "";
        }
    };

    const toDisplay = (iso) => {
        if (!iso) return "-";
        try { return new Date(iso).toLocaleString(); } catch { return iso; }
    }

    const handleChange = (id, name, value) => {
        setItems(prev => prev.map(it => it.id === id ? { ...it, [name]: value } : it));
    };

    const handleSave = async (it) => {
        const id = it.id ?? it.Id;
        setError("");
        setSavingIds(s => [...s, id]);
        try {
            const payload = {
                minValue: it.minValue === null || it.minValue === "" ? null : Number(it.minValue),
                maxValue: it.maxValue === null || it.maxValue === "" ? null : Number(it.maxValue),
                effectedDateFrom: it.effectedDateFrom ? new Date(it.effectedDateFrom).toISOString() : null,
                effectedDateTo: it.effectedDateTo ? new Date(it.effectedDateTo).toISOString() : null
            };
            await Update(id, payload);
            setItems(prev => prev.map(x => x.id === id ? { ...x, _savedAt: new Date().toISOString(), ...payload } : x));
            toast.success(`Cập nhật cấu hình "${it.name}" thành công!`);
        } catch (err) {
            const errorMsg = err?.response?.data?.message || err?.message || "Lỗi không xác định";
            toast.error(`Cập nhật thất bại cho "${it.name}": ${errorMsg}`);
            setError(`Cập nhật thất bại cho id=${id}`);
        } finally {
            setSavingIds(s => s.filter(x => x !== id));
        }
    };

    return (
        <div className="syscfg-wrapper">
            <div className="syscfg-header-fixed">
                <div className="syscfg-header">
                    <div>
                        <h1 className="syscfg-main-title">
                            <SettingOutlined style={{ marginRight: 8 }} />
                            Cấu Hình Hệ Thống
                        </h1>
                        <p className="syscfg-subtitle">Quản lý và chỉnh sửa các thông số cấu hình hệ thống</p>
                    </div>
                </div>

                {error && (
                    <Card className="syscfg-error-card">
                        <div className="syscfg-error">{error}</div>
                    </Card>
                )}
            </div>

            <div className="syscfg-content-scroll">
                <div className="syscfg-grid">
                    {items.map((it) => (
                        <Card
                            key={it.id ?? it.Id}
                            className="syscfg-card-item"
                            hoverable
                        >
                            <div className="syscfg-card-content">
                                {/* Left: Info */}
                                <div className="syscfg-info">
                                    <div className="syscfg-name">
                                        {it.name}
                                        <span className="syscfg-id">#{it.id}</span>
                                    </div>
                                    <div className="syscfg-description">
                                        {it.description}
                                    </div>
                                    {/* {it.unit && (
                                        <div className="syscfg-unit">
                                            Đơn vị: <strong>{it.unit}</strong>
                                        </div>
                                    )} */}
                                </div>

                                {/* Right: Form */}
                                <div className="syscfg-form-section">
                                    <div className="syscfg-form-group">
                                        <label className="syscfg-label">Giá trị</label>
                                        <Input
                                            type="number"
                                            value={it.minValue ?? ""}
                                            onChange={(e) => handleChange(it.id, "minValue", e.target.value)}
                                            placeholder="Nhập giá trị"
                                        />
                                    </div>

                                    <div className="syscfg-form-group">
                                        <label className="syscfg-label">Hiệu lực từ</label>
                                        <Input
                                            type="datetime-local"
                                            value={toDateTimeLocal(it.effectedDateFrom)}
                                            onChange={(e) => handleChange(it.id, "effectedDateFrom", e.target.value)}
                                        />
                                    </div>

                                    <div className="syscfg-form-group">
                                        <label className="syscfg-label">Hiệu lực đến</label>
                                        <Input
                                            type="datetime-local"
                                            value={toDateTimeLocal(it.effectedDateTo)}
                                            onChange={(e) => handleChange(it.id, "effectedDateTo", e.target.value)}
                                        />
                                    </div>

                                    <div className="syscfg-actions">
                                        <Button
                                            icon={<UndoOutlined />}
                                            onClick={() => {
                                                (async () => {
                                                    try {
                                                        setLoading(true);
                                                        const res = await GetList();
                                                        const list = Array.isArray(res) ? res : res?.data ?? res?.data?.data ?? [];
                                                        const fresh = list.find(x => x.id === it.id);
                                                        if (fresh) setItems(prev => prev.map(p => p.id === it.id ? fresh : p));
                                                    } finally { setLoading(false); }
                                                })();
                                            }}
                                            disabled={savingIds.includes(it.id)}
                                        >
                                            Hủy
                                        </Button>

                                        <Button
                                            type="primary"
                                            icon={<SaveOutlined />}
                                            onClick={(e) => { e.preventDefault(); handleSave(it); }}
                                            loading={savingIds.includes(it.id)}
                                            disabled={savingIds.includes(it.id)}
                                        >
                                            {savingIds.includes(it.id) ? "Đang lưu..." : "Lưu"}
                                        </Button>
                                    </div>

                                    {it._savedAt && (
                                        <div className="syscfg-saved-time">
                                            ✓ Đã lưu lúc {new Date(it._savedAt).toLocaleString('vi-VN')}
                                        </div>
                                    )}
                                </div>
                            </div>
                        </Card>
                    ))}
                </div>
            </div>
        </div>
    );
}