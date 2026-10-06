using BusinessLogic.IServices;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace BusinessLogic.Jobs
{
    public class VoucherExpiryJob : BackgroundService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<VoucherExpiryJob> _logger;
        private readonly TimeSpan _interval = TimeSpan.FromHours(1);

        public VoucherExpiryJob(IServiceScopeFactory scopeFactory,
                                ILogger<VoucherExpiryJob> logger)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("VoucherExpiryJob started.");

            // Cho DB, migration, context khởi động xong
            await Task.Delay(TimeSpan.FromSeconds(10), stoppingToken);

            while (!stoppingToken.IsCancellationRequested)
            {
                using var scope = _scopeFactory.CreateScope();
                var voucherService = scope.ServiceProvider.GetRequiredService<IVoucherService>();

                try
                {
                    int expired = await voucherService.ExpireAllExpiredVouchers();

                    if (expired > 0)
                        _logger.LogInformation("[VoucherExpiryJob] Đã hết hạn {count} vouchers", expired);
                    else
                        _logger.LogInformation("[VoucherExpiryJob] Không có voucher nào hết hạn.");
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "VoucherExpiryJob ERROR");
                }

                await Task.Delay(_interval, stoppingToken);
            }

            _logger.LogInformation("VoucherExpiryJob stopped.");
        }
    }
}
