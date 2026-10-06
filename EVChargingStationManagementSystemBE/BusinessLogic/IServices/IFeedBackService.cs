using BusinessLogic.Base;
using Common.DTOs.FeedbackDto;

namespace BusinessLogic.IServices
{
    public interface IFeedbackService
    {
        Task<IServiceResult> CreateFeedbackAsync(FeedbackCreateDto dto, Guid userId);
        Task<IServiceResult> GetAllFeedbacksAsync();
        Task<IServiceResult> GetFeedbackByIdAsync(Guid id);
        Task<IServiceResult> UpdateStatusAsync(FeedbackUpdateStatusDto dto);
    }
}
