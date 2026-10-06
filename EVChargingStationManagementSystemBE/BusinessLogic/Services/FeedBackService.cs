using BusinessLogic.Base;
using BusinessLogic.IServices;
using Common;
using Common.DTOs.FeedbackDto;
using Infrastructure.IUnitOfWork;
using Infrastructure.Models;
using Mapster;
using Microsoft.EntityFrameworkCore;

namespace BusinessLogic.Services
{
    public class FeedbackService(IUnitOfWork unitOfWork) : IFeedbackService
    {
        private readonly IUnitOfWork _unitOfWork = unitOfWork;

        // TẠO PHẢN HỒI (AccountId lấy từ token)
        public async Task<IServiceResult> CreateFeedbackAsync(FeedbackCreateDto dto, Guid userId)
        {
            try
            {
                var feedback = dto.Adapt<Feedback>();
                feedback.Id = Guid.NewGuid();
                feedback.AccountId = userId;             //  gán từ token
                feedback.CreatedAt = DateTime.UtcNow;
                feedback.IsResolved = false;

                await _unitOfWork.FeedBackRepository.CreateAsync(feedback);
                await _unitOfWork.SaveChangesAsync();

                var response = feedback.Adapt<FeedbackReadDto>();
                return new ServiceResult(Const.SUCCESS_CREATE_CODE, Const.SUCCESS_CREATE_MSG, response);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.InnerException?.Message ?? ex.Message);
            }
        }

        // LẤY DANH SÁCH PHẢN HỒI
        public async Task<IServiceResult> GetAllFeedbacksAsync()
        {
            try
            {
                var feedbacks = await _unitOfWork.FeedBackRepository.GetQueryable()
                    .AsNoTracking()
                    .Include(f => f.UserAccount)
                    .OrderByDescending(f => f.CreatedAt)
                    .ProjectToType<FeedbackListDto>()
                    .ToListAsync();
                if (feedbacks == null || feedbacks.Count == 0)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không có phản hồi nào.");

                return new ServiceResult(Const.SUCCESS_READ_CODE, Const.SUCCESS_READ_MSG, feedbacks);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.InnerException?.Message ?? ex.Message);
            }
        }

        // LẤY PHẢN HỒI THEO ID
        public async Task<IServiceResult> GetFeedbackByIdAsync(Guid id)
        {
            try
            {
                var feedback = await _unitOfWork.FeedBackRepository.GetQueryable()
                    .AsNoTracking()
                    .Where(f => f.Id == id)
                    .Include(f => f.UserAccount)
                    .ProjectToType<FeedbackReadDto>()
                    .FirstOrDefaultAsync();

                if (feedback == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy phản hồi.");

                return new ServiceResult(Const.SUCCESS_READ_CODE, Const.SUCCESS_READ_MSG, feedback);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.InnerException?.Message ?? ex.Message);
            }
        }

        // CẬP NHẬT TRẠNG THÁI PHẢN HỒI
        public async Task<IServiceResult> UpdateStatusAsync(FeedbackUpdateStatusDto dto)
        {
            try
            {
                var feedback = await _unitOfWork.FeedBackRepository.GetQueryable()
                    .Where(f => f.Id == dto.Id)
                    .FirstOrDefaultAsync();

                if (feedback == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy phản hồi.");

                feedback.IsResolved = dto.IsResolved;

                var result = await _unitOfWork.SaveChangesAsync();
                if (result <= 0)
                    return new ServiceResult(Const.FAIL_UPDATE_CODE, Const.FAIL_UPDATE_MSG);

                var response = feedback.Adapt<FeedbackReadDto>();
                return new ServiceResult(Const.SUCCESS_UPDATE_CODE, Const.SUCCESS_UPDATE_MSG, response);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.InnerException?.Message ?? ex.Message);
            }
        }
    }
}
