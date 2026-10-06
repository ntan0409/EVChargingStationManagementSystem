using BusinessLogic.Base;
using Common.DTOs.BookingDto;
using Infrastructure.Models;
using System.Threading.Tasks;

namespace BusinessLogic.IServices
{
    public interface IBookingService
    {
        Task<IServiceResult> CreateBooking(BookingCreatedDto dto, Guid userId);
        Task<IServiceResult> GetBookingList(Guid? userId = null);
        Task<IServiceResult> GetBookingDetail(Guid bookingId);
        Task<IServiceResult> CheckInBooking(BookingCheckInDto request);
        Task<IServiceResult> CompleteBookingAsync(Guid bookingId);
        Task<IServiceResult> CancelBooking(Guid bookingId, Guid userId);
        Task AutoCancelExpiredBookings();
        //Task AutoReassignBookingsForErrorStations();
        Task<IServiceResult> GetBookingsByStaff(Guid staffId);
        Task AutoCompleteBookingsAsync();
        Task LockAccountsWithTooManyNoShows();
        Task AutoReserveConnectorBeforeStart();


    }
}


