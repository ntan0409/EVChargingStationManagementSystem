using Common;
using Common.DTOs.VehicleModelDto;
using Common.Enum.VehicleModel;
using Mapster;
using Infrastructure.IUnitOfWork;
using Infrastructure.Models;
using BusinessLogic.Base;
using BusinessLogic.IServices;
using Microsoft.EntityFrameworkCore;

namespace BusinessLogic.Services
{
    public class VehicleModelService(IUnitOfWork unitOfWork) : IVehicleModelService
    {
        private readonly IUnitOfWork _unitOfWork = unitOfWork;
        public async Task<IServiceResult> GetList()
        {

            try
            {
                var vehicleModels = await _unitOfWork.VehicleModelRepository.GetQueryable()
                    .AsNoTracking()
                    .Where(v => !v.IsDeleted)
                    .OrderByDescending(v => v.CreatedAt)
                    .ProjectToType<VehicleModelViewGeneralDto>()
                    .ToListAsync();

                if (vehicleModels == null || vehicleModels.Count == 0)
                    return new ServiceResult(
                        Const.WARNING_NO_DATA_CODE,
                        "Không tìm thấy mẫu xe nào",
                        new List<VehicleModelViewGeneralDto>());

                else
                    return new ServiceResult(Const.SUCCESS_READ_CODE, Const.SUCCESS_READ_MSG, vehicleModels);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }
        }

        public async Task<IServiceResult> GetById(Guid vehicleModelId)
        {

            try
            {
                var vehicleModel = await _unitOfWork.VehicleModelRepository.GetQueryable()
                    .AsNoTracking()
                    .Where(v => !v.IsDeleted && v.Id == vehicleModelId)
                    .ProjectToType<VehicleModelViewDetailDto>()
                    .FirstOrDefaultAsync();

                if (vehicleModel == null)
                    return new ServiceResult(
                        Const.WARNING_NO_DATA_CODE,
                        "Không tìm thấy mẫu xe nào"
                    );

                else
                    return new ServiceResult(Const.SUCCESS_READ_CODE, Const.SUCCESS_READ_MSG, vehicleModel);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }
        }

        public async Task<IServiceResult> Create(VehicleModelCreateDto dto, Guid adminId)
        {
            try
            {
                var vehicleModel = dto.Adapt<VehicleModel>();
                vehicleModel.Id = Guid.NewGuid();
                vehicleModel.Brand = "";
                vehicleModel.Status = "Inactive";
                vehicleModel.CreatedBy = adminId;

                await _unitOfWork.VehicleModelRepository.CreateAsync(vehicleModel);
                var result = await _unitOfWork.SaveChangesAsync();
                if (result > 0)
                {
                    var response = vehicleModel.Adapt<VehicleModelViewDetailDto>();
                    return new ServiceResult(Const.SUCCESS_CREATE_CODE, Const.SUCCESS_CREATE_MSG, response);
                }
                else
                    return new ServiceResult(Const.FAIL_CREATE_CODE, Const.FAIL_CREATE_MSG);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }
        }

        public async Task<IServiceResult> Update(VehicleModelUpdateDto dto, Guid vehicleModelId)
        {
            try
            {
                var vehicleModel = await _unitOfWork.VehicleModelRepository.GetQueryable()
                    .Where(v => !v.IsDeleted && v.Id == vehicleModelId)
                    .FirstOrDefaultAsync();

                if (vehicleModel == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Mẫu xe không tồn tại");

                vehicleModel = dto.Adapt(vehicleModel);
                vehicleModel.UpdatedAt = DateTime.UtcNow;

                var result = await _unitOfWork.SaveChangesAsync();
                if (result > 0)
                {
                    var response = vehicleModel.Adapt<VehicleModelViewDetailDto>();
                    return new ServiceResult(Const.SUCCESS_UPDATE_CODE, Const.SUCCESS_UPDATE_MSG, response);
                }
                else
                    return new ServiceResult(Const.FAIL_UPDATE_CODE, Const.FAIL_UPDATE_MSG);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }
        }

        public async Task<IServiceResult> UpdateStatus(VehicleModelStatus status, Guid vehicleModelId)
        {
            try
            {
                var vehicleModel = await _unitOfWork.VehicleModelRepository.GetQueryable()
                    .Where(v => !v.IsDeleted && v.Id == vehicleModelId)
                    .FirstOrDefaultAsync();
                if (vehicleModel == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Mẫu xe không tồn tại");

                vehicleModel.Status = status.ToString();
                vehicleModel.UpdatedAt = DateTime.UtcNow;

                var result = await _unitOfWork.SaveChangesAsync();
                if (result > 0)
                {
                    var response = vehicleModel.Adapt<VehicleModelViewDetailDto>();
                    return new ServiceResult(Const.SUCCESS_UPDATE_CODE, Const.SUCCESS_UPDATE_MSG, response);
                }
                else
                    return new ServiceResult(Const.FAIL_UPDATE_CODE, Const.FAIL_UPDATE_MSG);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }
        }

        public async Task<IServiceResult> Delete(Guid vehicleModelId)
        {
            try
            {
                var vehicleModel = await _unitOfWork.VehicleModelRepository.GetQueryable()
                    .Where(v => !v.IsDeleted && v.Id == vehicleModelId)
                    .FirstOrDefaultAsync();
                if (vehicleModel == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Mẫu xe không tồn tại");

                vehicleModel.IsDeleted = true;
                vehicleModel.UpdatedAt = DateTime.UtcNow;

                var result = await _unitOfWork.SaveChangesAsync();
                if (result > 0)
                    return new ServiceResult(Const.SUCCESS_DELETE_CODE, Const.SUCCESS_DELETE_MSG);
                else
                    return new ServiceResult(Const.FAIL_DELETE_CODE, Const.FAIL_DELETE_MSG);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }
        }
    }
}
