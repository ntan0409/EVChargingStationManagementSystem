using BusinessLogic.Base;

namespace BusinessLogic.IServices
{
    public interface IPaymentService
    {
        Task<IServiceResult> CreatePaymentURL(Guid sessionId, Guid? accountId = null);
        Task<string> ProcessVNPayIPN(Dictionary<string, string> queryParams);
        Task<IServiceResult> CreatePaymentOfflineRecord(Guid sessionId, Guid? accountId = null);
        Task<IServiceResult> GetSessionPayment(Guid sessionId, Guid accountId);
        IServiceResult GetMethods();
        Task<IServiceResult> UpdatePaymentOfflineRecord(Guid paymentId, Guid userId, decimal receivedAmount);
        Task<IServiceResult> GetList(Guid userId, bool pendingOnly = false);
        Task<IServiceResult> GetById(Guid paymentId, Guid? operatorId);
    }
}
