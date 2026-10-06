
using BusinessLogic.Base;

using Common.DTOs.ProfileStaffDto;

namespace BusinessLogic.IServices
{
    public interface ISCStaffService
    {
        //  Lấy thông tin Staff theo Id
        Task<IServiceResult> GetById(Guid id);

        //  Admin tạo tài khoản + hồ sơ Staff mới
        Task<IServiceResult> CreateAccountForStaff(StaffAccountCreateDto dto);

        Task<IServiceResult> GetByAccountId(Guid accountId);

        //  Admin cập nhật thông tin hồ sơ Staff
        Task<IServiceResult> UpdateProfileByAdmin(StaffUpdateAdminDto dto);

        //  Staff tự cập nhật hồ sơ của mình
        Task<IServiceResult> UpdateProfileByStaff(StaffUpdateDto dto);

        //  Admin thay đổi trạng thái hoạt động của Staff
        Task<IServiceResult> UpdateStaffStatus(StaffUpdateStatusDto dto);

        //  Admin xóa Staff (xóa mềm)
        Task<IServiceResult> Delete(Guid staffId);

        //  Admin lấy toàn bộ danh sách Staff chưa bị xóa
        Task<IServiceResult> GetAll();

        Task<IServiceResult> GetAllStaffAccount();
    }
}