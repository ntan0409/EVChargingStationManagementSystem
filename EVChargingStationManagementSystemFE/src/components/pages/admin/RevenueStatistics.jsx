import { useEffect, useState } from "react";
import { Card, Row, Col, Statistic, DatePicker, Select, Table, Spin, Empty, Input } from "antd";
import {
    DollarSign,
    TrendingUp,
    Users,
    Calendar,
    ArrowUp,
    ArrowDown,
    Search
} from "lucide-react";
import { toast } from "react-toastify";
import { GetTransaction } from "../../../API/Transaction";
import dayjs from "dayjs";
import "./RevenueStatistics.css";

const { RangePicker } = DatePicker;
const { Option } = Select;


// Mapping trạng thái và loại giao dịch sang tiếng Việt
const transactionTypeMapping = {
    'OnlinePayment': 'Thanh toán online',
    'OfflinePayment': 'Thanh toán tại chỗ',
    'Refund': 'Hoàn tiền',
    'Deposit': 'Đặt cọc',
    'Withdrawal': 'Rút tiền'
};

const statusMapping = {
    'Completed': 'Hoàn thành',
    'Pending': 'Đang xử lý',
    'Failed': 'Thất bại',
    'Cancelled': 'Đã hủy',
    'Processing': 'Đang xử lý',
    'Refunded': 'Đã hoàn tiền'
};

const RevenueStatistics = () => {
    const [noData, setNoData] = useState(false);
    const [hasError, setHasError] = useState(false);
    const [transactions, setTransactions] = useState([]);
    const [loading, setLoading] = useState(false);
    const [dateRange, setDateRange] = useState([dayjs().subtract(1, 'year'), dayjs().add(1, 'year')]);
    const [filterPeriod, setFilterPeriod] = useState('all');
    const [searchText, setSearchText] = useState('');
    const [statistics, setStatistics] = useState({
        totalRevenue: 0,
        totalEnergy: 0,
        totalSessions: 0,
        averageRevenue: 0,
        growthRate: 0
    });

    useEffect(() => {
        fetchTransactions();
    }, []);

    useEffect(() => {
        if (transactions.length > 0) {
            calculateStatistics();
        }
    }, [transactions, dateRange]);
    const fetchTransactions = async () => {
        setLoading(true);
        try {
            const response = await GetTransaction();
            console.log('📊 Full response:', response);
            console.log('📊 response.data:', response?.data);
            console.log('📊 response.data.data:', response?.data?.data);

            // Parse data từ response - BE trả về { data: [...], message: "..." }
            const data = Array.isArray(response?.data?.data) ? response.data.data :
                Array.isArray(response?.data) ? response.data :
                    Array.isArray(response) ? response : [];

            console.log('📊 Parsed data:', data);
            console.log('📊 Data length:', data.length);

            if (data.length === 0) {
                setNoData(true);
                setHasError(false);
            } else {
                setNoData(false);
                setHasError(false);
            }

            setTransactions(data);
        } catch (error) {
            console.log('❌ Full error:', error);

            const status = error?.response?.status;
            const message =
                error?.customMessage ||
                error?.response?.data?.message ||
                error?.message ||
                'Đã xảy ra lỗi';

            // Chỉ không bắn toast nếu là lỗi 404 VÀ thông điệp đúng
            const isNoDataError = status === 404 && message.includes('Không tìm thấy lịch sử giao dịch');

            if (isNoDataError) {
                console.log('Không có giao dịch nào trong khoảng thời gian này');
                setNoData(true);
                setHasError(false);
            } else {
                toast.error(message);
                setHasError(true);
                setNoData(false);
            }

            setTransactions([]);
        } finally {
            setLoading(false);
        }
    };







    const calculateStatistics = () => {
        // Parse ngày từ referenceCode (format: ONL-YYYYMMDD-XXXXXX)
        const filtered = transactions.filter(t => {
            if (!t.referenceCode) return true; // Nếu không có referenceCode thì vẫn hiển thị
            try {
                const dateStr = t.referenceCode.split('-')[1]; // Lấy phần YYYYMMDD
                const transDate = dayjs(dateStr, 'YYYYMMDD');
                // Sử dụng isSameOrAfter và isSameOrBefore để bao gồm cả ngày bắt đầu và kết thúc
                return transDate.isSameOrAfter(dateRange[0], 'day') && transDate.isSameOrBefore(dateRange[1], 'day');
            } catch {
                return true; // Nếu parse lỗi thì vẫn hiển thị
            }
        });

        const totalRevenue = filtered.reduce((sum, t) => sum + (t.amount || 0), 0);
        const totalSessions = filtered.length;
        const averageRevenue = totalSessions > 0 ? totalRevenue / totalSessions : 0;

        // Tính tăng trưởng so với kỳ trước
        const periodDays = dateRange[1].diff(dateRange[0], 'days');
        const previousStart = dateRange[0].subtract(periodDays, 'days');
        const previousEnd = dateRange[0];

        const previousTransactions = transactions.filter(t => {
            if (!t.referenceCode) return false;
            try {
                const dateStr = t.referenceCode.split('-')[1];
                const transDate = dayjs(dateStr, 'YYYYMMDD');
                return transDate.isSameOrAfter(previousStart, 'day') && transDate.isBefore(previousEnd, 'day');
            } catch {
                return false;
            }
        });

        const previousRevenue = previousTransactions.reduce((sum, t) => sum + (t.amount || 0), 0);
        const growthRate = previousRevenue > 0
            ? ((totalRevenue - previousRevenue) / previousRevenue) * 100
            : 0;

        setStatistics({
            totalRevenue,
            totalEnergy: 0, // Backend không trả về energyDelivered
            totalSessions,
            averageRevenue,
            growthRate
        });
    };

    const handlePeriodChange = (value) => {
        setFilterPeriod(value);
        const now = dayjs();
        let start, end;

        switch (value) {
            case 'all':
                start = now.subtract(1, 'year');
                end = now.add(1, 'year');
                break;
            case 'today':
                start = now.startOf('day');
                end = now;
                break;
            case '7days':
                start = now.subtract(7, 'days');
                end = now;
                break;
            case '30days':
                start = now.subtract(30, 'days');
                end = now;
                break;
            case '90days':
                start = now.subtract(90, 'days');
                end = now;
                break;
            case 'year':
                start = now.subtract(1, 'year');
                end = now;
                break;
            default:
                start = now.subtract(1, 'year');
                end = now.add(1, 'year');
        }

        setDateRange([start, end]);
    };

    const columns = [
        {
            title: 'Mã tham chiếu',
            dataIndex: 'referenceCode',
            key: 'referenceCode',
            width: 180,
            render: (code) => <span className="font-mono text-xs">{code}</span>
        },
        {
            title: 'Thời gian',
            dataIndex: 'referenceCode',
            key: 'date',
            render: (code) => {
                if (!code) return '-';
                try {
                    const dateStr = code.split('-')[1]; // Lấy YYYYMMDD
                    return dayjs(dateStr, 'YYYYMMDD').format('DD/MM/YYYY');
                } catch {
                    return '-';
                }
            },
            width: 120,
        },
        {
            title: 'Loại giao dịch',
            dataIndex: 'transactionType',
            key: 'transactionType',
            render: (type) => (
                <span className="text-xs">
                    {transactionTypeMapping[type] || type}
                </span>
            ),
            width: 150,
        },
        {
            title: 'Số tiền (VNĐ)',
            dataIndex: 'amount',
            key: 'amount',
            render: (value) => (
                <span className="font-semibold text-green-600">
                    {value ? value.toLocaleString('vi-VN', { maximumFractionDigits: 2 }) : '0'}
                </span>
            ),
            width: 130,
        },
        {
            title: 'Trạng thái',
            dataIndex: 'status',
            key: 'status',
            render: (status) => {
                const getStatusColor = (status) => {
                    switch (status) {
                        case 'Completed':
                            return 'bg-green-100 text-green-700';
                        case 'Pending':
                        case 'Processing':
                            return 'bg-yellow-100 text-yellow-700';
                        case 'Failed':
                        case 'Cancelled':
                            return 'bg-red-100 text-red-700';
                        case 'Refunded':
                            return 'bg-blue-100 text-blue-700';
                        default:
                            return 'bg-gray-100 text-gray-700';
                    }
                };

                return (
                    <span className={`px-2 py-1 rounded text-xs ${getStatusColor(status)}`}>
                        {statusMapping[status] || status}
                    </span>
                );
            },
            width: 120,
        },
    ];

    const filteredTransactions = transactions.filter(t => {
        // Filter by date range
        let matchDate = true;
        if (t.referenceCode) {
            try {
                const dateStr = t.referenceCode.split('-')[1];
                const transDate = dayjs(dateStr, 'YYYYMMDD');
                // Sử dụng isSameOrAfter và isSameOrBefore để bao gồm cả ngày bắt đầu và kết thúc
                matchDate = transDate.isSameOrAfter(dateRange[0], 'day') && transDate.isSameOrBefore(dateRange[1], 'day');
            } catch {
                matchDate = true;
            }
        }

        // Filter by search text
        let matchSearch = true;
        if (searchText) {
            const search = searchText.toLowerCase();
            matchSearch = (
                t.referenceCode?.toLowerCase().includes(search) ||
                t.id?.toLowerCase().includes(search) ||
                t.transactionType?.toLowerCase().includes(search)
            );
        }

        return matchDate && matchSearch;
    });

    if (loading) {
        return (
            <div className="flex justify-center items-center min-h-screen">
                <Spin size="large" />
            </div>
        );
    }

    return (
        <div className="admin-revenue-statistics">
            {/* Header */}
            <div className="header">
                <h1>Thống Kê Doanh Thu</h1>
                <p>Tổng quan về doanh thu và hoạt động sạc xe</p>
            </div>

            {/* Statistics Cards */}
            <div className="stats-container">
                <Row gutter={[16, 16]}>
                    <Col xs={24} sm={12} lg={8}>
                        <Card className="h-full">
                            <Statistic
                                title="Tổng doanh thu"
                                value={statistics.totalRevenue}
                                precision={2}
                                suffix="VNĐ"
                                prefix={<DollarSign className="text-green-500" size={20} />}
                                formatter={(value) => `${Number(value).toLocaleString('vi-VN')}`}
                            />
                            {statistics.growthRate !== 0 && (
                                <div className={`flex items-center gap-1 mt-2 text-sm ${statistics.growthRate > 0 ? 'text-green-600' : 'text-red-600'
                                    }`}>
                                    {statistics.growthRate > 0 ? <ArrowUp size={16} /> : <ArrowDown size={16} />}
                                    <span>{Math.abs(statistics.growthRate).toFixed(1)}% so với kỳ trước</span>
                                </div>
                            )}
                        </Card>
                    </Col>

                    <Col xs={24} sm={12} lg={8}>
                        <Card className="h-full">
                            <Statistic
                                title="Số giao dịch"
                                value={statistics.totalSessions}
                                prefix={<Calendar className="text-blue-500" size={20} />}
                            />
                        </Card>
                    </Col>

                    <Col xs={24} sm={12} lg={8}>
                        <Card className="h-full">
                            <Statistic
                                title="Doanh thu TB/giao dịch"
                                value={statistics.averageRevenue}
                                precision={2}
                                suffix="VNĐ"
                                prefix={<TrendingUp className="text-purple-500" size={20} />}
                                formatter={(value) => `${Number(value).toLocaleString('vi-VN')}`}
                            />
                        </Card>
                    </Col>
                </Row>
            </div>

            {/* Filters */}
            <div className="actions-card">
                <Row gutter={16} align="middle">
                    <Col xs={24} md={8}>
                        <Input
                            placeholder="Tìm kiếm theo mã giao dịch..."
                            prefix={<Search size={16} />}
                            value={searchText}
                            onChange={(e) => setSearchText(e.target.value)}
                            allowClear
                        />
                    </Col>
                    <Col xs={24} sm={12} md={6}>
                        <Select
                            value={filterPeriod}
                            onChange={handlePeriodChange}
                            className="w-full"
                            placeholder="Khoảng thời gian"
                        >
                            <Option value="all">Tất cả</Option>
                            <Option value="today">Hôm nay</Option>
                            <Option value="7days">7 ngày qua</Option>
                            <Option value="30days">30 ngày qua</Option>
                            <Option value="90days">90 ngày qua</Option>
                            <Option value="year">1 năm qua</Option>
                        </Select>
                    </Col>
                    <Col xs={24} sm={12} md={10}>
                        <RangePicker
                            value={dateRange}
                            onChange={(dates) => {
                                if (dates) {
                                    setDateRange(dates);
                                    setFilterPeriod('custom');
                                }
                            }}
                            format="DD/MM/YYYY"
                            className="w-full"
                        />
                    </Col>
                </Row>
            </div>

            {/* Transactions Table */}
            <div className="table-card">
                <Card
                    title={
                        <div className="flex items-center gap-2">
                            <Users size={20} />
                            <span>Chi tiết giao dịch ({filteredTransactions.length})</span>
                        </div>
                    }
                >
                    {hasError ? (
                        <Empty description="Đã xảy ra lỗi khi tải dữ liệu" />
                    ) : noData || filteredTransactions.length === 0 ? (
                        <Empty description="Không có giao dịch nào trong khoảng thời gian này" />
                    ) : (
                        <Table
                            columns={columns}
                            dataSource={filteredTransactions}
                            rowKey="id"
                            pagination={false}
                            scroll={{ x: 800, y: 400 }}
                            sticky
                        />
                    )}

                </Card>
            </div>
        </div>
    );
};

export default RevenueStatistics;
