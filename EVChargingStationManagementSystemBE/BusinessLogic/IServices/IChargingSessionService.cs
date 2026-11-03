using BusinessLogic.Base;
using Common.DTOs.ChargingSessionDto;

namespace BusinessLogic.IServices
{
    public interface IChargingSessionService
    {
        Task<IServiceResult> GetList();
        Task<IServiceResult> GetById(Guid SessionId, Guid? accountId = null);
        Task<IServiceResult> GetByConnector(Guid ConnectorId, Guid? accountId = null);
        Task<IServiceResult> GetCurrent(Guid accountId);
        Task<IServiceResult> Start(ChargingSessionStartDto dto, Guid? accountId = null);
        Task<IServiceResult> Stop(ChargingSessionStopDto dto, Guid sessionId, Guid? accountId = null);
    }
}
