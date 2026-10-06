using BusinessLogic.IServices;
using Infrastructure.IUnitOfWork;
using Microsoft.EntityFrameworkCore;

namespace BusinessLogic.Services
{
    public class CheckInCodeService(IUnitOfWork unitOfWork) : ICheckInCodeService
    {
        readonly IUnitOfWork _unitOfWork = unitOfWork;
        static readonly Random _random = new();

        public async Task<string> GenerateUniqueCodeAsync()
        {
            string code;
            bool exists;

            do
            {
                code = _random.Next(1000, 10000).ToString();

                //exists = (await _unitOfWork.BookingRepository.GetAllAsync(
                //    b => b.CheckInCode == code
                //)).Any();
                exists = (await _unitOfWork.BookingRepository.GetQueryable()
                    .Where(b => b.CheckInCode == code).ToListAsync()
                    ).Count != 0;

            } while (exists);

            return code;
        }
    }
}