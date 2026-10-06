using Infrastructure.Base;
using Infrastructure.Data;
using Infrastructure.IRepositories;
using Infrastructure.Models;

namespace Infrastructure.Repositories
{
    public class PaymentRepository(EVCSMSContext context) : GenericRepository<Payment>(context), IPaymentRepository
    {
    }
}
