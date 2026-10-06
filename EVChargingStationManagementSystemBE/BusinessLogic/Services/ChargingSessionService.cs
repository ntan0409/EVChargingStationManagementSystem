using BusinessLogic.Base;
using BusinessLogic.IServices;
using Common;
using Common.DTOs.ChargingSessionDto;
using Common.Enum.ChargingSession;
using Common.Enum.Connector;
using Common.Helper;
using Infrastructure.IUnitOfWork;
using Infrastructure.Models;
using Mapster;
using Microsoft.EntityFrameworkCore;

namespace BusinessLogic.Services
{
    public class ChargingSessionService(IUnitOfWork unitOfWork) : IChargingSessionService
    {
        private readonly IUnitOfWork _unitOfWork = unitOfWork;

        public async Task<IServiceResult> GetList()
        {
            try
            {
                var chargingSession = await _unitOfWork.ChargingSessionRepository.GetQueryable()
                    .AsNoTracking()
                    //.Where(c => !c.IsDeleted && c.UserId == userId)
                    .Where(c => !c.IsDeleted)
                    //.ProjectToType<ChargingSessionViewListDto>()
                    .ToListAsync();
                if (chargingSession == null || chargingSession.Count == 0)
                    return new ServiceResult(
                        Const.WARNING_NO_DATA_CODE,
                        "Không tìm thấy phiên sạc nào");
                var response = chargingSession.Adapt<List<ChargingSessionViewListDto>>();
                return new ServiceResult(Const.SUCCESS_READ_CODE, Const.SUCCESS_READ_MSG, response);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }
        }

        public async Task<IServiceResult> GetById(Guid SessionId)
        {
            try
            {
                var chargingSession = await _unitOfWork.ChargingSessionRepository.GetQueryable()
                    .AsNoTracking()
                    .Where(v => !v.IsDeleted && v.Id == SessionId)
                    .ProjectToType<ChargingSessionViewDetailDto>()
                    .FirstOrDefaultAsync();
                if (chargingSession == null)
                    return new ServiceResult(
                        Const.WARNING_NO_DATA_CODE,
                        "Không tìm thấy phiên sạc nào"
                    );

                return new ServiceResult(Const.SUCCESS_READ_CODE, Const.SUCCESS_READ_MSG, chargingSession);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }
        }

        public async Task<IServiceResult> GetByConnector(Guid connectorId)
        {
            try
            {
                var chargingSession = await _unitOfWork.ChargingSessionRepository.GetQueryable()
                    .AsNoTracking()
                    .Where(v => !v.IsDeleted && v.ConnectorId == connectorId && v.Status.Equals(ChargingSessionStatus.Completed.ToString()))
                    .OrderByDescending(v => v.UpdatedAt)
                    .ProjectToType<ChargingSessionViewDetailDto>()
                    .FirstOrDefaultAsync();
                if (chargingSession == null)
                    return new ServiceResult(
                        Const.WARNING_NO_DATA_CODE,
                        "Không tìm thấy phiên sạc nào"
                    );

                return new ServiceResult(Const.SUCCESS_READ_CODE, Const.SUCCESS_READ_MSG, chargingSession);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }
        }

        public async Task<IServiceResult> Start(ChargingSessionStartDto dto)
        {
            try
            {
                var chargingSession = dto.Adapt<ChargingSession>();
                chargingSession.Id = Guid.NewGuid();
                chargingSession.CreatedAt = DateTime.Now;
                chargingSession.UpdatedAt = DateTime.Now;
                chargingSession.StartTime = DateTime.Now;
                chargingSession.Status = ChargingSessionStatus.Charging.ToString();

                if (dto.Phone.HasValue())
                {
                    var user = await _unitOfWork.UserAccountRepository.GetQueryable()
                        .AsNoTracking()
                        .Where(u => !u.IsDeleted && u.PhoneNumber == dto.Phone)
                        .Include(u => u.EVDriverProfile)
                        .FirstOrDefaultAsync();
                    if (user == null)
                        return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy tài khoản người dùng, vui lòng xem lại số điện thoại");
                    if (user?.EVDriverProfile == null)
                        return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Số điện thoại này không thuộc tài khoản tài xế");

                    chargingSession.UserId = user.Id;
                    chargingSession.DriverId = user.EVDriverProfile.Id;

                    if (dto.VehicleModelId == Guid.Empty)
                        return new ServiceResult(Const.FAIL_CREATE_CODE, "Vui lòng chọn xe trong profile của bạn");
                }

                var connector = await _unitOfWork.ConnectorRepository.GetQueryable()
                    .Where(p => !p.IsDeleted && p.Id == dto.ConnectorId)
                    .Include(v => v.ChargingPost)
                        .ThenInclude(c => c.ChargingStationNavigation)
                    .FirstOrDefaultAsync();

                if (connector == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy cổng sạc được chọn");

                if (connector.ChargingPost == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy trụ sạc được chọn");

                if (connector.ChargingPost.ChargingStationNavigation == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy trạm sạc đã chọn");

                // Nếu cổng sạc là bất cứ trạng thái nào khác ngoài "InUse - (đang được sử dụng)" thì trả lỗi 
                if (!connector.Status.Equals(ConnectorStatus.InUse.ToString()))
                    return new ServiceResult(Const.FAIL_CREATE_CODE, "Cổng sạc này không khả dụng hiện tại hoặc chưa được cắm vào xe");
                // Sau khi đã chạy api dừng sạc (stop) thì không cho phép chạy api này để ngăn người dùng chưa thanh toán
                if (connector.IsLocked)
                    return new ServiceResult(Const.FAIL_CREATE_CODE, "Bạn chưa thanh toán phiên sạc trước, vui lòng thanh toán phiên sạc trước");

                chargingSession.ChargingPostId = connector.ChargingPostId;
                connector.Status = ConnectorStatus.Charging.ToString();
                connector.IsLocked = true;
                connector.ChargingPost.UpdatedAt = DateTime.Now;

                connector.ChargingPost.ChargingStationNavigation.UpdatedAt = DateTime.Now;

                await _unitOfWork.ChargingSessionRepository.CreateAsync(chargingSession);
                var result = await _unitOfWork.SaveChangesAsync();
                if (result > 0)
                {
                    var response = chargingSession.Adapt<ChargingSessionViewDetailDto>();
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

        public async Task<IServiceResult> Stop(ChargingSessionStopDto dto, Guid sessionId)
        {
            try
            {
                var session = await _unitOfWork.ChargingSessionRepository.GetQueryable()
                    .Where(s => !s.IsDeleted && s.Id == sessionId)
                    .FirstOrDefaultAsync();
                if (session == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy phiên sạc nào");

                if (!session.Status.Equals(ChargingSessionStatus.Charging.ToString()))
                    return new ServiceResult(Const.FAIL_UPDATE_CODE, "Phiên sạc này đã được dừng lại rồi");

                var connector = await _unitOfWork.ConnectorRepository.GetQueryable()
                    .Where(p => !p.IsDeleted && p.Id == session.ConnectorId)
                    .FirstOrDefaultAsync();

                if (connector == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy cổng sạc được chọn");

                dto.Adapt(session);

                var t_e = await _unitOfWork.SystemConfigurationRepository.GetQueryable()
                .AsNoTracking()
                .Where(c => !c.IsDeleted && c.Name == "PRICE_PER_kWH")
                .FirstOrDefaultAsync();

                decimal pricePerKWh = 1000; //vnd
                if (t_e != null && _unitOfWork.SystemConfigurationRepository.Validate(t_e))
                    pricePerKWh = t_e.MinValue ?? 1000;

                session.Cost = (decimal)dto.EnergyDeliveredKWh * pricePerKWh;
                session.Status = ChargingSessionStatus.Completed.ToString();
                session.UpdatedAt = DateTime.Now;
                session.EndTime = DateTime.Now;

                connector.Status = ConnectorStatus.InUse.ToString();
                connector.UpdatedAt = DateTime.Now;

                var result = await _unitOfWork.SaveChangesAsync();
                if (result > 0)
                {
                    var response = session.Adapt<ChargingSessionViewDetailDto>();
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
