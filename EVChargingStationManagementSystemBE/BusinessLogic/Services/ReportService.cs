using BusinessLogic.Base;
using BusinessLogic.IServices;
using Common;
using Common.DTOs.ReportDto;
using Infrastructure.IUnitOfWork;
using Infrastructure.Models;
using Mapster;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace BusinessLogic.Services
{
    public class ReportService(
         IUnitOfWork unitOfWork,
         UserManager<UserAccount> userManager
     ) : IReportService
    {
        private readonly IUnitOfWork _unitOfWork = unitOfWork;
        private readonly UserManager<UserAccount> _userManager = userManager;
        //  LẤY TOÀN BỘ REPORT 
        public async Task<ServiceResult> GetAllAsync()
        {
            try
            {
                // Lấy tất cả report chưa bị xóa, kèm navigation để hiển thị thông tin đầy đủ
                var reports = await _unitOfWork.ReportRepository.GetQueryable()
                    .AsNoTracking()
                    .Where(r => !r.IsDeleted)
                    .Include(r => r.ReportedBy)
                    .Include(r => r.ChargingStation)
                    .Include(r => r.ChargingPost)
                    .OrderByDescending(r => r.CreatedAt)
                    .ToListAsync();

                if (reports == null || reports.Count == 0)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy báo cáo nào.");

                var response = new List<ViewReportDTO>();

                foreach (var report in reports)
                {
                    var dto = report.Adapt<ViewReportDTO>();

                    // Lấy role bằng UserManager
                    var user = report.ReportedBy;
                    if (user != null)
                    {
                        var roles = await _userManager.GetRolesAsync(user);
                        dto.RoleName = roles.FirstOrDefault(); // nếu chỉ có 1 role
                    }

                    response.Add(dto);
                }

                return new ServiceResult(Const.SUCCESS_READ_CODE, Const.SUCCESS_READ_MSG, response);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }
        }


        //  LẤY CHI TIẾT REPORT THEO ID 
        public async Task<ServiceResult> GetByIdAsync(Guid id)
        {
            try
            {
                var report = await _unitOfWork.ReportRepository.GetQueryable()
                    .AsNoTracking()
                    .Where(r => r.Id == id && !r.IsDeleted)
                    .Include(r => r.ReportedBy)
                    .Include(r => r.ChargingStation)
                    .Include(r => r.ChargingPost)
                    .ProjectToType<ViewReportDTO>()
                    .FirstOrDefaultAsync();

                if (report == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy báo cáo.");

                return new ServiceResult(Const.SUCCESS_READ_CODE, Const.SUCCESS_READ_MSG, report);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }
        }

        // TẠO MỚI REPORT 
        public async Task<ServiceResult> CreateAsync(ReportCreateDTO dto, Guid userId)
        {
            try
            {
                // Map từ DTO sang entity (theo cấu hình Mapster)
                var report = dto.Adapt<Report>();

                // Gán thêm các giá trị hệ thống
                report.Id = Guid.NewGuid();
                report.CreatedAt = DateTime.Now;
                report.UpdatedAt = DateTime.Now;
                report.Status = "Open";       // Mặc định khi tạo là "Open"
                report.ReportedById = userId; // Gán người báo cáo từ userId truyền vào

                await _unitOfWork.ReportRepository.CreateAsync(report);
                await _unitOfWork.SaveChangesAsync();

                var response = report.Adapt<ViewReportDTO>();
                return new ServiceResult(Const.SUCCESS_CREATE_CODE, Const.SUCCESS_CREATE_MSG, response);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }
        }

        // CẬP NHẬT REPORT 
        public async Task<ServiceResult> UpdateAsync(Guid id, ReportUpdateDTO dto)
        {
            try
            {
                var report = await _unitOfWork.ReportRepository.GetQueryable()
                    .Where(r => r.Id == id && !r.IsDeleted)
                    .FirstOrDefaultAsync();

                if (report == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy báo cáo.");

                // Map giá trị mới từ DTO sang entity hiện tại (chỉ map field khác null)
                dto.Adapt(report);
                report.UpdatedAt = DateTime.Now;

                var result = await _unitOfWork.SaveChangesAsync();
                if (result <= 0)
                    return new ServiceResult(Const.FAIL_UPDATE_CODE, Const.FAIL_UPDATE_MSG);

                var response = report.Adapt<ViewReportDTO>();
                return new ServiceResult(Const.SUCCESS_UPDATE_CODE, Const.SUCCESS_UPDATE_MSG, response);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }
        }


        // XÓA MỀM REPORT 
        public async Task<ServiceResult> DeleteAsync(Guid id)
        {
            try
            {
                var report = await _unitOfWork.ReportRepository.GetQueryable()
                    .Where(r => r.Id == id && !r.IsDeleted)
                    .FirstOrDefaultAsync();

                if (report == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy báo cáo.");

                // Đánh dấu là đã xóa và đóng report
                report.IsDeleted = true;
                report.Status = "Closed";
                report.UpdatedAt = DateTime.Now;

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
        public async Task<ServiceResult> CreateByEVDriverAsync(ReportCreateByUserDto dto, Guid userId)
        {
            try
            {
                // Map từ DTO sang entity (theo cấu hình Mapster)
                var report = dto.Adapt<Report>();

                // Gán thêm các giá trị hệ thống
                report.Id = Guid.NewGuid();
                report.CreatedAt = DateTime.Now;
                report.UpdatedAt = DateTime.Now;
                report.Status = "Open";
                report.IsDeleted = false;

                // Gán userId từ token vào ReportedById
                report.ReportedById = userId;

                await _unitOfWork.ReportRepository.CreateAsync(report);
                await _unitOfWork.SaveChangesAsync();

                var response = report.Adapt<ViewReportDTO>();
                return new ServiceResult(Const.SUCCESS_CREATE_CODE, Const.SUCCESS_CREATE_MSG, response);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.InnerException?.Message ?? ex.Message);
            }
        }
    }
}

