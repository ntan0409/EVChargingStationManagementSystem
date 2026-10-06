using BusinessLogic.Base;
using BusinessLogic.IServices;
using Common;
using Common.DTOs.VoucherDto;
using Infrastructure.IUnitOfWork;
using Infrastructure.Models;
using Mapster;
using Microsoft.EntityFrameworkCore;

namespace BusinessLogic.Services
{
    public class VoucherService(IUnitOfWork unitOfWork) : IVoucherService
    {
        private readonly IUnitOfWork _unitOfWork = unitOfWork;

        // 1) GET AVAILABLE VOUCHERS
        public async Task<IServiceResult> GetAvailableVouchers()
        {
            try
            {
                var now = DateTime.Now;

                var vouchers = await _unitOfWork.VoucherRepository.GetQueryable()
                    .AsNoTracking()
                    .Where(v => v.IsActive &&
                                v.ValidFrom <= now &&
                                v.ValidTo >= now)
                    .OrderByDescending(v => v.ValidFrom)
                    .ProjectToType<VoucherDto>()
                    .ToListAsync();

                if (vouchers.Count == 0)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy voucher nào còn hiệu lực");

                return new ServiceResult(Const.SUCCESS_READ_CODE, "Lấy danh sách voucher thành công", vouchers);
            }
            catch (Exception ex)
            {

                return new ServiceResult(Const.ERROR_EXCEPTION, "Đã xảy ra lỗi: " + ex.Message);
            }
        }


        // 2) CREATE VOUCHER
        public async Task<IServiceResult> CreateVoucher(VoucherCreateDto dto)
        {
            try
            {
                var voucher = dto.Adapt<Voucher>();
                voucher.Id = Guid.NewGuid();
                voucher.IsActive = true;

                await _unitOfWork.VoucherRepository.CreateAsync(voucher);
                await _unitOfWork.SaveChangesAsync();

                return new ServiceResult(Const.SUCCESS_CREATE_CODE, "Tạo voucher thành công", voucher.Adapt<VoucherDto>());
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, "Đã xảy ra lỗi: " + ex.Message);
            }
        }


        // 3) UPDATE VOUCHER
        public async Task<IServiceResult> UpdateVoucher(VoucherUpdateDto dto, Guid voucherId)
        {
            try
            {
                var voucher = await _unitOfWork.VoucherRepository
                    .GetQueryable()
                    .FirstOrDefaultAsync(v => v.Id == voucherId);

                if (voucher == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Voucher không tồn tại");

                dto.Adapt(voucher);
                voucher.Id = voucherId;

                await _unitOfWork.SaveChangesAsync();

                return new ServiceResult(Const.SUCCESS_UPDATE_CODE, "Cập nhật voucher thành công", voucher.Adapt<VoucherDto>());
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, "Đã xảy ra lỗi: " + ex.Message);
            }
        }

        // 4) REDEEM VOUCHER
        public async Task<IServiceResult> RedeemVoucher(Guid evDriverId, Guid voucherId)
        {
            try
            {
                var now = DateTime.Now;

                var driver = await _unitOfWork.EVDriverRepository.GetQueryable()
                    .FirstOrDefaultAsync(d => d.AccountId == evDriverId && !d.IsDeleted);

                var voucher = await _unitOfWork.VoucherRepository.GetQueryable()
                    .FirstOrDefaultAsync(v => v.Id == voucherId && v.IsActive);

                if (driver == null || voucher == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy user hoặc voucher");

                if (now < voucher.ValidFrom || now > voucher.ValidTo)
                    return new ServiceResult(Const.FAIL_CREATE_CODE, "Voucher đã hết hạn hoặc chưa đến thời gian sử dụng");

                if (driver.Point < voucher.RequiredPoints)
                    return new ServiceResult(Const.FAIL_CREATE_CODE, "Điểm thưởng không đủ để đổi voucher");

                bool alreadyRedeemed = await _unitOfWork.UserVoucherRepository.GetQueryable()
                    .AnyAsync(uv => uv.EVDriverId == evDriverId && uv.VoucherId == voucherId && uv.Status != "Expired");

                if (alreadyRedeemed)
                    return new ServiceResult(Const.FAIL_CREATE_CODE, "Bạn đã đổi voucher này rồi");

                driver.Point -= voucher.RequiredPoints;
                driver.UpdatedAt = now;

                var userVoucher = new UserVoucher
                {
                    Id = Guid.NewGuid(),
                    EVDriverId = driver.Id,
                    VoucherId = voucherId,
                    AssignedDate = now,
                    RedeemDate = now,
                    ExpiryDate = voucher.ValidTo,
                    Status = "Redeemed",
                    CreatedAt = now,
                    UpdatedAt = now
                };

                await _unitOfWork.UserVoucherRepository.CreateAsync(userVoucher);
                await _unitOfWork.SaveChangesAsync();

                return new ServiceResult(Const.SUCCESS_CREATE_CODE, "Đổi voucher thành công", userVoucher.Adapt<UserVoucherDto>());
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, "Đã xảy ra lỗi: " + ex.Message);
            }
        }

        // 5) USE VOUCHER
     
        public async Task<IServiceResult> UseVoucher(Guid userVoucherId, Guid sessionId)
        {
            try
            {
                // 1️ Lấy thông tin voucher
                var userVoucher = await _unitOfWork.UserVoucherRepository.GetQueryable()
                    .Include(uv => uv.Voucher)
                    .FirstOrDefaultAsync(uv => uv.Id == userVoucherId);

                if (userVoucher == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Voucher không tồn tại");

                if (userVoucher.Status != "Redeemed")
                    return new ServiceResult(Const.FAIL_UPDATE_CODE, "Voucher chưa được redeem hoặc đã hết hạn");

                // 2️ Lấy thông tin phiên sạc
                var session = await _unitOfWork.ChargingSessionRepository.GetQueryable()
                    .FirstOrDefaultAsync(s => s.Id == sessionId);

                if (session == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy phiên sạc");

                // 3️ Kiểm tra xem session đã có voucher nào chưa
                var existingVoucher = await _unitOfWork.UserVoucherRepository.GetQueryable()
                    .FirstOrDefaultAsync(uv => uv.SessionId == sessionId && uv.Status == "Used");

                if (existingVoucher != null)
                {
                    //  Nếu đã có voucher thì gỡ ra trước khi gắn voucher mới
                    existingVoucher.Status = "Redeemed"; // hoặc "Unused" nếu bạn có trạng thái này
                    existingVoucher.SessionId = null;
                    existingVoucher.UsedDate = null;
                }

                // 4️ Gắn voucher mới vào session
                userVoucher.UsedDate = DateTime.Now;
                userVoucher.SessionId = sessionId;
                userVoucher.Status = "Used";

                // 5️ Áp dụng giảm giá
                if (userVoucher.Voucher != null)
                {
                    if (userVoucher.Voucher.VoucherType == "Discount")
                    {
                        var discount = session.Cost * (userVoucher.Voucher.Value / 100);
                        session.Cost -= discount;
                    }
                    else if (userVoucher.Voucher.VoucherType == "Amount")
                    {
                        session.Cost -= userVoucher.Voucher.Value;
                    }

                    if (session.Cost < 0) session.Cost = 0;
                }

                // 6️ Lưu thay đổi
                await _unitOfWork.SaveChangesAsync();

                return new ServiceResult(Const.SUCCESS_UPDATE_CODE, "Áp dụng voucher thành công", userVoucher.Adapt<UserVoucherDto>());
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, "Đã xảy ra lỗi: " + ex.Message);
            }
        }


        // 6) EXPIRE A SINGLE USER VOUCHER
        public async Task<IServiceResult> ExpireVoucher(Guid userVoucherId)
        {
            try
            {
                var now = DateTime.Now;

                var userVoucher = await _unitOfWork.UserVoucherRepository.GetQueryable()
                    .FirstOrDefaultAsync(uv => uv.Id == userVoucherId);

                if (userVoucher == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Voucher không tồn tại");

                if (userVoucher.ExpiryDate < now && userVoucher.Status != "Used")
                    userVoucher.Status = "Expired";

                await _unitOfWork.SaveChangesAsync();

                return new ServiceResult(Const.SUCCESS_UPDATE_CODE, "Voucher đã hết hạn");
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, "Đã xảy ra lỗi: " + ex.Message);
            }
        }


        // 7) DELETE VOUCHER (SOFT)
        public async Task<IServiceResult> DeleteVoucher(Guid voucherId)
        {
            try
            {
                var voucher = await _unitOfWork.VoucherRepository.GetQueryable()
                    .FirstOrDefaultAsync(v => v.Id == voucherId);

                if (voucher == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Voucher không tồn tại");

                voucher.IsActive = false;

                await _unitOfWork.SaveChangesAsync();
                return new ServiceResult(Const.SUCCESS_DELETE_CODE, "Xoá voucher thành công");
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, "Đã xảy ra lỗi: " + ex.Message);
            }
        }
        // Admin xem tất cả voucher (kể cả Inactive)
        public async Task<IServiceResult> GetAllVouchersForAdmin()
        {
            try
            {
                var vouchers = await _unitOfWork.VoucherRepository.GetQueryable()
                    .AsNoTracking()
                    .OrderByDescending(v => v.ValidFrom)
                    .ProjectToType<VoucherDto>()
                    .ToListAsync();

                if (vouchers.Count == 0)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy voucher nào.");

                return new ServiceResult(Const.SUCCESS_READ_CODE, "Lấy danh sách voucher thành công.", vouchers);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, "Đã xảy ra lỗi: " + ex.Message);
            }
        }
        // EVDriver xem voucher của mình
        public async Task<IServiceResult> GetMyVouchers(Guid evDriverId)
        {
            try
            {
                var now = DateTime.Now;

                var userVouchers = await _unitOfWork.UserVoucherRepository.GetQueryable()
                    .Include(uv => uv.Voucher)
                    .Where(uv => uv.EVDriverId == evDriverId
                                 && uv.Voucher.IsActive
                                 && uv.Voucher.ValidFrom <= now
                                 && uv.Voucher.ValidTo >= now)
                    .OrderByDescending(uv => uv.AssignedDate)
                    .ProjectToType<UserVoucherDto>()
                    .ToListAsync();

                if (userVouchers.Count == 0)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy voucher nào.");

                return new ServiceResult(Const.SUCCESS_READ_CODE, "Lấy danh sách voucher thành công.", userVouchers);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, "Đã xảy ra lỗi: " + ex.Message);
            }
        }



        // 8) EXPIRE ALL EXPIRED VOUCHERS (Background Job)
        public async Task<int> ExpireAllExpiredVouchers()
        {
            var now = DateTime.Now;

            var expiredVouchers = await _unitOfWork.UserVoucherRepository.GetQueryable()
                .Where(uv => uv.Status != "Used" && uv.ExpiryDate < now)
                .ToListAsync();

            if (expiredVouchers.Count == 0)
                return 0;

            foreach (var uv in expiredVouchers)
            {
                uv.Status = "Expired";
                uv.UpdatedAt = now;
            }

            await _unitOfWork.SaveChangesAsync();
            return expiredVouchers.Count;
        }
    }
}

