using Infrastructure.Base;
using Infrastructure.Data;
using Infrastructure.IRepositories;
using Infrastructure.Models;

namespace Infrastructure.Repositories
{
    public class SystemConfigurationRepository(EVCSMSContext context) : GenericRepository<SystemConfiguration> (context), ISystemConfigurationRepository
    {
        public bool Validate(SystemConfiguration configuration)
        {
            if (configuration == null)
                return false;

            // Rule 1: EffectedDateFrom bắt buộc
            if (configuration.EffectedDateFrom == default)
                return false;

            // Rule 2: Nếu có EffectedDateTo thì phải >= EffectedDateFrom
            if (configuration.EffectedDateTo.HasValue &&
                configuration.EffectedDateTo.Value < configuration.EffectedDateFrom)
                return false;

            // Rule 3: Nếu có cả MinValue và MaxValue thì MinValue phải <= MaxValue
            if (configuration.MinValue.HasValue &&
                configuration.MaxValue.HasValue &&
                configuration.MinValue.Value > configuration.MaxValue.Value)
                return false;

            // Rule 4: Kiểm tra hiệu lực theo thời gian
            // Nếu EffectedDateTo có giá trị, thì hiện tại phải nằm trong khoảng đó
            // Nếu không có EffectedDateTo, chỉ cần EffectedDateFrom <= hiện tại
            var now = DateTime.Now;
            if (configuration.EffectedDateFrom > now)
                return false;

            if (configuration.EffectedDateTo.HasValue && configuration.EffectedDateTo.Value < now)
                return false;

            return true;
        }
    }
}
