using BusinessLogic.Base;
using BusinessLogic.IServices;
using Common;
using Common.DTOs.BookingDto;
using Common.Enum.Booking;
using Common.Enum.ChargingPost;
using Common.Enum.ChargingSession;
using Common.Enum.Connector;
using Common.Enum.VehicleModel;
using Infrastructure.IUnitOfWork;
using Infrastructure.Models;
using Mapster;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace BusinessLogic.Services
{
    public class BookingService(IUnitOfWork unitOfWork, UserManager<UserAccount> userManager, ICheckInCodeService checkInCodeService) : IBookingService
    {
        private readonly IUnitOfWork _unitOfWork = unitOfWork;
        private readonly UserManager<UserAccount> _userManager = userManager;
        private readonly ICheckInCodeService _checkInCodeService = checkInCodeService;


        // Tạo booking mới (EndTime mặc định +1h)

        public async Task<IServiceResult> CreateBooking(BookingCreatedDto dto, Guid userId)
        {
            try
            {
                // --- BR12: Kiểm tra tài khoản EVDriver ---
                var user = await _unitOfWork.UserAccountRepository.GetByIdAsync(
                    u => u.Id == userId && !u.IsDeleted);
                if (user == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy tài khoản người dùng.");
                if (!user.EmailConfirmed)
                    return new ServiceResult(Const.FAIL_CREATE_CODE, "Tài khoản chưa được xác thực.");
                var roles = await _userManager.GetRolesAsync(user);
                if (!roles.Contains("EVDriver", StringComparer.OrdinalIgnoreCase))
                    return new ServiceResult(Const.FAIL_CREATE_CODE, "Chỉ EVDriver mới được phép đặt chỗ.");

                // --- BR04: Lấy EVDriver profile + xe ---
                var evDriver = await _unitOfWork.EVDriverRepository.GetByIdAsync(
                    e => e.AccountId == userId && !e.IsDeleted,
                    include: e => e.Include(x => x.UserVehicles).ThenInclude(v => v.VehicleModel));
                if (evDriver == null)
                    return new ServiceResult(Const.FAIL_CREATE_CODE, "Người dùng chưa có hồ sơ EVDriver.");
                if (!evDriver.Status.Equals("Active"))
                    return new ServiceResult(Const.FAIL_CREATE_CODE, "Tài khoản của bạn đã bị khóa.");

                var vehicle = evDriver.UserVehicles
                    .Select(uv => uv.VehicleModel)
                    .FirstOrDefault(v => v.Id == dto.VehicleId && !v.IsDeleted);
                if (vehicle == null)
                    return new ServiceResult(Const.FAIL_CREATE_CODE, "Phương tiện không hợp lệ hoặc không thuộc người dùng.");

                var validVehicle = await _unitOfWork.VehicleModelRepository.GetByIdAsync(
                    v => v.Id == vehicle.Id && !v.IsDeleted);
                if (validVehicle == null)
                    return new ServiceResult(Const.FAIL_CREATE_CODE, "Xe không tồn tại trong hệ thống.");

                // --- BR06: StartTime >= Now + 5 phút ---
                if (dto.StartTime < DateTime.Now.AddMinutes(5))
                    return new ServiceResult(Const.FAIL_CREATE_CODE, "Thời gian bắt đầu phải cách hiện tại ≥ 5 phút.");

                // --- BR05: Kiểm tra booking đang hoạt động ---
                var active = await _unitOfWork.BookingRepository.GetAllAsync(
                    b => b.BookedBy == userId &&
                         (b.Status == BookingStatus.Scheduled.ToString() ||
                          b.Status == BookingStatus.InProgress.ToString()) &&
                         !b.IsDeleted);
                if (active.Any())
                    return new ServiceResult(Const.FAIL_CREATE_CODE, "Bạn đã có booking đang hoạt động.");

                // --- Kiểm tra trạm sạc ---
                var station = await _unitOfWork.ChargingStationRepository.GetByIdAsync(
                    s => s.Id == dto.StationId && !s.IsDeleted,
                    include: s => s.Include(x => x.ChargingPosts)
                                   .ThenInclude(cp => cp.Connectors));
                if (station == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy trạm sạc.");
                if (station.Status.Equals("Maintenance", StringComparison.OrdinalIgnoreCase) ||
                    station.Status.Equals("Inactive", StringComparison.OrdinalIgnoreCase))
                {
                    return new ServiceResult(Const.FAIL_CREATE_CODE, "Trạm sạc không khả dụng.");
                }

                // --- BR10: Trạm phải có ít nhất 1 connector usable & không bị chiếm trong thời gian đặt ---
                var bookingStartTime = dto.StartTime;
                var bookingEndTime = dto.StartTime.AddMinutes(60); // mặc định 60 phút

                var usableConnectors = station.ChargingPosts
                    .Where(cp => !cp.IsDeleted && cp.Status.Equals("Available", StringComparison.OrdinalIgnoreCase))
                    .SelectMany(cp => cp.Connectors)
                    .Where(c =>
                        !c.IsDeleted &&
                        (c.Status.Equals(ConnectorStatus.Available.ToString(), StringComparison.OrdinalIgnoreCase) ||
                         c.Status.Equals(ConnectorStatus.Preparing.ToString(), StringComparison.OrdinalIgnoreCase))
                    )
                    .ToList();

                if (!usableConnectors.Any())
                    return new ServiceResult(Const.FAIL_CREATE_CODE, "Trạm sạc hiện không có cổng sạc hoạt động.");

                var usableConnectorIds = usableConnectors.Select(c => c.Id).ToList();
                // Đếm số booking đã chiếm connector trong khoảng thời gian này
                var overlappingBookings = await _unitOfWork.BookingRepository.GetAllAsync(
                    b => !b.IsDeleted &&
                         b.ConnectorId.HasValue &&
                         usableConnectorIds.Contains(b.ConnectorId.Value) &&
                         (bookingStartTime < b.EndTime && bookingEndTime > b.StartTime)
                );

                int connectorCount = usableConnectors.Count;
                int bookingCount = overlappingBookings.Count;

                // Nếu số booking >= số connector usable thì từ chối booking mới
                if (bookingCount >= connectorCount)
                {
                    return new ServiceResult(Const.FAIL_CREATE_CODE, "Tất cả cổng sạc tại trạm đã được đặt, không thể tạo thêm booking.");
                }

                bool isFullyBooked = await _unitOfWork.BookingRepository.GetQueryable()
                    .AnyAsync(b =>
                        !b.IsDeleted &&
                        b.ConnectorId.HasValue &&
                        usableConnectorIds.Contains(b.ConnectorId.Value) &&
                        (bookingStartTime < b.EndTime && bookingEndTime > b.StartTime)
                    );

                if (isFullyBooked)
                    return new ServiceResult(Const.FAIL_CREATE_CODE, "Tất cả cổng sạc tại trạm đều đã được đặt trong thời gian này.");

                // --- Tạo booking ---
                var booking = dto.Adapt<Booking>();
                booking.Id = Guid.NewGuid();
                booking.BookedBy = userId;
                booking.Status = BookingStatus.Scheduled.ToString();
                booking.EndTime = bookingEndTime;
                booking.CreatedAt = DateTime.Now;
                booking.UpdatedAt = DateTime.Now;
                booking.CheckInCode = await _checkInCodeService.GenerateUniqueCodeAsync();

                await _unitOfWork.BookingRepository.CreateAsync(booking);
                var result = await _unitOfWork.SaveChangesAsync();

                if (result > 0)
                {
                    var response = booking.Adapt<BookingViewDto>();
                    return new ServiceResult(Const.SUCCESS_CREATE_CODE, Const.SUCCESS_CREATE_MSG, response);
                }

                return new ServiceResult(Const.FAIL_CREATE_CODE, Const.FAIL_CREATE_MSG);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }
        }

        public async Task<IServiceResult> CheckInBooking(BookingCheckInDto request)
        {
            try
            {
                //  1. Tìm booking theo mã CheckInCode + userId
                var bookings = await _unitOfWork.BookingRepository.GetAllAsync(
                 b => b.CheckInCode == request.CheckInCode &&
                 !b.IsDeleted,
                include: b => b.Include(x => x.ConnectorNavigation)
                .Include(x => x.BookedByNavigation),
                asNoTracking: false

);

                var booking = bookings.FirstOrDefault();


                if (booking == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy booking.");

                //  2. Kiểm tra trạng thái
                if (!booking.Status.Equals(BookingStatus.Scheduled.ToString(), StringComparison.OrdinalIgnoreCase) &&
                    !booking.Status.Equals(BookingStatus.Reserved.ToString(), StringComparison.OrdinalIgnoreCase))
                {
                    return new ServiceResult(Const.FAIL_UPDATE_CODE, "Booking không ở trạng thái 'Scheduled' hoặc 'Reserved'.");
                }

                //  3. Kiểm tra mã check-in hợp lệ
                if (string.IsNullOrWhiteSpace(request.CheckInCode) ||
                    !string.Equals(booking.CheckInCode, request.CheckInCode, StringComparison.Ordinal))
                {
                    return new ServiceResult(Const.FAIL_UPDATE_CODE, "Mã check-in không hợp lệ.");
                }

                //  4. Kiểm tra thời gian check-in
                var now = DateTime.Now;
                if (now < booking.StartTime.AddMinutes(-15) || now > booking.EndTime)
                    return new ServiceResult(Const.FAIL_UPDATE_CODE, "Không thể check-in ngoài thời gian cho phép.");

                //  5. Mở khóa connector (nếu có gắn)
                if (booking.ConnectorNavigation != null)
                {
                    booking.ConnectorNavigation.IsLocked = false;
                    booking.ConnectorNavigation.Status = ConnectorStatus.Preparing.ToString(); // hoặc "Active"
                }

                //  6. Cập nhật booking sang "InProgress"
                booking.Status = BookingStatus.InProgress.ToString();
                booking.ActualStartTime = now;
                booking.UpdatedAt = now;

                var result = await _unitOfWork.SaveChangesAsync();

                if (result > 0)
                {
                    var response = booking.Adapt<BookingViewDto>(); return new ServiceResult(Const.SUCCESS_UPDATE_CODE, "Check-in thành công, trụ đã được mở khóa.", response);
                }

                return new ServiceResult(Const.FAIL_UPDATE_CODE, "Không thể hoàn tất check-in.");
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }
        }



        public async Task<IServiceResult> CompleteBookingAsync(Guid bookingId)
        {
            try
            {
                var booking = await _unitOfWork.BookingRepository.GetByIdAsync(
                    predicate: b => !b.IsDeleted && b.Id == bookingId,
                    asNoTracking: false
                );

                if (booking == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy booking");

                var session = await _unitOfWork.ChargingSessionRepository.GetByIdAsync(
                    predicate: s => s.BookingId == booking.Id && !s.IsDeleted,
                    asNoTracking: false
                );

                if (session == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy phiên sạc");

                // ❗ REQUIRE SESSION PAID
                if (session.Status != ChargingSessionStatus.Paid.ToString())
                    return new ServiceResult(Const.FAIL_UPDATE_CODE, "Phiên sạc chưa thanh toán, không thể hoàn tất booking");

                // Nếu đã completed thì thoát
                if (booking.Status == BookingStatus.Completed.ToString())
                    return new ServiceResult(Const.SUCCESS_UPDATE_CODE, "Booking đã hoàn tất trước đó");

                booking.Status = BookingStatus.Completed.ToString();
                booking.ActualEndTime = DateTime.Now;
                booking.UpdatedAt = DateTime.Now;

                await _unitOfWork.SaveChangesAsync();

                return new ServiceResult(Const.SUCCESS_UPDATE_CODE, "Hoàn tất booking thành công");
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }
        }


        public async Task<IServiceResult> CancelBooking(Guid bookingId, Guid userId)
        {
            try
            {
                // 1. Kiểm tra người dùng
                var user = await _unitOfWork.UserAccountRepository.GetByIdAsync(u => u.Id == userId && !u.IsDeleted);
                if (user == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy người dùng");

                var roles = await _userManager.GetRolesAsync(user);
                if (!roles.Any(r => r.Equals("EVDriver", StringComparison.OrdinalIgnoreCase)))
                    return new ServiceResult(Const.FAIL_UPDATE_CODE, "Chỉ tài xế xe điện (EVDriver) mới được hủy đặt chỗ");

                // 2. Lấy booking kèm connector → post → station
                var booking = await _unitOfWork.BookingRepository.GetByIdAsync(
                    predicate: b => b.Id == bookingId && !b.IsDeleted,
                    include: b => b.Include(x => x.ConnectorNavigation)
                                   .ThenInclude(c => c.ChargingPost)
                                       .ThenInclude(p => p.ChargingStationNavigation),
                    asNoTracking: false
                );
                if (booking == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy đặt chỗ");

                if (booking.BookedBy != userId)
                    return new ServiceResult(Const.FAIL_UPDATE_CODE, "Bạn không có quyền hủy đặt chỗ này");

                if (!booking.Status.Equals(BookingStatus.Scheduled.ToString(), StringComparison.OrdinalIgnoreCase))
                    return new ServiceResult(Const.FAIL_UPDATE_CODE, "Chỉ được hủy khi đặt chỗ đang ở trạng thái 'Đã lên lịch'");

                var now = DateTime.Now;

                // 3. Xác định hủy hợp lệ / không hợp lệ
                if (now < booking.StartTime && (booking.StartTime - now).TotalMinutes > 2)
                    booking.Status = BookingStatus.Cancelled.ToString();
                else
                    booking.Status = BookingStatus.CancelledInvalid.ToString();

                booking.UpdatedAt = now;

                // 4. Xử lý connector/post/station
                if (booking.ConnectorNavigation != null)
                {
                    var connector = booking.ConnectorNavigation;
                    var post = connector.ChargingPost;
                    var station = post?.ChargingStationNavigation;

                    if (post == null || station == null)
                        return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Dữ liệu trạm hoặc trụ không hợp lệ");

                    // Không cho hủy nếu connector đang hoạt động
                    if (connector.Status == ConnectorStatus.InUse.ToString()
                        || connector.Status == ConnectorStatus.Charging.ToString())
                    {
                        return new ServiceResult(Const.FAIL_UPDATE_CODE, "Không thể hủy khi connector đang hoạt động");
                    }

                    // Gọi lại hàm xử lý connector
                    HandleConnectorRelease(booking, now);
                }

                // 5. Lưu thay đổi
                var result = await _unitOfWork.SaveChangesAsync();
                if (result > 0)
                    return new ServiceResult(Const.SUCCESS_UPDATE_CODE, "Hủy đặt chỗ thành công");
                else
                    return new ServiceResult(Const.FAIL_UPDATE_CODE, "Hủy đặt chỗ thất bại");
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, $"Lỗi hệ thống: {ex.Message}");
            }
        }

        private void HandleConnectorRelease(Booking booking, DateTime now)
        {
            var connector = booking.ConnectorNavigation;
            var post = connector?.ChargingPost;
            var station = post?.ChargingStationNavigation;

            if (connector == null || post == null || station == null)
                return;

            int prevAvailable = post.AvailableConnectors;

            bool reservedByBooking =
                connector.IsLocked ||
                connector.Status == ConnectorStatus.Reserved.ToString();

            if (reservedByBooking)
            {
                connector.Status = ConnectorStatus.Available.ToString();
                connector.IsLocked = false;
                connector.UpdatedAt = now;

                post.AvailableConnectors += 1;

                if (post.VehicleTypeSupported == VehicleTypeEnum.Car.ToString())
                    station.AvailableCarConnectors += 1;
                else
                    station.AvailableBikeConnectors += 1;
            }

            if (prevAvailable == 0 && post.AvailableConnectors > 0)
            {
                if (post.VehicleTypeSupported == VehicleTypeEnum.Car.ToString())
                    station.AvailableCarChargingPosts += 1;
                else
                    station.AvailableBikeChargingPosts += 1;

                if (post.Status == ChargingPostStatus.Busy.ToString())
                    post.Status = ChargingPostStatus.Available.ToString();
            }

            if (post.AvailableConnectors < 0)
                post.AvailableConnectors = 0;

            post.UpdatedAt = now;
            station.UpdatedAt = now;
        }



        // Lấy chi tiết 1 booking cụ thể
        public async Task<IServiceResult> GetBookingDetail(Guid bookingId)
        {
            try
            {
                var booking = await _unitOfWork.BookingRepository.GetByIdAsync(
                    b => b.Id == bookingId && !b.IsDeleted,
                    include: b => b
                        .Include(x => x.BookedByNavigation)
                        .Include(x => x.ChargingStationNavigation)
                        .Include(x => x.ConnectorNavigation)
                            .ThenInclude(c => c.ChargingPost),
                    asNoTracking: false
                );

                if (booking == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy thông tin booking");

                var response = booking.Adapt<BookingViewDto>();
                return new ServiceResult(Const.SUCCESS_READ_CODE, Const.SUCCESS_READ_MSG, response);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }
        }
        // Lấy danh sách tất cả booking (hoặc chỉ booking của 1 user)
        public async Task<IServiceResult> GetBookingList(Guid? userId = null)
        {
            try
            {
                var bookings = await _unitOfWork.BookingRepository.GetAllAsync(
     b => !b.IsDeleted && (userId == null || b.BookedBy == userId),
     include: b => b
         .Include(x => x.ChargingStationNavigation)
         .Include(x => x.BookedByNavigation)
         .Include(x => x.ConnectorNavigation)
             .ThenInclude(c => c.ChargingPost)
              .Include(x => x.BookedByNavigation),
     orderBy: q => q.OrderByDescending(b => b.CreatedAt)
 );


                if (bookings == null || bookings.Count == 0)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy booking nào");

                var response = bookings.Adapt<List<BookingViewDto>>();
                return new ServiceResult(Const.SUCCESS_READ_CODE, Const.SUCCESS_READ_MSG, response);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }
        }



        // Khóa tài khoản EVDriver nếu trong ngày có >= 3 lần hủy không hợp lệ hoặc auto-cancel
        public async Task LockAccountsWithTooManyNoShows()
        {
            int threshold = 3;
            DateTime today = DateTime.Now.Date;

            var evDrivers = await _unitOfWork.EVDriverRepository.GetAllAsync(
                e => !e.IsDeleted,
                include: e => e.Include(x => x.UserAccount)
            );

            foreach (var ev in evDrivers)
            {
                var invalidCancels = await _unitOfWork.BookingRepository.GetAllAsync(
                    b => b.BookedBy == ev.AccountId &&
                         (b.Status == BookingStatus.CancelledInvalid.ToString() ||
                          b.Status == BookingStatus.AutoCancelled.ToString()) &&
                         b.CreatedAt >= today
                );

                if (invalidCancels.Count >= threshold)
                {
                    ev.Status = "Locked";
                    ev.UpdatedAt = DateTime.Now;
                }
            }

            await _unitOfWork.SaveChangesAsync();
        }




        // Tự động hủy các booking quá thời gian check-in cho phép
        // Chú ý: phương thức này sẽ xử lý những booking có trạng thái "Scheduled" mà
        // hiện tại  đã vượt quá StartTime + CHECKIN_ALLOW_MINUTES.
        // CHECKIN_ALLOW_MINUTES lấy từ SystemConfiguration (nếu không có → mặc định 15 phút).
        public async Task AutoCancelExpiredBookings()
        {
            var now = DateTime.Now;

            // Lấy cấu hình từ systemconfig 
            var config = await _unitOfWork.SystemConfigurationRepository.GetQueryable()
                        .AsNoTracking()
                        .Where(c => !c.IsDeleted && c.Name == "BOOKING_TIME_CANCEL_TRIGGER")
                        .FirstOrDefaultAsync();

            decimal allowance = 0;
            if (config != null && _unitOfWork.SystemConfigurationRepository.Validate(config))
                allowance = config.MinValue ?? 0;

            // Lấy tất cả booking Scheduled mà đã quá thời gian cho phép check-in hoặc đã kết thúc
            var expiredBookings = await _unitOfWork.BookingRepository.GetAllAsync(
                b => !b.IsDeleted &&
                     b.Status == BookingStatus.Scheduled.ToString() &&
                     (now > b.StartTime.AddMinutes((double)allowance) || now > b.EndTime),
                include: b => b.Include(x => x.ConnectorNavigation)
                               .ThenInclude(c => c.ChargingPost)
                                   .ThenInclude(p => p.ChargingStationNavigation),
                asNoTracking: false
            );

            foreach (var booking in expiredBookings)
            {
                // Hủy booking tự động
                booking.Status = BookingStatus.AutoCancelled.ToString();
                booking.UpdatedAt = now;

                // Dùng lại logic xử lý connector/post/station
                HandleConnectorRelease(booking, now);
            }

            await _unitOfWork.SaveChangesAsync();
        }





        // Tự động xử lý các booking thuộc trạm bị lỗi
        // Tự động xử lý các booking thuộc trạm bị lỗi
        // - Mục đích: Khi một trạm sạc bị lỗi (Status = "Error"), tất cả booking "Scheduled" tại đó
        //   sẽ được chuyển sang trạm khả dụng khác. Nếu không có trạm khả dụng, booking sẽ bị hủy.
        // - Chạy định kỳ bởi scheduler (ví dụ: background service hoặc cron job).
        // Tự động xử lý lại các booking thuộc các trạm sạc đang gặp lỗi
        public async Task AutoReassignBookingsForErrorStations()
        {
            //  Lấy tất cả các trạm sạc có trạng thái "Error" (đang bị lỗi) và chưa bị xóa
            var errorStations = await _unitOfWork.ChargingStationRepository.GetAllAsync(
                s => s.Status == "Error" && !s.IsDeleted, include: s => s.Include(x => x.ChargingPosts)
            );

            // 🔹 Nếu không có trạm nào bị lỗi thì không cần xử lý tiếp
            if (errorStations == null || !errorStations.Any())
                return;

            // 🔹 Cache (tải sẵn) danh sách trạm sạc đang khả dụng
            //     Mục đích: tránh việc truy vấn database nhiều lần trong vòng lặp
            var availableStations = (await _unitOfWork.ChargingStationRepository.GetAllAsync(
                s => s.Status == "Available" && !s.IsDeleted,
                include: s => s.Include(p => p.ChargingPosts)
            )).ToList();

            //  Ghi nhận thời điểm hiện tại để tái sử dụng cho các bản ghi cập nhật
            var now = DateTime.Now;

            //  Duyệt từng trạm sạc đang bị lỗi
            foreach (var station in errorStations)
            {
                //  Lấy toàn bộ booking thuộc trạm này có trạng thái "Scheduled" (đang chờ sạc)
                var bookings = await _unitOfWork.BookingRepository.GetAllAsync(
                    b => b.StationId == station.Id && b.Status == "Scheduled"
                );

                //  Duyệt từng booking cần xử lý
                foreach (var booking in bookings)
                {
                    //  Tìm một trạm thay thế có ít nhất 1 post đang ở trạng thái "Available"
                    //     => Ưu tiên trạm sẵn sàng phục vụ
                    var alternativeStation = availableStations.FirstOrDefault(
                        s => s.ChargingPosts.Any(p => p.Status == "Available")
                    );

                    if (alternativeStation != null)
                    {
                        //  Tìm thấy trạm thay thế phù hợp
                        //    → Cập nhật lại StationId của booking
                        booking.StationId = alternativeStation.Id;
                        booking.UpdatedAt = now;

                        //  Chọn một post đang Available trong trạm thay thế và đánh dấu nó là Reserved
                        var availablePost = alternativeStation.ChargingPosts
                            .FirstOrDefault(p => p.Status == "Available");

                        if (availablePost != null)
                        {
                            availablePost.Status = "Reserved";   // Post được giữ chỗ cho booking này
                            availablePost.UpdatedAt = now;
                        }
                    }
                    else
                    {
                        //  Không tìm thấy trạm thay thế nào phù hợp
                        //    → Hủy booking để tránh khách hàng chờ vô ích
                        booking.Status = "Cancelled";
                        booking.UpdatedAt = now;
                    }
                }
            }//  Lưu toàn bộ thay đổi (booking + trạm + post) xuống cơ sở dữ liệu
            await _unitOfWork.SaveChangesAsync();
        }
        public async Task AutoReserveConnectorBeforeStart()
        {
            var now = DateTime.Now;

            var upcomingBookings = await _unitOfWork.BookingRepository.GetAllAsync(
                b => !b.IsDeleted &&
                     b.Status == BookingStatus.Scheduled.ToString() &&
                     b.StartTime <= now.AddMinutes(7) &&
                     b.StartTime > now,
                include: b => b.Include(x => x.ChargingStationNavigation)
                               .ThenInclude(s => s.ChargingPosts)
                                   .ThenInclude(p => p.Connectors)
                               .Include(x => x.ConnectorNavigation),
                asNoTracking: false
            );

            foreach (var booking in upcomingBookings)
            {
                var station = booking.ChargingStationNavigation;

                var connector = station.ChargingPosts
                    .SelectMany(p => p.Connectors)
                    .FirstOrDefault(c => c.Status == ConnectorStatus.Available.ToString());

                if (connector == null)
                {
                    var blockingBookings = await _unitOfWork.BookingRepository.GetAllAsync(
                        b => b.ChargingStationNavigation.Id == station.Id &&
                             b.Status == BookingStatus.Scheduled.ToString() &&
                             b.EndTime > booking.StartTime,
                        asNoTracking: false
                    );

                    var nearestBlocking = blockingBookings
                        .OrderBy(b => b.EndTime)
                        .FirstOrDefault();

                    if (nearestBlocking != null)
                    {
                        var diff = nearestBlocking.EndTime - booking.StartTime;

                        if (diff.TotalMinutes <= 10)
                        {
                            // Nếu chênh lệch <= 10 phút thì booking mới chuyển sang Waiting
                            booking.Status = BookingStatus.Waiting.ToString();
                            booking.UpdatedAt = now;
                            continue;
                        }
                        else
                        {
                            // Giữ nguyên booking cũ với connector của nó
                            // => Hủy booking mới
                            booking.Status = BookingStatus.CompensatedCancelled.ToString();
                            booking.UpdatedAt = now;

                            // Cộng điểm cho driver profile của booking mới
                            var driverProfiles = await _unitOfWork.EVDriverRepository
                                .GetAllAsync(dp => dp.AccountId == booking.BookedBy && !dp.IsDeleted);

                            var driverProfile = driverProfiles.FirstOrDefault();
                            if (driverProfile != null)
                            {
                                driverProfile.Point += 100;
                                driverProfile.UpdatedAt = now;
                            }

                            continue;
                        }
                    }
                    else
                    {
                        // Không có connector khả dụng và không có booking để hoán đổi
                        booking.Status = BookingStatus.CompensatedCancelled.ToString();
                        booking.UpdatedAt = now;

                        // Cộng điểm cho driver profile của booking mới
                        var driverProfiles = await _unitOfWork.EVDriverRepository
                            .GetAllAsync(dp => dp.AccountId == booking.BookedBy && !dp.IsDeleted);

                        var driverProfile = driverProfiles.FirstOrDefault();
                        if (driverProfile != null)
                        {
                            driverProfile.Point += 100;
                            driverProfile.UpdatedAt = now;
                        }

                        continue;
                    }
                }
                else
                {
                    // Nếu có connector khả dụng thì gán cho booking mới
                    booking.ConnectorId = connector.Id;
                    booking.UpdatedAt = now;

                    connector.Status = ConnectorStatus.Reserved.ToString();
                    connector.IsLocked = true;
                    connector.UpdatedAt = now;

                    ApplyReserveLogic(connector, now);
                }
            }

            await _unitOfWork.SaveChangesAsync();
        }

        public async Task<IServiceResult> GetBookingsByStaff(Guid staffId)
        {
            // 1️ Kiểm tra nhân viên tồn tại và không bị xóa
            var staff = await _unitOfWork.UserAccountRepository.GetByIdAsync(
                u => u.Id == staffId && !u.IsDeleted,
                include: u => u.Include(x => x.ChargingStations)
            );

            if (staff == null)
                return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy nhân viên.");

            // 2️ Lấy danh sách trạm mà nhân viên này quản lý
            var stationIds = staff.ChargingStations
                .Where(s => !s.IsDeleted)
                .Select(s => s.Id)
                .ToList();

            if (!stationIds.Any())
                return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Nhân viên chưa được gán trạm nào.");

            // 3️ Lấy tất cả booking thuộc các trạm đó
            var bookings = await _unitOfWork.BookingRepository.GetAllAsync(
                b => stationIds.Contains(b.StationId) && !b.IsDeleted,
                include: b => b
                    .Include(x => x.BookedByNavigation)
                    .Include(x => x.ChargingStationNavigation)
                    .Include(x => x.ConnectorNavigation)
                        .ThenInclude(c => c.ChargingPost),
                orderBy: q => q.OrderByDescending(b => b.CreatedAt)
            );

            if (bookings == null || bookings.Count == 0)
                return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không có booking nào tại các trạm bạn quản lý.");

            var response = bookings.Adapt<List<BookingViewDto>>();
            return new ServiceResult(Const.SUCCESS_READ_CODE, Const.SUCCESS_READ_MSG, response);
        }
        private void ApplyReserveLogic(Connector connector, DateTime now)
        {
            var post = connector.ChargingPost;
            var station = post.ChargingStationNavigation;

            int prevAvailable = post.AvailableConnectors;

            // Reserve
            connector.Status = ConnectorStatus.Reserved.ToString();
            connector.IsLocked = true;
            connector.UpdatedAt = now;

            // Giảm AvailableConnectors trong Post
            post.AvailableConnectors -= 1;
            if (post.AvailableConnectors < 0)
                post.AvailableConnectors = 0;

            // Nếu từ còn connector → hết connector → Post chuyển Busy
            if (prevAvailable > 0 && post.AvailableConnectors == 0)
            {
                if (post.VehicleTypeSupported == VehicleTypeEnum.Car.ToString())
                    station.AvailableCarChargingPosts -= 1;
                else
                    station.AvailableBikeChargingPosts -= 1;

                post.Status = ChargingPostStatus.Busy.ToString();
            }

            // Giảm AvailableConnector trong Station
            if (post.VehicleTypeSupported == VehicleTypeEnum.Car.ToString())
                station.AvailableCarConnectors -= 1;
            else
                station.AvailableBikeConnectors -= 1;

            // Safety
            if (station.AvailableCarConnectors < 0)
                station.AvailableCarConnectors = 0;
            if (station.AvailableBikeConnectors < 0)
                station.AvailableBikeConnectors = 0;

            post.UpdatedAt = now;
            station.UpdatedAt = now;
        }


        public async Task AutoCompleteBookingsAsync()
        {
            // Lấy tất cả booking (không cần lọc ở đây)
            var bookings = await _unitOfWork.BookingRepository.GetAllAsync(
                b => !b.IsDeleted,
                asNoTracking: false
            );

            foreach (var booking in bookings)
            {
                // Gọi lại logic hoàn tất booking
                await CompleteBookingAsync(booking.Id);
            }
        }
    }
}
    