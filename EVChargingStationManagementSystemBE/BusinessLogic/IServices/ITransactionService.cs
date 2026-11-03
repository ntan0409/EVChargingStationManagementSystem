using BusinessLogic.Base;

namespace BusinessLogic.IServices
{
    public interface ITransactionService
    {
        Task<IServiceResult> GetList(Guid? operatorId = null);
        Task<IServiceResult> GetList(Guid paidBy);
        Task<IServiceResult> GetById(Guid transactionId, Guid? accountId = null, Guid? operatorId = null);
    }
}
