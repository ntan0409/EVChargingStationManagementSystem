using BusinessLogic.Base;
using Common.DTOs.ChargingSessionDto;

namespace BusinessLogic.IServices
{
    public interface IChargingSessionService
    {
        Task<IServiceResult> GetList();
        Task<IServiceResult> GetById(Guid SessionId);
        Task<IServiceResult> GetByConnector(Guid ConnectorId);
        Task<IServiceResult> Start(ChargingSessionStartDto dto);
        Task<IServiceResult> Stop(ChargingSessionStopDto dto, Guid sessionId);
    }
}
