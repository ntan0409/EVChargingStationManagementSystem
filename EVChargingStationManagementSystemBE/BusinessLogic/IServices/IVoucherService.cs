using BusinessLogic.Base;
using Common.DTOs.VoucherDto;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BusinessLogic.IServices
{
    public interface IVoucherService
    {
          // ===== ADMIN CRUD =====
        Task<IServiceResult> CreateVoucher(VoucherCreateDto dto);
        Task<IServiceResult> UpdateVoucher(VoucherUpdateDto dto, Guid voucherId);
        Task<IServiceResult> DeleteVoucher(Guid voucherId);
        Task<IServiceResult> GetAllVouchersForAdmin();


        // ===== USER FLOW =====    
        Task<IServiceResult> GetAvailableVouchers();
        Task<IServiceResult> RedeemVoucher(Guid evDriverId, Guid voucherId);
        Task<IServiceResult> UseVoucher(Guid userVoucherId, Guid sessionId);

        Task<IServiceResult> GetMyVouchers(Guid evDriverId);

        // ===== BACKGROUND JOB =====
        Task<IServiceResult> ExpireVoucher(Guid userVoucherId);
        Task<int> ExpireAllExpiredVouchers();
    }
}