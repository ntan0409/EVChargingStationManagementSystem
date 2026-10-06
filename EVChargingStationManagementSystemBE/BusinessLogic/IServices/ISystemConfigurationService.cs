using BusinessLogic.Base;
using Common.DTOs.SystemConfigurationDto;

namespace BusinessLogic.IServices
{
    public interface ISystemConfigurationService
    {
        Task<IServiceResult> GetList();
        Task<IServiceResult> Update(int id, SystemConfigurationUpdateDto dto, Guid userId);
        Task<IServiceResult> GetByName(string configName);
    }
}
