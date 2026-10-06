using BusinessLogic.Base;

namespace BusinessLogic.IServices
{
    public interface ITransactionService
    {
        Task<IServiceResult> GetList();
        Task<IServiceResult> GetList(Guid paidBy);
        Task<IServiceResult> GetById(Guid transactionId);
    }
}
