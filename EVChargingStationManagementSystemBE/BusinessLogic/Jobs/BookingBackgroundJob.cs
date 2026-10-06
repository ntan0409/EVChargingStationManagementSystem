using BusinessLogic.IServices;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace BusinessLogic.Jobs
{
    public class BookingBackgroundJob : BackgroundService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<BookingBackgroundJob> _logger;
        private readonly TimeSpan _interval = TimeSpan.FromSeconds(30);

        public BookingBackgroundJob(IServiceScopeFactory scopeFactory, ILogger<BookingBackgroundJob> logger)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    using var scope = _scopeFactory.CreateScope();
                    var bookingService = scope.ServiceProvider.GetRequiredService<IBookingService>();

                    _logger.LogInformation("[BookingBackgroundJob] bắt đầu chạy lúc {time}", DateTime.Now);

                    await bookingService.LockAccountsWithTooManyNoShows();
                    await bookingService.AutoCancelExpiredBookings();
                    //await bookingService.AutoReassignBookingsForErrorStations();
                    await bookingService.AutoReserveConnectorBeforeStart();
                    await bookingService.AutoCompleteBookingsAsync();

                    _logger.LogInformation("[BookingBackgroundJob] hoàn tất vòng chạy lúc {time}", DateTime.Now);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "[BookingBackgroundJob] lỗi trong vòng chạy");
                }

                await Task.Delay(_interval, stoppingToken);
            }
        }
    }
}