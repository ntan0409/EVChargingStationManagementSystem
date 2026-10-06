using BusinessLogic.Base;
using Common.DTOs.ChargingPostDto;
using Common.Enum.ChargingPost;

namespace BusinessLogic.IServices
{
    public interface IChargingPostService
    {
        Task<IServiceResult> GetList();
        Task<IServiceResult> GetById(Guid postId);
        Task<IServiceResult> Create(ChargingPostCreateDto dto);
        Task<IServiceResult> Update(ChargingPostUpdateDto dto, Guid stationId);
        Task<IServiceResult> UpdateStatus(ChargingPostUpdateStatus status, Guid postId);
        Task<IServiceResult> Delete(Guid postId);
    }
}
