using Infrastructure.IRepositories;

namespace Infrastructure.IUnitOfWork
{
    public interface IUnitOfWork : IDisposable
    {
        Task<int> SaveChangesAsync();
        IBookingRepository  BookingRepository { get; }
        IReportRepository ReportRepository { get; }
        ISCStaffRepository SCStaffRepository { get; }
        IVehicleModelRepository VehicleModelRepository { get; }
        IChargingStationRepository ChargingStationRepository { get; }
        IEVDriverRepository EVDriverRepository { get; }
         IUserAccountRepository UserAccountRepository { get; }
        IChargingPostRepository ChargingPostRepository { get; }
        IPaymentRepository PaymentRepository { get; }
        IChargingSessionRepository ChargingSessionRepository { get; }
        ISystemConfigurationRepository SystemConfigurationRepository { get; }
        IConnectorRepository ConnectorRepository { get; }
        ITransactionRepository TransactionRepository { get; }
        INotificationRecipientRepository NotificationRecipientRepository { get; }
        INotificationRepository NotificationRepository { get; }
        IUserVehicleRepository UserVehicleRepository { get; }
        IFeedBackRepository FeedBackRepository { get; }
        IUserVoucherRepository UserVoucherRepository { get; }
            IVoucherRepository VoucherRepository { get; }
        }
}
