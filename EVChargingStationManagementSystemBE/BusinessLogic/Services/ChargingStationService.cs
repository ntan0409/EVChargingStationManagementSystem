using BusinessLogic.Base;
using BusinessLogic.IServices;
using Common;
using Common.DTOs.ChargingStationDto;
using Common.Enum.ChargingPost;
using Common.Enum.ChargingStation;
using Common.Enum.Connector;
using Common.Enum.User;
using Common.Enum.VehicleModel;
using Infrastructure.IUnitOfWork;
using Infrastructure.Models;
using Mapster;
using Microsoft.EntityFrameworkCore;

namespace BusinessLogic.Services
{
    public class ChargingStationService(IUnitOfWork unitOfWork) : IChargingStationService
    {
        private readonly IUnitOfWork _unitOfWork = unitOfWork;

        public async Task<IServiceResult> GetList()
        {

            try
            {
                var chargingStation = await _unitOfWork.ChargingStationRepository.GetQueryable()
                    .AsNoTracking()
                    .Where(c => !c.IsDeleted)
                    .Include( c => c.OperatorNavigation)
                    .OrderByDescending( c => c.CreatedAt)
                    .ProjectToType<ChargingStationViewGeneralDto>()
                    .ToListAsync();

                if (chargingStation == null || chargingStation.Count == 0)
                    return new ServiceResult(
                        Const.WARNING_NO_DATA_CODE,
                        "Không tìm thấy trạm sạc nào");

                else
                    return new ServiceResult(Const.SUCCESS_READ_CODE, Const.SUCCESS_READ_MSG, chargingStation);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }
        }

        public async Task<IServiceResult> GetById(Guid StationId)
        {

            try
            {
                var chargingStation = await _unitOfWork.ChargingStationRepository.GetQueryable()
                    .Where(c => !c.IsDeleted && c.Id == StationId)
                    .Include(c => c.ChargingPosts.Where(cp => !cp.IsDeleted).OrderByDescending( cp => cp.CreatedAt))
                    .Include(cp => cp.OperatorNavigation)
                    .OrderByDescending(cp => cp.CreatedAt)
                    //.ProjectToType<ChargingStationsViewDetailDto>()
                    .FirstOrDefaultAsync();
                if (chargingStation == null)
                    return new ServiceResult(
                        Const.WARNING_NO_DATA_CODE,
                        "Không tìm thấy trạm sạc nào"
                    );

                else
                {
                    var response = chargingStation.Adapt<ChargingStationsViewDetailDto>();
                    return new ServiceResult(Const.SUCCESS_READ_CODE, Const.SUCCESS_READ_MSG, response);
                }
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }
        }

        public async Task<IServiceResult> GetByStaffId(Guid StaffAccountId)
        {

            try
            {
                var chargingStation = await _unitOfWork.ChargingStationRepository.GetQueryable()
                    .Where(c => !c.IsDeleted && c.OperatorId == StaffAccountId)
                    .Include(c => c.ChargingPosts.Where(cp => !cp.IsDeleted).OrderByDescending(cp => cp.CreatedAt))
                    .Include(cp => cp.OperatorNavigation)
                    .OrderByDescending(cp => cp.CreatedAt)
                    .ProjectToType<ChargingStationsViewDetailDto>()
                    .FirstOrDefaultAsync();
                if (chargingStation == null)
                    return new ServiceResult(
                        Const.WARNING_NO_DATA_CODE,
                        "Không tìm thấy trạm sạc nào"
                    );

                return new ServiceResult(Const.SUCCESS_READ_CODE, Const.SUCCESS_READ_MSG, chargingStation);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }
        }

        public async Task<IServiceResult> Create(ChargingStationCreateDto dto)
        {
            try
            {
                if (dto.OperatorId != null)
                {
                    var staff = await _unitOfWork.UserAccountRepository.GetQueryable()
                    .Where(s => !s.IsDeleted && s.Id == dto.OperatorId)
                    .Include(s => s.SCStaffProfile)
                    .FirstOrDefaultAsync();

                    if (staff == null || staff.SCStaffProfile == null)
                        return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Nhân viên trạm không tồn tại");

                    staff.Status = UserStatus.Assigned.ToString();
                    staff.UpdatedAt = DateTime.Now;
                    staff.SCStaffProfile.WorkingLocation = dto.Location;
                    staff.SCStaffProfile.UpdatedAt = DateTime.Now;

                    var chargingStations = await _unitOfWork.ChargingStationRepository.GetQueryable()
                    .AsNoTracking()
                    .Include(cs => cs.OperatorNavigation)
                    .ToListAsync();
                    foreach (var station in chargingStations)
                        if (station.OperatorId == dto.OperatorId)
                            return new ServiceResult(Const.FAIL_CREATE_CODE,
                                $"Nhân viên {station.OperatorNavigation.Name} đã được phân công ở trạm {station.StationName} rồi");
                }

                var chargingStation = dto.Adapt<ChargingStation>();
                chargingStation.Id = Guid.NewGuid();
                chargingStation.Status = "Inactive";
                chargingStation.CreatedAt = DateTime.Now;
                chargingStation.UpdatedAt = DateTime.Now;

                await _unitOfWork.ChargingStationRepository.CreateAsync(chargingStation);
                var result = await _unitOfWork.SaveChangesAsync();
                if (result > 0)
                {
                    var response = chargingStation.Adapt<ChargingStationViewGeneralDto>();
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

        public async Task<IServiceResult> Update(ChargingStationUpdateDto dto, Guid stationId)
        {
            try
            {
                if (dto.OperatorId != null)
                {
                    var staff = await _unitOfWork.UserAccountRepository.GetQueryable()
                    .Where(s => !s.IsDeleted && s.Id == dto.OperatorId)
                    .Include(s => s.SCStaffProfile)
                    .FirstOrDefaultAsync();

                    if (staff == null || staff.SCStaffProfile == null)
                        return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Nhân viên trạm không tồn tại");

                    // Cập nhật trạng thái nhân viên được phân công thành Assigned
                    staff.Status = UserStatus.Assigned.ToString();
                    staff.UpdatedAt = DateTime.Now;
                    staff.SCStaffProfile.WorkingLocation = dto.Location ?? staff.SCStaffProfile.WorkingLocation;
                    staff.SCStaffProfile.UpdatedAt = DateTime.Now;

                    var chargingStations = await _unitOfWork.ChargingStationRepository.GetQueryable()
                    .AsNoTracking()
                    .Include(cs => cs.OperatorNavigation)
                    .ToListAsync();
                    foreach (var station in chargingStations)
                        if (station.OperatorId == dto.OperatorId)
                            return new ServiceResult(Const.FAIL_UPDATE_CODE,
                                $"Nhân viên {station.OperatorNavigation.Name} đã được phân công ở trạm {station.StationName} rồi");
                }

                var chargingStation = await _unitOfWork.ChargingStationRepository.GetQueryable()
                    .Where(c => c.Id == stationId)
                    .FirstOrDefaultAsync();
                if (chargingStation == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Trạm sạc không tồn tại");

                // Cập nhật trạng thái nhân viên hiện tại thành Active nếu có
                if (chargingStation.OperatorId != null)
                {
                    var currentStaff = await _unitOfWork.UserAccountRepository.GetQueryable()
                    .Where(s => !s.IsDeleted && s.Id == chargingStation.OperatorId)
                    .Include(s => s.SCStaffProfile)
                    .FirstOrDefaultAsync();
                    if (currentStaff != null)
                    {
                        currentStaff.Status = UserStatus.Active.ToString();
                        currentStaff.UpdatedAt = DateTime.Now;
                        currentStaff.SCStaffProfile.WorkingLocation = null;
                        currentStaff.SCStaffProfile.UpdatedAt = DateTime.Now;
                    }
                }

                chargingStation = dto.Adapt(chargingStation);
                chargingStation.UpdatedAt = DateTime.Now;

                var result = await _unitOfWork.SaveChangesAsync();
                if (result > 0)
                {
                    var response = chargingStation.Adapt<ChargingStationViewGeneralDto>();
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

        public async Task<IServiceResult> UpdateStatus(ChargingStationUpdateStatus status, Guid stationId)
        {
            try
            {
                var chargingStation = await _unitOfWork.ChargingStationRepository.GetQueryable()
                    .Where(c => c.Id == stationId)
                    .Include(c => c.ChargingPosts)
                    .FirstOrDefaultAsync();
                if (chargingStation == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Trạm sạc không tồn tại");

                if (status.ToString().Equals(chargingStation.Status))
                    return new ServiceResult(Const.FAIL_UPDATE_CODE, "Trạm sạc đã ở trạng thái được chọn rồi");

                if (status.Equals(ChargingStationUpdateStatus.Active) && chargingStation.OperatorId == null)
                    return new ServiceResult(Const.FAIL_UPDATE_CODE, "Trạm này chưa được phân công nhân viên nên không thể chọn trạng thái này");

                // Nếu trạng thái là Maintained hoặc InActive, tắt toàn bộ các trụ và cổng sạc của trạm này
                if (!status.Equals(ChargingStationUpdateStatus.Active))
                {
                    chargingStation.AvailableCarChargingPosts = 0;
                    chargingStation.AvailableCarConnectors = 0;
                    chargingStation.AvailableBikeChargingPosts = 0;
                    chargingStation.AvailableBikeConnectors = 0;

                    foreach (var chargingPost in chargingStation.ChargingPosts)
                    {
                        var connectors = await _unitOfWork.ConnectorRepository.GetQueryable()
                            .Where(c => !c.IsDeleted && c.ChargingPostId == chargingPost.Id && c.Status.Equals(ConnectorStatus.Available.ToString()))
                            .ToListAsync();
                        foreach (var connector in connectors)
                        {
                            if (connector.Status.Equals(ConnectorStatus.InUse.ToString()) || connector.Status.Equals(ConnectorStatus.Charging.ToString()))
                                return new ServiceResult(Const.FAIL_UPDATE_CODE, "Đang có trụ được sử dụng, không thể đổi trạng thái trạm được");
                            connector.Status = ConnectorUpdateStatus.OutOfService.ToString();
                            connector.UpdatedAt = DateTime.Now;
                        }
                        if (chargingPost.Status.Equals(ChargingPostStatus.Available.ToString()))
                        {
                            chargingPost.Status = ChargingPostUpdateStatus.InActive.ToString();
                            chargingPost.AvailableConnectors = 0;
                            chargingPost.UpdatedAt = DateTime.Now;
                        }
                    }
                }
                // Ngược lại thì bật lên
                else
                {
                    foreach (var chargingPost in chargingStation.ChargingPosts)
                    {
                        // Chuyển toàn bộ trạng thái các connector từ OutOfService sang Available
                        var connectors = await _unitOfWork.ConnectorRepository.GetQueryable()
                            .Where(c => !c.IsDeleted && c.ChargingPostId == chargingPost.Id && c.Status.Equals(ConnectorStatus.OutOfService.ToString()))
                            .ToListAsync();

                        // Nếu status trả về là bật lên mà status của trạm đang là maintained hay available thì sẽ không cập nhật
                        if (chargingPost.Status.Equals(ChargingPostStatus.InActive.ToString()))
                        {
                            foreach (var connector in connectors)
                            {
                                connector.Status = ConnectorUpdateStatus.Available.ToString();
                                connector.UpdatedAt = DateTime.Now;

                                chargingPost.AvailableConnectors += 1;
                                if (chargingPost.VehicleTypeSupported.Equals(VehicleTypeEnum.Car.ToString()))
                                    chargingStation.AvailableCarConnectors += 1;
                                else
                                    chargingStation.AvailableBikeConnectors += 1;
                            }

                            if (chargingPost.VehicleTypeSupported.Equals(VehicleTypeEnum.Car.ToString()))
                                chargingStation.AvailableCarChargingPosts += 1;
                            else chargingStation.AvailableBikeChargingPosts += 1;
                            chargingPost.Status = ChargingPostUpdateStatus.Available.ToString();
                            chargingPost.UpdatedAt = DateTime.Now;
                        }
                    }
                }

                chargingStation.Status = status.ToString();
                chargingStation.UpdatedAt = DateTime.Now;

                var result = await _unitOfWork.SaveChangesAsync();
                if (result > 0)
                {
                    var response = chargingStation.Adapt<ChargingStationViewGeneralDto>();
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

        public async Task<IServiceResult> Delete(Guid stationId)
        {
            try
            {
                var chargingStation = await _unitOfWork.ChargingStationRepository.GetQueryable()
                    .Where(c => c.Id == stationId)
                        .Include(c => c.OperatorNavigation)
                        .Include(c => c.ChargingPosts)
                            .ThenInclude(c => c.Connectors)
                    .FirstOrDefaultAsync();
                if (chargingStation == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Trạm sạc không tồn tại");

                if (!chargingStation.Status.Equals(ChargingStationStatus.Maintenance.ToString()))
                    return new ServiceResult(Const.FAIL_DELETE_CODE, "Trạm phải trong trạng thái bảo trì mới được phép xóa");

                
                foreach(var post in chargingStation.ChargingPosts)
                {
                    if (!post.Status.Equals(ChargingPostStatus.InActive.ToString()))
                        return new ServiceResult(Const.FAIL_DELETE_CODE, "Toàn bộ trụ phải tắt trước khi xóa trạm");
                    post.IsDeleted = true;
                    post.UpdatedAt = DateTime.Now;
                    foreach(var connector in post.Connectors)
                    {
                        connector.IsDeleted = true;
                        connector.UpdatedAt = DateTime.Now;
                    }
                }

                chargingStation.OperatorNavigation.Status = UserStatus.Active.ToString();
                chargingStation.OperatorId = null;
                chargingStation.IsDeleted = true;
                chargingStation.UpdatedAt = DateTime.Now;

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
