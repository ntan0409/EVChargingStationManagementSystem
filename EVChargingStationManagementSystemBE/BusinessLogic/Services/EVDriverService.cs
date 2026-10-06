using BusinessLogic.Base;
using BusinessLogic.IServices;
using Common;
using Common.DTOs.ProfileEVDriverDto;
using Infrastructure.IUnitOfWork;
using Infrastructure.Models;
using Mapster;
using Microsoft.EntityFrameworkCore;

namespace BusinessLogic.Services
{
    public class EVDriverService(
        IUnitOfWork unitOfWork
    ) : IEVDriverService
    {
        private readonly IUnitOfWork _unitOfWork = unitOfWork;

        //  Lấy danh sách tất cả EVDriver
        public async Task<IServiceResult> GetAll()
        {
            try
            {
                var drivers = await _unitOfWork.EVDriverRepository.GetQueryable()
                    .AsNoTracking()
                    .Where(d => !d.IsDeleted)
                    .Include(d => d.UserAccount)
                    .Include(d => d.UserVehicles)
                        .ThenInclude(uv => uv.VehicleModel)
                    .OrderByDescending(d => d.CreatedAt)
                    .ProjectToType<EVDriverViewDto>()
                    .ToListAsync();
                if (drivers == null || drivers.Count == 0)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy EVDriver nào");

                return new ServiceResult(Const.SUCCESS_READ_CODE, Const.SUCCESS_READ_MSG, drivers);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }
        }

        //  Lấy chi tiết EVDriver theo Id
        public async Task<IServiceResult> GetById(Guid driverId)
        {
            try
            {
                var driver = await _unitOfWork.EVDriverRepository.GetQueryable()
                    .AsNoTracking()
                    .Where(d => d.Id == driverId && !d.IsDeleted)
                    .Include(d => d.UserAccount)
                    .Include(d => d.UserVehicles)
                        .ThenInclude(uv => uv.VehicleModel)
                    .OrderByDescending(d => d.CreatedAt)
                    .ProjectToType<EVDriverViewDto>()
                    .ToListAsync();

                if (driver == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy EVDriver");

                return new ServiceResult(Const.SUCCESS_READ_CODE, Const.SUCCESS_READ_MSG, driver);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }
        }

        public async Task<IServiceResult> GetByAccountId(Guid accountId)
        {
            try
            {
                var driver = await _unitOfWork.UserAccountRepository.GetQueryable()
                    .AsNoTracking()
                    .Where(ua => ua.Id == accountId && !ua.IsDeleted && ua.EVDriverProfile != null)
                    .Include(ua => ua.EVDriverProfile)
                    .ProjectToType<EVDriverViewDto>()
                    .FirstOrDefaultAsync();

                if (driver == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy EVDriver");

                return new ServiceResult(Const.SUCCESS_READ_CODE, Const.SUCCESS_READ_MSG, driver);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }
        }

        public async Task<IServiceResult> UpdateProfile(EVDriverUpdateSelfDto dto)
        {
            try
            {
                var driver = await _unitOfWork.EVDriverRepository.GetQueryable()
                    .Where(d => d.Id == dto.DriverId && !d.IsDeleted)
                    .Include(d => d.UserAccount)
                    .Include(d => d.UserVehicles)
                    .FirstOrDefaultAsync();

                if (driver == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy EVDriver");

                // Cập nhật thông tin cơ bản
                dto.Adapt(driver);
                driver.UpdatedAt = DateTime.Now;

                if (driver.UserAccount != null)
                {
                    dto.Adapt(driver.UserAccount);
                    driver.UserAccount.UpdatedAt = DateTime.Now;
                }

                // Nếu có danh sách xe mới từ client
                if (dto.VehicleModelIds != null && dto.VehicleModelIds.Any())
                {
                    var existingVehicleIds = driver.UserVehicles
                        .Select(uv => uv.VehicleModelId)
                        .ToList();

                    // Chỉ thêm những xe chưa có
                    var newVehicleIds = dto.VehicleModelIds
                        .Except(existingVehicleIds)
                        .ToList();

                    if (newVehicleIds.Any())
                    {
                        var newUserVehicles = newVehicleIds.Select(id => new UserVehicle
                        {
                            DriverId = driver.Id,
                            VehicleModelId = id
                        }).ToList();

                        await _unitOfWork.UserVehicleRepository.BulkCreateAsync(newUserVehicles);
                    }
                }

                //  Lưu toàn bộ thay đổi
                var result = await _unitOfWork.SaveChangesAsync();
                if (result <= 0)
                    return new ServiceResult(Const.FAIL_UPDATE_CODE, Const.FAIL_UPDATE_MSG);

                //  Lấy lại profile sau khi cập nhật
                var updatedDriver = await _unitOfWork.EVDriverRepository.GetQueryable()
                    .AsNoTracking()
                    .Where(d => d.Id == dto.DriverId)
                    .Include(d => d.UserAccount)
                    .Include(d => d.UserVehicles)
                        .ThenInclude(uv => uv.VehicleModel)
                    .ProjectToType<EVDriverViewDto>()
                    .FirstOrDefaultAsync();
                if (updatedDriver == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy profile");
                return new ServiceResult(Const.SUCCESS_UPDATE_CODE, Const.SUCCESS_UPDATE_MSG, updatedDriver);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }
        }

        // Admin cập nhật trạng thái EVDriver
        public async Task<IServiceResult> UpdateStatus(Guid driverId, EVDriverUpdateStatusDto dto)
        {
            try
            {
                var driver = await _unitOfWork.EVDriverRepository.GetQueryable()
                    .Where(d => d.Id == driverId && !d.IsDeleted)
                    .FirstOrDefaultAsync();

                if (driver == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy EVDriver");

                driver.Status = dto.Status;
                driver.UpdatedAt = DateTime.Now;

                var result = await _unitOfWork.SaveChangesAsync();
                if (result <= 0)
                    return new ServiceResult(Const.FAIL_UPDATE_CODE, Const.FAIL_UPDATE_MSG);

                var response = driver.Adapt<EVDriverViewDto>();
                return new ServiceResult(Const.SUCCESS_UPDATE_CODE, Const.SUCCESS_UPDATE_MSG, response);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }
        }




        //  Xóa mềm EVDriver
        public async Task<IServiceResult> Delete(Guid driverId)
        {
            try
            {
                var driver = await _unitOfWork.EVDriverRepository.GetQueryable()
                    .Where(d => d.Id == driverId && !d.IsDeleted)
                    .FirstOrDefaultAsync();

                if (driver == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy EVDriver");

                driver.IsDeleted = true;
                driver.Status = "Inactive";
                driver.UpdatedAt = DateTime.Now;

                var result = await _unitOfWork.SaveChangesAsync();
                if (result <= 0)
                    return new ServiceResult(Const.FAIL_DELETE_CODE, Const.FAIL_DELETE_MSG);

                return new ServiceResult(Const.SUCCESS_DELETE_CODE, Const.SUCCESS_DELETE_MSG);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }
        }
        // EVDriver tự xem hồ sơ của mình
        // EVDriver xem hồ sơ của mình (theo AccountId)
        public async Task<IServiceResult> GetMyProfile(Guid accountId)
        {
            try
            {
                // Lấy thông tin EVDriver gắn với tài khoản đang đăng nhập
                var driver = await _unitOfWork.EVDriverRepository.GetQueryable()
                    .AsNoTracking()
                    .Where(d => d.AccountId == accountId && !d.IsDeleted)
                    .Include(d => d.UserAccount)
                    .Include(d => d.UserVehicles)
                        .ThenInclude(uv => uv.VehicleModel)
                    .ProjectToType<EVDriverViewDto>()
                    .FirstOrDefaultAsync();


                // Nếu không tìm thấy tài xế
                if (driver == null)
                    return new ServiceResult(
                        Const.WARNING_NO_DATA_CODE,
                        "Không tìm thấy hồ sơ tài xế tương ứng với tài khoản hiện tại."
                    );

                return new ServiceResult(
                    Const.SUCCESS_READ_CODE,
                    Const.SUCCESS_READ_MSG,
                    driver
                );
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }
        }

        // EVDriver xóa xe khỏi hồ sơ cá nhân (hard delete chỉ bản ghi UserVehicle)
        public async Task<IServiceResult> DeleteMyVehicle(Guid accountId, Guid vehicleModelId)
        {
            try
            {
                // Lấy driver kèm danh sách xe
                var driver = await _unitOfWork.EVDriverRepository.GetQueryable()
                    .Where(d => d.AccountId == accountId && !d.IsDeleted)
                    .Include(d => d.UserVehicles)
                    .FirstOrDefaultAsync();

                if (driver == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy hồ sơ của bạn.");

                // Tìm xe cần xóa trong danh sách
                var userVehicle = driver.UserVehicles.FirstOrDefault(uv => uv.VehicleModelId == vehicleModelId);
                if (userVehicle == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy xe trong hồ sơ của bạn.");

                // Xóa cứng bản ghi UserVehicle (KHÔNG đụng vào VehicleModel)
                await _unitOfWork.UserVehicleRepository.RemoveAsync(userVehicle);


                var result = await _unitOfWork.SaveChangesAsync();
                if (result <= 0)
                    return new ServiceResult(Const.FAIL_DELETE_CODE, "Xóa xe thất bại.");

                return new ServiceResult(Const.SUCCESS_DELETE_CODE, "Xe đã được xóa khỏi hồ sơ thành công.");
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }
        }
    }
}
