using Azure;
using BusinessLogic.Base;
using BusinessLogic.IServices;
using Common;
using Common.DTOs.TransactionDto;
using Infrastructure.IUnitOfWork;
using Mapster;
using Microsoft.EntityFrameworkCore;

namespace BusinessLogic.Services
{
    public class TransactionService(IUnitOfWork unitOfWork) : ITransactionService
    {
        private readonly IUnitOfWork _unitOfWork = unitOfWork;

        public async Task<IServiceResult> GetList()
        {

            try
            {
                var transaction = await _unitOfWork.TransactionRepository.GetQueryable()
                    .AsNoTracking()
                    .Where(v => !v.IsDeleted)
                    .OrderByDescending(v => v.CreatedAt)
                    .ProjectToType<TransactionViewListDto>()
                    .ToListAsync();
                if (transaction == null || transaction.Count == 0)
                    return new ServiceResult(
                        Const.WARNING_NO_DATA_CODE,
                        "Không tìm thấy lịch sử giao dịch nào");

                else
                    return new ServiceResult(Const.SUCCESS_READ_CODE, Const.SUCCESS_READ_MSG, transaction);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }
        }

        public async Task<IServiceResult> GetList(Guid paidBy)
        {

            try
            {
                var transaction = await _unitOfWork.TransactionRepository.GetQueryable()
                    .AsNoTracking()
                    .Where(v => !v.IsDeleted && v.PaidBy == paidBy)
                    .OrderByDescending(v => v.CreatedAt) 
                    .ProjectToType<TransactionViewListDto>()
                    .ToListAsync();

                if (transaction == null || transaction.Count == 0)
                    return new ServiceResult(
                        Const.WARNING_NO_DATA_CODE,
                        "Không tìm thấy lịch sử giao dịch nào");

                else
                    return new ServiceResult(Const.SUCCESS_READ_CODE, Const.SUCCESS_READ_MSG, transaction);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }
        }

        public async Task<IServiceResult> GetById(Guid transactionId)
        {

            try
            {
                var transaction = await _unitOfWork.TransactionRepository.GetQueryable()
                    .AsNoTracking()
                    .Where(v => !v.IsDeleted && v.Id == transactionId)
                    .ProjectToType<TransactionViewDetailDto>()
                    .FirstOrDefaultAsync();
                if (transaction == null)
                    return new ServiceResult(
                        Const.WARNING_NO_DATA_CODE,
                        "Không tìm thấy lịch sử giao dịch nào"
                    );

                else
                    return new ServiceResult(Const.SUCCESS_READ_CODE, Const.SUCCESS_READ_MSG, transaction);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }
        }

    }
}
