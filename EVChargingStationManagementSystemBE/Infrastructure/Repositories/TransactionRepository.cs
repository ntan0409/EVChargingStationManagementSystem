using Infrastructure.Base;
using Infrastructure.Data;
using Infrastructure.IRepositories;
using Infrastructure.Models;

namespace Infrastructure.Repositories
{
    public class TransactionRepository (EVCSMSContext context) : GenericRepository<Transaction>(context), ITransactionRepository
    {
    }
}
