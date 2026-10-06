using BusinessLogic.Base;
using BusinessLogic.IServices;
using Common;
using Common.DTOs.ConnectorDto;
using Common.Enum.ChargingPost;
using Common.Enum.Connector;
using Common.Enum.VehicleModel;
using Infrastructure.IUnitOfWork;
using Infrastructure.Models;
using Mapster;
using Microsoft.EntityFrameworkCore;

namespace BusinessLogic.Services
{
    public class ConnectorService(IUnitOfWork unitOfWork) : IConnectorService
    {
        private readonly IUnitOfWork _unitOfWork = unitOfWork;

        public async Task<IServiceResult> GetList(Guid chargingPostId)
        {

            try
            {
                var connectors = await _unitOfWork.ConnectorRepository.GetQueryable()
                    .AsNoTracking()
                    .Where(v => !v.IsDeleted && v.ChargingPostId == chargingPostId)
                    .OrderByDescending(v => v.CreatedAt)
                    .ProjectToType<ConnectorViewListDto>()
                    .ToListAsync();
                if (connectors == null || connectors.Count == 0)
                    return new ServiceResult(
                        Const.WARNING_NO_DATA_CODE,
                        "Không tìm thấy cổng kết nối nào");

                return new ServiceResult(Const.SUCCESS_READ_CODE, Const.SUCCESS_READ_MSG, connectors);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }
        }

        public async Task<IServiceResult> GetById(Guid ConnectorId)
        {

            try
            {
                var connector = await _unitOfWork.ConnectorRepository.GetQueryable()
                    .AsNoTracking()
                    .Where(v => !v.IsDeleted && v.Id == ConnectorId)
                    .ProjectToType<ConnectorViewListDto>()
                    .FirstOrDefaultAsync();
                if (connector == null)
                    return new ServiceResult(
                        Const.WARNING_NO_DATA_CODE,
                        "Không tìm thấy cổng kết nối nào"
                    );
                return new ServiceResult(Const.SUCCESS_READ_CODE, Const.SUCCESS_READ_MSG, connector);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }
        }

        public async Task<IServiceResult> Create(ConnectorCreateDto dto)
        {
            try
            {
                var connector = dto.Adapt<Connector>();
                connector.Id = Guid.NewGuid();
                connector.Status = "OutOfService";
                connector.CreatedAt = DateTime.Now;
                connector.UpdatedAt = DateTime.Now;

                var chargingPost = await _unitOfWork.ChargingPostRepository.GetQueryable()
                    .Where(cp => !cp.IsDeleted && cp.Id == dto.ChargingPostId)
                    .FirstOrDefaultAsync();

                if (chargingPost == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Trụ sạc không tồn tại");

                var connectorLimit = await _unitOfWork.SystemConfigurationRepository.GetQueryable()
                    .AsNoTracking()
                    .Where(c => !c.IsDeleted && c.Name == "CONNECTOR_LIMIT")
                    .FirstOrDefaultAsync();

                decimal connectorCount = 2;
                if (connectorLimit != null && _unitOfWork.SystemConfigurationRepository.Validate(connectorLimit))
                    connectorCount = connectorLimit.MinValue ?? 2;

                if (chargingPost.TotalConnectors == connectorCount)
                    return new ServiceResult(Const.FAIL_CREATE_CODE,
                        $"Số cổng sạc của trụ này đã vượt mức quy định trong hệ thống là {connectorCount} cổng");

                var chargingStation = await _unitOfWork.ChargingStationRepository.GetQueryable()
                    .Where(cp => !cp.IsDeleted && cp.Id == chargingPost.StationId)
                    .FirstOrDefaultAsync();

                if (chargingStation == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Trạm sạc không tồn tại");

                chargingPost.TotalConnectors += 1;

                if (chargingPost.VehicleTypeSupported.Equals("Car"))
                    chargingStation.TotalCarChargingConnectors += 1;
                else
                    chargingStation.TotalBikeConnectors += 1;

                chargingPost.UpdatedAt = DateTime.Now;
                chargingStation.UpdatedAt = DateTime.Now;
                await _unitOfWork.ConnectorRepository.CreateAsync(connector);
                var result = await _unitOfWork.SaveChangesAsync();
                if (result > 0)
                {
                    var response = connector.Adapt<ConnectorViewListDto>();
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

        public async Task<IServiceResult> Update(ConnectorUpdateDto dto, Guid connectorId)
        {
            try
            {
                var connector = await _unitOfWork.ConnectorRepository.GetQueryable()
                    .Where(v => !v.IsDeleted && v.Id == connectorId)
                    .Include (v => v.ChargingPost)
                    .FirstOrDefaultAsync();
                if (connector == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Cổng kết nối không tồn tại");

                //var chargingPost = await _unitOfWork.ChargingPostRepository.GetQueryable()
                //    .Where(cp => !cp.IsDeleted && cp.Id == dto.ChargingPostId).FirstOrDefaultAsync();
                if (connector.ChargingPost == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Trụ sạc không tồn tại");

                if (!connector.ChargingPost.Status.Equals("Maintained"))
                    return new ServiceResult(Const.FAIL_UPDATE_CODE, "Trụ sạc phải có trạng thái là bảo trì mới được phép cập nhật cổng kết nối");

                connector = dto.Adapt(connector);
                connector.UpdatedAt = DateTime.Now;

                var result = await _unitOfWork.SaveChangesAsync();
                if (result > 0)
                {
                    var response = connector.Adapt<ConnectorViewListDto>();
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

        public async Task<IServiceResult> UpdateStatus(ConnectorUpdateStatus status, Guid connectorId)
        {
            try
            {
                var connector = await _unitOfWork.ConnectorRepository.GetQueryable()
                    .Where(v => !v.IsDeleted && v.Id == connectorId)
                    .Include(v => v.ChargingPost)
                        .ThenInclude(c => c.ChargingStationNavigation)
                    .FirstOrDefaultAsync();
                if (connector == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Cổng kết nối không tồn tại");

                if (connector.ChargingPost == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Trụ sạc không tồn tại");

                if (status.ToString().Equals(connector.Status))
                    return new ServiceResult(Const.FAIL_UPDATE_CODE, "Cổng sạc đã ở trạng thái được chọn rồi");

                if (connector.ChargingPost.ChargingStationNavigation == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Trạm sạc không tồn tại");

                if (!connector.Status.Equals(ConnectorStatus.Available.ToString()) && status.Equals(ConnectorStatus.Available))
                {
                    connector.ChargingPost.AvailableConnectors += 1;
                    if (connector.ChargingPost.VehicleTypeSupported.Equals(VehicleTypeEnum.Car.ToString()))
                        connector.ChargingPost.ChargingStationNavigation.AvailableCarConnectors += 1;
                    else
                        connector.ChargingPost.ChargingStationNavigation.AvailableBikeConnectors += 1;
                }
                else if (connector.Status.Equals(ConnectorStatus.Available.ToString()) && !status.Equals(ChargingPostStatus.Available))
                {
                    connector.ChargingPost.AvailableConnectors -= 1;
                    if (connector.ChargingPost.VehicleTypeSupported.Equals(VehicleTypeEnum.Car.ToString()))
                        connector.ChargingPost.ChargingStationNavigation.AvailableCarConnectors -= 1;
                    else
                        connector.ChargingPost.ChargingStationNavigation.AvailableBikeConnectors -= 1;
                }

                if (connector.ChargingPost.AvailableConnectors == 0)
                {
                    if (connector.ChargingPost.VehicleTypeSupported.Equals(VehicleTypeEnum.Car.ToString()))
                        connector.ChargingPost.ChargingStationNavigation.AvailableCarChargingPosts -= 1;
                    else
                        connector.ChargingPost.ChargingStationNavigation.AvailableBikeChargingPosts -= 1;
                    connector.ChargingPost.Status = ChargingPostStatus.InActive.ToString();
                }

                connector.ChargingPost.ChargingStationNavigation.UpdatedAt = DateTime.Now;
                connector.ChargingPost.UpdatedAt = DateTime.Now;
                connector.Status = status.ToString();
                connector.UpdatedAt = DateTime.Now;

                var result = await _unitOfWork.SaveChangesAsync();
                if (result > 0)
                {
                    var response = connector.Adapt<ConnectorViewListDto>();
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

        public async Task<IServiceResult> UpdateConnectorCount(bool toggle, Guid connectorId)
        {
            try
            {
                var connector = await _unitOfWork.ConnectorRepository.GetQueryable()
                    .Where(v => !v.IsDeleted && v.Id == connectorId)
                    .Include(v => v.ChargingPost)
                        .ThenInclude(c => c.ChargingStationNavigation)
                    .FirstOrDefaultAsync();

                if (connector == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Cổng kết nối không tồn tại");

                var post = connector.ChargingPost;
                var station = post?.ChargingStationNavigation;

                if (post == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Trụ sạc không tồn tại");

                if (station == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy trạm sạc");

                var status = Enum.Parse<ConnectorStatus>(connector.Status);


                // ================== ❌ Không cho toggle ==================

                if (status == ConnectorStatus.Charging)
                    return new ServiceResult(Const.FAIL_UPDATE_CODE, "Cổng đang sạc, không thể thay đổi trạng thái.");

                if (connector.IsLocked)
                    return new ServiceResult(Const.FAIL_UPDATE_CODE, "Cổng đang bị khóa. Hãy thanh toán để mở khóa.");

                if (status == ConnectorStatus.Reserved && toggle == false)
                    return new ServiceResult(Const.FAIL_UPDATE_CODE, "Cổng đang được đặt trước, không thể cắm vào.");



                // ================== ❗ Cho phép override trong các trạng thái hư hỏng ==================
                bool allowOverride =
                    status == ConnectorStatus.OutOfService ||
                    status == ConnectorStatus.Faulted ||
                    status == ConnectorStatus.Unknown ||
                    status == ConnectorStatus.Preparing;



                // ================== TRUE = RÚT | FALSE = CẮM ==================
                bool isUnplug = toggle;      // true = rút
                bool isPlugIn = !toggle;     // false = cắm


                // ========== ❌ Kiểm tra logic nếu KHÔNG thuộc nhóm override ==========
                if (!allowOverride)
                {
                    if (isUnplug && status == ConnectorStatus.Available)
                        return new ServiceResult(Const.FAIL_UPDATE_CODE, "Cổng này đã được rút ra rồi.");

                    if (isPlugIn && status == ConnectorStatus.InUse)
                        return new ServiceResult(Const.FAIL_UPDATE_CODE, "Cổng này đã được cắm vào rồi.");
                }



                // ================== ✔ Cập nhật trạng thái ==================

                if (isUnplug) // TRUE = RÚT
                {
                    connector.Status = ConnectorStatus.Available.ToString();

                    post.AvailableConnectors += 1;

                    if (post.VehicleTypeSupported == "Car")
                        station.AvailableCarConnectors += 1;
                    else
                        station.AvailableBikeConnectors += 1;
                }
                else // FALSE = CẮM
                {
                    connector.Status = ConnectorStatus.InUse.ToString();

                    post.AvailableConnectors = Math.Max(0, post.AvailableConnectors - 1);

                    if (post.VehicleTypeSupported == "Car")
                        station.AvailableCarConnectors = Math.Max(0, station.AvailableCarConnectors - 1);
                    else
                        station.AvailableBikeConnectors = Math.Max(0, station.AvailableBikeConnectors - 1);
                }



                // ================== ✔ Update trạng thái của Post ==================
                if (post.AvailableConnectors <= 0)
                {
                    post.AvailableConnectors = 0;
                    post.Status = ChargingPostStatus.Busy.ToString();

                    if (post.VehicleTypeSupported == "Car")
                        station.AvailableCarChargingPosts = Math.Max(0, station.AvailableCarChargingPosts - 1);
                    else
                        station.AvailableBikeChargingPosts = Math.Max(0, station.AvailableBikeChargingPosts - 1);
                }
                else
                {
                    post.Status = ChargingPostStatus.Available.ToString();

                    if (post.VehicleTypeSupported == "Car")
                        station.AvailableCarChargingPosts += 1;
                    else
                        station.AvailableBikeChargingPosts += 1;
                }


                connector.UpdatedAt = DateTime.Now;
                post.UpdatedAt = DateTime.Now;

                // Save
                var result = await _unitOfWork.SaveChangesAsync();
                if (result > 0)
                {
                    var response = connector.Adapt<ConnectorViewListDto>();
                    return new ServiceResult(Const.SUCCESS_UPDATE_CODE, Const.SUCCESS_UPDATE_MSG, response);
                }

                return new ServiceResult(Const.FAIL_UPDATE_CODE, Const.FAIL_UPDATE_MSG);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }
        }



        public async Task<IServiceResult> Delete(Guid connectorId)
        {
            try
            {
                var connector = await _unitOfWork.ConnectorRepository.GetQueryable()
                    .Where(v => !v.IsDeleted && v.Id == connectorId)
                    .Include(v => v.ChargingPost)
                        .ThenInclude(c => c.ChargingStationNavigation)
                    .FirstOrDefaultAsync();
                if (connector == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Cổng kết nối không tồn tại");

                //var chargingPost = await _unitOfWork.ChargingPostRepository.GetByIdAsync(
                //    predicate: cp => !cp.IsDeleted && cp.Id == connector.ChargingPostId,
                //    asNoTracking: false
                //    );
                if (connector.ChargingPost == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Trụ sạc không tồn tại");

                if (!connector.ChargingPost.Status.Equals("Maintained"))
                    return new ServiceResult(Const.FAIL_UPDATE_CODE, "Trụ sạc phải có trạng thái là bảo trì mới được phép cập nhật cổng kết nối");

                //var chargingStation = await _unitOfWork.ChargingStationRepository.GetByIdAsync(
                //    predicate: cp => !cp.IsDeleted && cp.Id == connector.ChargingPost.StationId,
                //    asNoTracking: false
                //    );

                if (connector.ChargingPost.ChargingStationNavigation == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Trạm sạc không tồn tại");

                connector.ChargingPost.TotalConnectors -= 1;

                if (connector.ChargingPost.VehicleTypeSupported.Equals("Car"))
                    connector.ChargingPost.ChargingStationNavigation.TotalCarChargingConnectors -= 1;
                else
                    connector.ChargingPost.ChargingStationNavigation.TotalBikeConnectors -= 1;

                connector.ChargingPost.UpdatedAt = DateTime.Now;
                connector.ChargingPost.ChargingStationNavigation.UpdatedAt = DateTime.Now;

                connector.IsDeleted = true;
                connector.UpdatedAt = DateTime.Now;

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
