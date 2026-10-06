using BusinessLogic.Base;
using Common.DTOs.VehicleModelDto;
using Common.Enum.VehicleModel;

namespace BusinessLogic.IServices
{
    public interface IVehicleModelService
    {
        Task<IServiceResult> GetList();
        Task<IServiceResult> GetById(Guid vehicleModelId);
        Task<IServiceResult> Create(VehicleModelCreateDto dto, Guid adminId);
        Task<IServiceResult> Update(VehicleModelUpdateDto dto, Guid vehicleModelId);
        Task<IServiceResult> UpdateStatus(VehicleModelStatus status, Guid vehicleModelId);
        Task<IServiceResult> Delete(Guid vehicleModelId);
    }
}
