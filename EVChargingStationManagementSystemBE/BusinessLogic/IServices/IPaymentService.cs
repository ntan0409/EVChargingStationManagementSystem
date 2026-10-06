using BusinessLogic.Base;

namespace BusinessLogic.IServices
{
    public interface IPaymentService
    {
        Task<IServiceResult> CreatePaymentURL(Guid sessionId);
        Task<string> ProcessVNPayIPN(Dictionary<string, string> queryParams);
        Task<IServiceResult> CreatePaymentOfflineRecord(Guid sessionId);
        Task<IServiceResult> UpdatePaymentOfflineRecord(Guid paymentId, Guid userId);
        Task<IServiceResult> GetList(Guid userId);
        Task<IServiceResult> GetById(Guid paymentId);
    }
}
