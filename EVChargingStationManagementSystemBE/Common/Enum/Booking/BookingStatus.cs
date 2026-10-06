using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace Common.Enum.Booking
{
    public enum BookingStatus
    {
        Unknown = 0,          // Mặc định nếu chưa gán
        Scheduled = 1,        // Người dùng đã đặt lịch (chờ tới giờ)
        Reserved = 2,         // (tùy chọn) trụ/cổng đã bị giữ chỗ
        CheckedIn = 3,        // Người dùng đã đến trạm nhưng chưa sạc
        InProgress = 4,       // Đang sạc
        Completed = 5,        // Hoàn tất phiên sạc
        Cancelled = 6,        // Người dùng hủy (hợp lệ)
        AutoCancelled = 7,    // Hệ thống tự hủy (do trễ hoặc lỗi)
        NoShow = 8,           // Người dùng không tới
        CancelledInvalid = 9,
        Waiting = 10,
        CompensatedCancelled= 11,
        Rejected=12,
        // Người dùng hủy không hợp lệ (sau StartTime hoặc trước StartTime ≤ 2 phút)
    }
}
