using BusinessLogic.Base;
using BusinessLogic.IServices;
using Common;
using Common.DTOs.ChargingPostDto;
using Common.Enum.ChargingPost;
using Common.Enum.ChargingStation;
using Common.Enum.Connector;
using Common.Enum.VehicleModel;
using Infrastructure.IUnitOfWork;
using Infrastructure.Models;
using Mapster;
using Microsoft.EntityFrameworkCore;

namespace BusinessLogic.Services
{
    public class ChargingPostService(IUnitOfWork unitOfWork) : IChargingPostService
    {
        private readonly IUnitOfWork _unitOfWork = unitOfWork;

        public async Task<IServiceResult> Create(ChargingPostCreateDto dto)
        {
            try
            {
                var connectorLimit = await _unitOfWork.SystemConfigurationRepository.GetQueryable()
                    .AsNoTracking()
                    .Where(c => !c.IsDeleted && c.Name == "CONNECTOR_LIMIT")
                    .FirstOrDefaultAsync();

                decimal connectorCount = 2;
                if (connectorLimit != null && _unitOfWork.SystemConfigurationRepository.Validate(connectorLimit))
                    connectorCount = connectorLimit.MinValue ?? 2;

                if (dto.TotalConnectors > connectorCount)
                    return new ServiceResult(Const.FAIL_CREATE_CODE,
                        $"Số cổng sạc của trụ này đã vượt mức quy định trong hệ thống là {connectorCount} cổng");

                var chargingPost = dto.Adapt<ChargingPost>();
                chargingPost.Id = Guid.NewGuid();
                chargingPost.Status = ChargingPostUpdateStatus.InActive.ToString();
                chargingPost.CreatedAt = DateTime.Now;
                chargingPost.UpdatedAt = DateTime.Now;

                await _unitOfWork.ChargingPostRepository.CreateAsync(chargingPost);

                var chargingStation = await _unitOfWork.ChargingStationRepository.GetQueryable()
                    .Where(c => c.Id == chargingPost.StationId)
                    .FirstOrDefaultAsync();
                if (chargingStation == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy trạm sạc đã chọn");

                if (chargingPost.VehicleTypeSupported.Equals("Car"))
                {
                    chargingStation.TotalCarChargingPosts += 1;
                    chargingStation.TotalCarChargingConnectors += chargingPost.TotalConnectors;
                }
                else
                {
                    chargingStation.TotalBikeChargingPosts += 1;
                    chargingStation.TotalBikeConnectors += chargingPost.TotalConnectors;
                }

                // Bulk create connectors
                for (int i = 0; i < chargingPost.TotalConnectors; i++)
                {
                    var connector = new Connector
                    {
                        Id = Guid.NewGuid(),
                        ConnectorName = $"C{i + 1}",
                        Status = "OutOfService",
                        ChargingPostId = chargingPost.Id,
                        CreatedAt = DateTime.Now,
                        UpdatedAt = DateTime.Now
                    };
                    await _unitOfWork.ConnectorRepository.CreateAsync(connector);
                }

                var result = await _unitOfWork.SaveChangesAsync();
                if (result > 0)
                {
                    var response = chargingPost.Adapt<ChargingPostViewListDto>();
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

        public async Task<IServiceResult> Update(ChargingPostUpdateDto dto, Guid postId)
        {
            try
            {
                var chargingPost = await _unitOfWork.ChargingPostRepository.GetQueryable()
                    .Where(v => !v.IsDeleted && v.Id == postId)
                    .FirstOrDefaultAsync();

                if (chargingPost == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Trụ sạc không tồn tại");

                if (!chargingPost.Status.Equals("Maintained"))
                    return new ServiceResult(Const.FAIL_UPDATE_CODE, "Trụ sạc phải có trạng thái là bảo trì mới được phép cập nhật");

                chargingPost = dto.Adapt(chargingPost);
                chargingPost.UpdatedAt = DateTime.Now;

                var result = await _unitOfWork.SaveChangesAsync();
                if (result > 0)
                {
                    var response = chargingPost.Adapt<ChargingPostViewListDto>();
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

        public async Task<IServiceResult> Delete(Guid postId)
        {
            try
            {
                var chargingPost = await _unitOfWork.ChargingPostRepository.GetQueryable()
                    .Where(v => !v.IsDeleted && v.Id == postId)
                    .Include( c => c.ChargingStationNavigation)
                    .FirstOrDefaultAsync();

                if (chargingPost == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Trụ sạc không tồn tại");

                if (!chargingPost.Status.Equals("Maintained"))
                    return new ServiceResult(Const.FAIL_DELETE_CODE, "Trụ sạc phải có trạng thái là bảo trì mới được phép xóa");

                chargingPost.IsDeleted = true;
                chargingPost.UpdatedAt = DateTime.Now;


                if (chargingPost.ChargingStationNavigation == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy trạm sạc đã chọn");

                if (chargingPost.VehicleTypeSupported.Equals("Car"))
                {
                    chargingPost.ChargingStationNavigation.TotalCarChargingPosts -= 1;
                    chargingPost.ChargingStationNavigation.TotalCarChargingConnectors -= chargingPost.TotalConnectors;
                }
                else
                {
                    chargingPost.ChargingStationNavigation.TotalBikeChargingPosts -= 1;
                    chargingPost.ChargingStationNavigation.TotalBikeConnectors -= chargingPost.TotalConnectors;
                }

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

        public async Task<IServiceResult> GetById(Guid postId)
        {
            try
            {
                var chargingPost = await _unitOfWork.ChargingPostRepository.GetQueryable()
                    .AsNoTracking()
                    .Where(v => !v.IsDeleted && v.Id == postId)
                    .Include(p => p.Connectors.Where(c => !c.IsDeleted).OrderByDescending(c => c.CreatedAt))
                    .OrderByDescending(v => v.CreatedAt)
                    .ProjectToType<ChargingPostViewDetailDto>()
                    .FirstOrDefaultAsync();

                if (chargingPost == null)
                    return new ServiceResult(
                        Const.WARNING_NO_DATA_CODE,
                        "Không tìm thấy trụ sạc nào"
                    );

                return new ServiceResult(Const.SUCCESS_READ_CODE, Const.SUCCESS_READ_MSG, chargingPost);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }
        }

        public async Task<IServiceResult> GetList()
        {
            try
            {
                var chargingPost = await _unitOfWork.ChargingPostRepository.GetQueryable()
                    .AsNoTracking()
                    .Where(v => !v.IsDeleted)
                    .OrderByDescending(v => v.CreatedAt)
                    .ProjectToType<ChargingPostViewListDto>()
                    .ToListAsync();

                if (chargingPost == null || chargingPost.Count == 0)
                    return new ServiceResult(
                        Const.WARNING_NO_DATA_CODE,
                        "Không tìm thấy trụ sạc nào");

                return new ServiceResult(Const.SUCCESS_READ_CODE, Const.SUCCESS_READ_MSG, chargingPost);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }
        }

        public async Task<IServiceResult> UpdateStatus(ChargingPostUpdateStatus status, Guid postId)
        {
            try
            {
                var chargingPost = await _unitOfWork.ChargingPostRepository.GetQueryable()
                    .Where(v => !v.IsDeleted && v.Id == postId)
                    .Include(c => c.ChargingStationNavigation)
                    .Include(c => c.Connectors)
                    .FirstOrDefaultAsync();

                if (chargingPost == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Trụ sạc không tồn tại");


                if (chargingPost.ChargingStationNavigation == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy trạm sạc đã chọn");

                if (!chargingPost.ChargingStationNavigation.Status.Equals(ChargingStationStatus.Active.ToString()) && status.Equals(ChargingPostUpdateStatus.Available))
                    return new ServiceResult(Const.FAIL_UPDATE_CODE, "Trạm đang dừng hoạt động, vui lòng kích hoạt trạng thái trạm để có thể thay đổi trạng thái trụ sạc");

                if (status.ToString().Equals(chargingPost.Status))
                    return new ServiceResult(Const.FAIL_UPDATE_CODE, "Trụ sạc đã ở trạng thái được chọn rồi");

                // Nếu chuyển từ bất kỳ trạng thái nào
                // sang Available thì tăng số trụ sạc khả dụng lên 1 và reset số cổng kết nối khả dụng
                if (!chargingPost.Status.Equals(ChargingPostUpdateStatus.Available.ToString()) && status.Equals(ChargingPostUpdateStatus.Available))
                {
                    chargingPost.AvailableConnectors = chargingPost.TotalConnectors;
                    if (chargingPost.VehicleTypeSupported.Equals(VehicleTypeEnum.Car.ToString()))
                    {
                        chargingPost.ChargingStationNavigation.AvailableCarChargingPosts += 1;
                        chargingPost.ChargingStationNavigation.AvailableCarConnectors += chargingPost.TotalConnectors;
                    }
                    else
                    {
                        chargingPost.ChargingStationNavigation.AvailableBikeChargingPosts += 1;
                        chargingPost.ChargingStationNavigation.AvailableBikeConnectors += chargingPost.TotalConnectors;
                    }
                    var connectors = chargingPost.Connectors.ToList().
                        Where(c => !c.IsDeleted && c.ChargingPostId == chargingPost.Id && c.Status.Equals(ConnectorStatus.OutOfService.ToString()));
                    foreach (var connector in connectors)
                    {
                        connector.Status = ConnectorStatus.Available.ToString();
                        connector.UpdatedAt = DateTime.Now;
                    }
                }
                else if (chargingPost.Status.Equals(ChargingPostStatus.Available.ToString()) && !status.Equals(ChargingPostStatus.Available))
                {
                    if (chargingPost.VehicleTypeSupported.Equals(VehicleTypeEnum.Car.ToString()))
                    {
                        chargingPost.ChargingStationNavigation.AvailableCarChargingPosts -= 1;
                        chargingPost.ChargingStationNavigation.AvailableCarConnectors -= chargingPost.AvailableConnectors;
                    }
                    else
                    {
                        chargingPost.ChargingStationNavigation.AvailableBikeChargingPosts -= 1;
                        chargingPost.ChargingStationNavigation.AvailableBikeConnectors -= chargingPost.AvailableConnectors;
                    }

                    // Chuyển toàn bộ trạng thái các connector từ Available sang OutOfService
                    //var connectors = await _unitOfWork.ConnectorRepository.GetAllAsync(
                    //    predicate: c => !c.IsDeleted && c.ChargingPostId == chargingPost.Id && c.Status.Equals(ChargingPostStatus.Available.ToString())
                    //    , asNoTracking: false);
                    var connectors = chargingPost.Connectors.ToList().
                        Where(c => !c.IsDeleted && c.ChargingPostId == chargingPost.Id && c.Status.Equals(ConnectorStatus.Available.ToString()));
                    foreach (var connector in connectors)
                    {
                        connector.Status = ConnectorStatus.OutOfService.ToString();
                        connector.UpdatedAt = DateTime.Now;
                    }
                }
                else chargingPost.AvailableConnectors = 0;

                chargingPost.Status = status.ToString();
                chargingPost.UpdatedAt = DateTime.Now;

                var result = await _unitOfWork.SaveChangesAsync();
                if (result > 0)
                {
                    var response = chargingPost.Adapt<ChargingPostViewListDto>();
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
    }
}
