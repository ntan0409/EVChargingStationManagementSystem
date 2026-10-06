using BusinessLogic.Base;
using Common.DTOs.ConnectorDto;
using Common.Enum.Connector;

namespace BusinessLogic.IServices
{
    public interface IConnectorService
    {
        Task<IServiceResult> GetList(Guid chargingPostId);
        Task<IServiceResult> GetById(Guid connectorId);
        Task<IServiceResult> Create(ConnectorCreateDto dto);
        Task<IServiceResult> Update(ConnectorUpdateDto dto, Guid connectorId);
        Task<IServiceResult> UpdateStatus(ConnectorUpdateStatus status, Guid connectorId);
        Task<IServiceResult> UpdateConnectorCount(bool toggle, Guid connectorId);
        Task<IServiceResult> Delete(Guid connectorId);
    }
}
