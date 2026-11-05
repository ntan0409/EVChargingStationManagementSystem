using BusinessLogic.Base;

namespace BusinessLogic.IServices
{
    public interface IPaymentService
    {
        Task<IServiceResult> CreateSandboxPayment(Guid sessionId, Guid accountId);
        Task<string?> GetSandboxForm(Guid sessionId, Guid accountId);
        Task<IServiceResult> CreateSePayPayment(Guid sessionId, Guid? accountId = null);
        Task<IServiceResult> ConfirmSePayPayment(Guid sessionId, Guid? accountId = null);
        Task<IServiceResult> ProcessSePayWebhook(string content, decimal amount);
        Task<IServiceResult> CreatePaymentURL(Guid sessionId, Guid? accountId = null);
        Task<string> ProcessVNPayIPN(Dictionary<string, string> queryParams);
        Task<IServiceResult> CreatePaymentOfflineRecord(Guid sessionId, Guid? accountId = null);
        Task<IServiceResult> GetSessionPayment(Guid sessionId, Guid? accountId = null);
        IServiceResult GetMethods();
        Task<IServiceResult> UpdatePaymentOfflineRecord(Guid paymentId, Guid userId, decimal receivedAmount);
        Task<IServiceResult> GetList(Guid userId, bool pendingOnly = false);
        Task<IServiceResult> GetById(Guid paymentId, Guid? operatorId);
    }
}
