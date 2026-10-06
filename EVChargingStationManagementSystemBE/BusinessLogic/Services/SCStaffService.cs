using BusinessLogic.Base;
using BusinessLogic.IServices;
using Common;
using Common.DTOs.ProfileStaffDto;
using Infrastructure.IUnitOfWork;
using Infrastructure.Models;
using Mapster;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace BusinessLogic.Services
{
    public class SCStaffService(
        IUnitOfWork unitOfWork,
        UserManager<UserAccount> userManager
    ) : ISCStaffService
    {
        private readonly IUnitOfWork _unitOfWork = unitOfWork;
        private readonly UserManager<UserAccount> _userManager = userManager;

        // Lấy danh sách tất cả Staff
        public async Task<IServiceResult> GetAll()
        {
            try
            {
                var staffs = await _unitOfWork.SCStaffRepository.GetQueryable()
                    .AsNoTracking()
                    .Where(s => !s.IsDeleted)
                    .Include(x => x.UserAccountNavigation)
                    .OrderByDescending(s => s.CreatedAt)
                    .ProjectToType<StaffViewDto>()
                    .ToListAsync();

                if (staffs == null || staffs.Count == 0)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy nhân viên nào.");

                return new ServiceResult(Const.SUCCESS_READ_CODE, "Lấy danh sách nhân viên thành công.", staffs);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, $"Đã xảy ra lỗi: {ex.Message}");
            }
        }

        public async Task<IServiceResult> GetAllStaffAccount()
        {
            try
            {
                var staffs = await _unitOfWork.UserAccountRepository.GetQueryable()
                    .AsNoTracking()
                    .Where(s => !s.IsDeleted && s.SCStaffProfile != null)
                    .Include(Task => Task.SCStaffProfile)
                    .OrderByDescending(s => s.CreatedAt)
                    .ProjectToType<StaffViewDto>()
                    .ToListAsync();

                if (staffs == null || staffs.Count == 0)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy nhân viên nào.");

                return new ServiceResult(Const.SUCCESS_READ_CODE, "Lấy danh sách nhân viên thành công.", staffs);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, $"Đã xảy ra lỗi: {ex.Message}");
            }
        }

        // Lấy thông tin chi tiết nhân viên
        public async Task<IServiceResult> GetById(Guid id)
        {
            try
            {
                var staff = await _unitOfWork.SCStaffRepository.GetQueryable()
                    .AsNoTracking()
                    .Where(s => s.Id == id && !s.IsDeleted)
                    .Include(Task => Task.UserAccountNavigation)
                    .ProjectToType<StaffViewDto>()
                    .FirstOrDefaultAsync();

                if (staff == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy nhân viên.");

                return new ServiceResult(Const.SUCCESS_READ_CODE, "Lấy thông tin nhân viên thành công.", staff);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, $"Đã xảy ra lỗi: {ex.Message}");
            }
        }

        // Tạo tài khoản + hồ sơ nhân viên
        public async Task<IServiceResult> CreateAccountForStaff(StaffAccountCreateDto dto)
        {
            try
            {
                // 1. Kiểm tra mật khẩu xác nhận
                if (dto.Password != dto.ConfirmPassword)
                    return new ServiceResult(Const.FAIL_CREATE_CODE, "Mật khẩu xác nhận không khớp.");

                // 2. Kiểm tra email đã tồn tại
                var existedEmail = await _userManager.FindByEmailAsync(dto.Email.ToLowerInvariant());
                if (existedEmail != null)
                    return new ServiceResult(Const.FAIL_CREATE_CODE, "Email đã tồn tại trong hệ thống.");

                // 3. Kiểm tra số điện thoại đã tồn tại
                var normalizedPhone = NormalizePhone(dto.PhoneNumber);
                var existedPhone = await _unitOfWork.UserAccountRepository.GetQueryable()
                    .FirstOrDefaultAsync(x => NormalizePhone(x.PhoneNumber) == normalizedPhone && !x.IsDeleted);
                if (existedPhone != null)
                    return new ServiceResult(Const.FAIL_CREATE_CODE, "Số điện thoại đã tồn tại trong hệ thống.");

                // 4. Tạo UserAccount
                var user = dto.Adapt<UserAccount>();
                user.Email = dto.Email.ToLowerInvariant();
                user.UserName = dto.Email.ToLowerInvariant();
                user.PhoneNumber = normalizedPhone;
                user.RegistrationDate = DateTime.Now;
                user.Status = "Active";
                user.CreatedAt = DateTime.Now;
                user.UpdatedAt = DateTime.Now;

                var createResult = await _userManager.CreateAsync(user, dto.Password);
                if (!createResult.Succeeded)
                {
                    var errors = createResult.Errors.Select(e => e.Description).ToList();
                    return new ServiceResult(Const.FAIL_CREATE_CODE, "Không thể tạo tài khoản.", errors);
                }

                // 5. Gán role Staff
                var roleResult = await _userManager.AddToRoleAsync(user, "Staff");
                if (!roleResult.Succeeded)
                {
                    var errors = roleResult.Errors.Select(e => e.Description).ToList();
                    return new ServiceResult(Const.FAIL_CREATE_CODE, "Không thể gán quyền Staff.", errors);
                }

                // 6. Tạo hồ sơ nhân viên
                var staff = dto.Adapt<SCStaffProfile>();
                staff.Id = Guid.NewGuid();
                staff.AccountId = user.Id;
                staff.Status = "Active";
                staff.CreatedAt = DateTime.Now;
                staff.UpdatedAt = DateTime.Now;
                staff.IsDeleted = false;

                await _unitOfWork.SCStaffRepository.CreateAsync(staff);
                await _unitOfWork.SaveChangesAsync();

                var response = staff.Adapt<StaffViewDto>();
                return new ServiceResult(Const.SUCCESS_CREATE_CODE, "Tạo tài khoản và hồ sơ nhân viên thành công.", response);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, $"Đã xảy ra lỗi: {ex.Message}");
            }
        }

        // Hàm chuẩn hóa số điện thoại
        private string NormalizePhone(string phone)
        {
            if (string.IsNullOrWhiteSpace(phone)) return phone;
            phone = phone.Replace(" ", "").Replace("-", "");
            if (phone.StartsWith("+84"))
                phone = "0" + phone.Substring(3);
            return phone;
        }


        // Admin cập nhật nhân viên
        public async Task<IServiceResult> UpdateProfileByAdmin(StaffUpdateAdminDto dto)
        {
            try
            {
                var staff = await _unitOfWork.SCStaffRepository.GetQueryable()
                    .Where(s => s.Id == dto.StaffId && !s.IsDeleted)
                    .Include(Task => Task.UserAccountNavigation)
                    .FirstOrDefaultAsync();

                if (staff == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy nhân viên.");

                dto.Adapt(staff);
                staff.UpdatedAt = DateTime.Now;

                if (staff.UserAccountNavigation != null)
                {
                    dto.Adapt(staff.UserAccountNavigation);
                    staff.UserAccountNavigation.UpdatedAt = DateTime.Now;
                }

                var result = await _unitOfWork.SaveChangesAsync();
                if (result <= 0)
                    return new ServiceResult(Const.FAIL_UPDATE_CODE, "Cập nhật thông tin nhân viên thất bại.");

                var response = staff.Adapt<StaffViewDto>();
                return new ServiceResult(Const.SUCCESS_UPDATE_CODE, "Cập nhật thông tin nhân viên thành công.", response);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, $"Đã xảy ra lỗi: {ex.Message}");
            }
        }

        // Nhân viên tự cập nhật hồ sơ
        public async Task<IServiceResult> UpdateProfileByStaff(StaffUpdateDto dto)
        {
            try
            {
                var staff = await _unitOfWork.SCStaffRepository.GetQueryable()
                    .Where(s => s.Id == dto.StaffId && !s.IsDeleted)
                    .Include(Task => Task.UserAccountNavigation)
                    .FirstOrDefaultAsync();

                if (staff == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy nhân viên.");

                dto.Adapt(staff);
                staff.UpdatedAt = DateTime.Now;

                if (staff.UserAccountNavigation != null)
                {
                    dto.Adapt(staff.UserAccountNavigation);
                    staff.UserAccountNavigation.UpdatedAt = DateTime.Now;
                }

                var result = await _unitOfWork.SaveChangesAsync();
                if (result <= 0)
                    return new ServiceResult(Const.FAIL_UPDATE_CODE, "Cập nhật thông tin thất bại.");

                var response = staff.Adapt<StaffViewDto>();
                return new ServiceResult(Const.SUCCESS_UPDATE_CODE, "Cập nhật thông tin thành công.", response);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, $"Đã xảy ra lỗi: {ex.Message}");
            }
        }

        // Cập nhật trạng thái nhân viên
        public async Task<IServiceResult> UpdateStaffStatus(StaffUpdateStatusDto dto)
        {
            try
            {
                var staff = await _unitOfWork.SCStaffRepository.GetQueryable()
                    .Where(s => s.Id == dto.StaffId && !s.IsDeleted)
                    .FirstOrDefaultAsync();

                if (staff == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy nhân viên.");

                staff.Status = dto.Status;
                staff.UpdatedAt = DateTime.Now;

                var result = await _unitOfWork.SaveChangesAsync();
                if (result <= 0)
                    return new ServiceResult(Const.FAIL_UPDATE_CODE, "Cập nhật trạng thái thất bại.");

                var response = staff.Adapt<StaffViewDto>();
                return new ServiceResult(Const.SUCCESS_UPDATE_CODE, "Cập nhật trạng thái thành công.", response);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, $"Đã xảy ra lỗi: {ex.Message}");
            }
        }

        // Xóa mềm nhân viên
        public async Task<IServiceResult> Delete(Guid staffId)
        {
            try
            {
                var staff = await _unitOfWork.SCStaffRepository.GetQueryable()
                    .Where(s => s.Id == staffId && !s.IsDeleted)
                    .FirstOrDefaultAsync();

                if (staff == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy nhân viên.");

                staff.IsDeleted = true;
                staff.Status = "Inactive";
                staff.UpdatedAt = DateTime.Now;

                var result = await _unitOfWork.SaveChangesAsync();
                if (result <= 0)
                    return new ServiceResult(Const.FAIL_DELETE_CODE, "Xóa nhân viên thất bại.");

                return new ServiceResult(Const.SUCCESS_DELETE_CODE, "Xóa nhân viên thành công.");
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, $"Đã xảy ra lỗi: {ex.Message}");
            }
        }

        public async Task<IServiceResult> GetByAccountId(Guid accountId)
        {
            try
            {
                var staff = await _unitOfWork.SCStaffRepository.GetQueryable()
                    .AsNoTracking()
                    .Where(s => s.AccountId == accountId && !s.IsDeleted)
                    .Include(Task => Task.UserAccountNavigation)
                    .ProjectToType<StaffViewDto>()
                    .FirstOrDefaultAsync();

                if (staff == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE,
                        "Không tìm thấy hồ sơ nhân viên tương ứng với tài khoản này.");

                return new ServiceResult(Const.SUCCESS_READ_CODE, "Lấy thông tin nhân viên thành công.", staff);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, $"Đã xảy ra lỗi: {ex.Message}");
            }
        }
    }
}
