using BusinessLogic.Base;
using BusinessLogic.IServices;
using Common;
using Common.DTOs.PaymentDto;
using Common.Enum.ChargingSession;
using Common.Enum.Payment;
using Common.Enum.Transaction;
using Common.Helper;
using Infrastructure.IUnitOfWork;
using Infrastructure.Models;
using Mapster;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Identity.Client;
using System.Web;

namespace BusinessLogic.Services
{
    public class PaymentService(IUnitOfWork unitOfWork, IConfiguration config, INotificationService notify) : IPaymentService
    {
        private readonly IUnitOfWork _unitOfWork = unitOfWork;
        private readonly IConfiguration _config = config;
        private readonly INotificationService _notify = notify;

        public async Task<IServiceResult> CreatePaymentURL(Guid sessionId)
        {
            try
            {
                var chargingSession = await _unitOfWork.ChargingSessionRepository.GetQueryable()
                    .AsNoTracking()
                    .Where(s => !s.IsDeleted && s.Id == sessionId)
                    .FirstOrDefaultAsync();

                if (chargingSession == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Phiên sạc này không tồn tại");

                if (chargingSession.Status.Equals(ChargingSessionStatus.Paid.ToString()))
                    return new ServiceResult(Const.FAIL_CREATE_CODE, "Phiên sạc này đã được thanh toán rồi");

                var txnRef = PaymentHelper.GenerateTxnRef(sessionId);
                string encoded = HttpUtility.UrlEncode("GiaTienPhienSac");

                var vat = await _unitOfWork.SystemConfigurationRepository.GetQueryable()
                    .AsNoTracking().Where(c => !c.IsDeleted && c.Name == "VAT").FirstOrDefaultAsync();

                decimal vatValue = 0;
                if (vat != null && _unitOfWork.SystemConfigurationRepository.Validate(vat))
                    vatValue = vat.MinValue ?? 0;

                var payment = new Payment
                {
                    ChargingSessionId = sessionId,
                    TxnRef = txnRef,
                    TaxRate = vatValue,
                    BeforeVatAmount = chargingSession.Cost
                };
                if (chargingSession.UserId != null || chargingSession.UserId != Guid.Empty)
                    payment.PaidBy = chargingSession.UserId;
                payment.Amount = payment.BeforeVatAmount * (1 + vatValue / 100);
                payment.CreatedAt = DateTime.Now;
                payment.UpdatedAt = DateTime.Now;


                var vnpParameters = PaymentHelper.CreateVnPayParameters(
                    _config["VnPay:TmnCode"],
                    (long)payment.Amount * 100,
                    txnRef,
                    encoded,
                    _config["VnPay:ReturnUrl"],
                    "127.0.0.1",
                    "vn");

                string url = PaymentHelper.CreateVnPayUrl(_config["VnPay:PaymentUrl"], vnpParameters, _config["VnPay:HashSecret"]);

                await _unitOfWork.PaymentRepository.CreateAsync(payment);
                var result = await _unitOfWork.SaveChangesAsync();

                if (result > 0)
                    return new ServiceResult(Const.SUCCESS_CREATE_CODE, "Tạo url thanh toán thành công", url);
                else
                    return new ServiceResult(Const.FAIL_CREATE_CODE, Const.FAIL_CREATE_MSG);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }

        }

        public async Task<string> ProcessVNPayIPN(Dictionary<string, string> queryParams)
        {
            try
            {
                // Lấy hash từ VNPay gửi đến
                var receivedHash = queryParams["vnp_SecureHash"];
                queryParams.Remove("vnp_SecureHash");
                queryParams.Remove("vnp_SecureHashType");

                // Tạo hash để kiểm tra
                string calculatedHash = PaymentHelper.CreateHmac512(_config["VnPay:HashSecret"], PaymentHelper.CreateDataString(queryParams));

                if (!receivedHash.Equals(calculatedHash, StringComparison.InvariantCultureIgnoreCase))
                    return JsonResponse("97", "Invalid signature");

                // Lấy thông tin giao dịch
                string txnRef = queryParams["vnp_TxnRef"];
                string responseCode = queryParams["vnp_ResponseCode"];
                string transactionStatus = queryParams["vnp_TransactionStatus"];
                string bankCode = queryParams.ContainsKey("vnp_BankCode") ? queryParams["vnp_BankCode"] : null;
                string cardType = queryParams.ContainsKey("vnp_CardType") ? queryParams["vnp_CardType"] : null;
                string transactionNo = queryParams.ContainsKey("vnp_TransactionNo") ? queryParams["vnp_TransactionNo"] : null;

                // Tìm payment tương ứng
                var payment = await _unitOfWork.PaymentRepository.GetQueryable()
                    .Where(p => p.TxnRef == txnRef).FirstOrDefaultAsync();

                if (payment == null)
                    return JsonResponse("01", "Không tìm thấy đơn thanh toán");

                var chargingSession = await _unitOfWork.ChargingSessionRepository.GetQueryable()
                    .Where(p => p.Id == payment.ChargingSessionId).FirstOrDefaultAsync();

                if (chargingSession == null)
                    return JsonResponse("01", "Không tìm thấy phiên sạc");

                var connector = await _unitOfWork.ConnectorRepository.GetQueryable()
                    .Where(p => p.Id == chargingSession.ConnectorId).FirstOrDefaultAsync();

                if (connector == null)
                    return JsonResponse("01", "Không tìm thấy cổng sạc");
                    //UpdatePoint(chargingSession.UserId ?? Guid.Empty, chargingSession.EnergyDeliveredKWh);

                if (bankCode != null)
                    payment.BankCode = bankCode;
                if (cardType != null)
                    payment.PaymentMethod = cardType;
                payment.UpdatedAt = DateTime.Now;

                // Cập nhật trạng thái thanh toán
                if (responseCode == "00" && transactionStatus == "00")
                {
                    payment.Status = PaymentStatus.Successed.ToString();

                    //Tích điểm cho tài xế
                    if (chargingSession.UserId != null || chargingSession.UserId != Guid.Empty)
                    {
                        var config = await _unitOfWork.SystemConfigurationRepository.GetQueryable()
                            .AsNoTracking()
                            .Where(c => !c.IsDeleted && c.Name == "POINT_PER_KWH")
                            .FirstOrDefaultAsync();

                        decimal pointValue = 0;
                        if (config != null && _unitOfWork.SystemConfigurationRepository.Validate(config))
                            pointValue = config.MinValue ?? 0;

                        var user = await _unitOfWork.UserAccountRepository.GetQueryable()
                            .Where(u => !u.IsDeleted && u.Id == chargingSession.UserId)
                            .Include(u => u.EVDriverProfile)
                            .FirstOrDefaultAsync();

                        if (user != null && user.EVDriverProfile != null)
                        {
                            user.EVDriverProfile.Point += (int)((decimal)chargingSession.EnergyDeliveredKWh * pointValue);
                            user.EVDriverProfile.UpdatedAt = DateTime.Now;
                        }
                    }

                    var transaction = new Transaction
                    {
                        Id = Guid.NewGuid(),
                        Amount = payment.Amount,
                        TransactionType = TransactionTypeEnum.OnlinePayment.ToString(),
                        Status = TransactionStatus.Completed.ToString(),
                        Note = $"VNPay Transaction: {transactionNo}",
                        InitiatedAt = payment.CreatedAt,
                        CompletedAt = DateTime.Now,
                        CreatedAt = DateTime.Now,
                        UpdatedAt = DateTime.Now,
                        PaymentId = payment.Id
                    };
                    if (payment.PaidBy != null || payment.PaidBy != Guid.Empty)
                        transaction.PaidBy = payment.PaidBy;
                    transaction.ReferenceCode = PaymentHelper.GenerateReferenceCode(transaction.TransactionType);

                    chargingSession.Status = ChargingSessionStatus.Paid.ToString();
                    chargingSession.UpdatedAt = DateTime.Now;

                    connector.IsLocked = false;
                    connector.UpdatedAt = DateTime.Now;

                    await _unitOfWork.TransactionRepository.CreateAsync(transaction);
                    await _unitOfWork.SaveChangesAsync();

                    return JsonResponse("00", "Thanh toán thành công");
                }
                else
                {
                    payment.Status = PaymentStatus.Failed.ToString();

                    await _unitOfWork.SaveChangesAsync();

                    return JsonResponse("02", "Thanh toán thất bại");
                }
            }
            catch (Exception ex)
            {
                return JsonResponse("99", "Lỗi không xác định: " + ex.Message);
            }
        }

        // Api này sẽ được gửi cho staff khi tài xế chọn thanh  toán offline
        // Gửi cho staff đang quản lý trạm đó (Xử lý bên FE)
        public async Task<IServiceResult> CreatePaymentOfflineRecord(Guid sessionId)
        {
            try
            {
                var chargingSession = await _unitOfWork.ChargingSessionRepository.GetQueryable()
                    .Where(cs => cs.Id == sessionId)
                    .Include(cs => cs.ChargingPost)
                        .ThenInclude(cs => cs.ChargingStationNavigation)
                    .FirstOrDefaultAsync();

                if (chargingSession == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy phiên sạc nào");

                if (chargingSession.Status.Equals(ChargingSessionStatus.Paid.ToString()))
                    return new ServiceResult(Const.FAIL_CREATE_CODE, "Phiên sạc này đã được thanh toán rồi");

                var txnRef = PaymentHelper.GenerateTxnRef(sessionId);

                var vat = await _unitOfWork.SystemConfigurationRepository.GetQueryable()
                    .AsNoTracking().Where(c => !c.IsDeleted && c.Name == "VAT").FirstOrDefaultAsync();

                decimal vatValue = 0;
                if (vat != null && _unitOfWork.SystemConfigurationRepository.Validate(vat))
                    vatValue = vat.MinValue ?? 0;

                var payment = new Payment
                {
                    Id = Guid.NewGuid(),
                    ChargingSessionId = sessionId,
                    TxnRef = txnRef,
                    TaxRate = vatValue,
                    BeforeVatAmount = chargingSession.Cost,
                };
                if (chargingSession.UserId != null || chargingSession.UserId != Guid.Empty)
                    payment.PaidBy = chargingSession.UserId;
                payment.PaymentMethod = "OFFLINE";
                payment.Amount = payment.BeforeVatAmount * (1 + vatValue / 100);
                payment.Status = PaymentStatus.Initiated.ToString();
                payment.CreatedAt = DateTime.Now;
                payment.UpdatedAt = DateTime.Now;

                await _unitOfWork.PaymentRepository.CreateAsync(payment);

                if (chargingSession.ChargingPost.ChargingStationNavigation.OperatorId == Guid.Empty)
                    return new ServiceResult(Const.FAIL_CREATE_CODE, "Không tìm thấy nhân viên trạm");

                //Gửi thông báo cho staff
                var notifyStaffs = await _notify.NotifyStaffOffLinePaymentRecord(
                    chargingSession.ChargingPost.ChargingStationNavigation.OperatorId ?? Guid.Empty,
                    chargingSession.UserId ?? Guid.Empty,
                    "Có người dùng chọn phương thức thanh toán offline cho phiên sạc mã: " + chargingSession.Id +
                    "\n Vui lòng cập nhật hóa đơn này sau khi đã nhận tiền mặt của khách hàng" +
                    $"\n Chi tiết hóa đơn: {_config["VnPay:FEOfflinePaymentBillPage"]}?paymentId={payment.Id}"
                    );

                var result = await _unitOfWork.SaveChangesAsync();

                if (result > 0)
                    return new ServiceResult(Const.SUCCESS_CREATE_CODE, "Đã ghi nhận phương thức thanh toán tiền mặt, vui lòng đến quầy nhân viên để thanh toán");
                else
                    return new ServiceResult(Const.FAIL_CREATE_CODE, Const.FAIL_CREATE_MSG);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }

        }

        // Staff nhận tiền xong bấm api này
        public async Task<IServiceResult> UpdatePaymentOfflineRecord(Guid paymentId, Guid userId)
        {
            try
            {
                var payment = await _unitOfWork.PaymentRepository.GetQueryable()
                    .Where(s => !s.IsDeleted && s.Id == paymentId).FirstOrDefaultAsync();

                if (payment == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy đơn thanh toán");

                var chargingSession = await _unitOfWork.ChargingSessionRepository.GetQueryable()
                    .Where(s => !s.IsDeleted && s.Id == payment.ChargingSessionId).FirstOrDefaultAsync();

                if (chargingSession == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy phiên sạc của đơn thanh toán này");

                var connector = await _unitOfWork.ConnectorRepository.GetQueryable()
                    .Where(s => !s.IsDeleted && s.Id == chargingSession.ConnectorId)
                    .Include(s => s.ChargingPost).ThenInclude(s => s.ChargingStationNavigation)
                    .FirstOrDefaultAsync();

                if (connector == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy cổng sạc của phiên sạc này");

                if (connector.ChargingPost.ChargingStationNavigation.OperatorId != userId)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Tài khoản này không phụ trách trạm này, vui lòng đăng nhập bằng tài khoản nhân viên khác");

                if (chargingSession.Status.Equals(ChargingSessionStatus.Paid.ToString()))
                    return new ServiceResult(Const.FAIL_CREATE_CODE, "Phiên sạc này đã được thanh toán rồi");

                //Tích điểm cho tài xế
                if (chargingSession.UserId != null || chargingSession.UserId != Guid.Empty)
                {
                    var config = await _unitOfWork.SystemConfigurationRepository.GetQueryable()
                        .AsNoTracking()
                        .Where(c => !c.IsDeleted && c.Name == "POINT_PER_KWH")
                        .FirstOrDefaultAsync();

                    decimal pointValue = 0;
                    if (config != null && _unitOfWork.SystemConfigurationRepository.Validate(config))
                        pointValue = config.MinValue ?? 0;

                    var user = await _unitOfWork.UserAccountRepository.GetQueryable()
                        .Where(u => !u.IsDeleted && u.Id == chargingSession.UserId)
                        .Include(u => u.EVDriverProfile)
                        .FirstOrDefaultAsync();

                    if (user != null && user.EVDriverProfile != null)
                    {
                        user.EVDriverProfile.Point += (int)((decimal)chargingSession.EnergyDeliveredKWh * pointValue);
                        user.EVDriverProfile.UpdatedAt = DateTime.Now;
                    }
                }

                payment.Status = PaymentStatus.Successed.ToString();
                payment.UpdatedAt = DateTime.Now;

                var transaction = new Transaction
                {
                    Id = Guid.NewGuid(),
                    Amount = payment.Amount,
                    TransactionType = TransactionTypeEnum.OfflinePayment.ToString(),
                    Status = TransactionStatus.Completed.ToString(),
                    Note = $"Offline Transaction",
                    InitiatedAt = payment.CreatedAt,
                    CompletedAt = DateTime.Now,
                    CreatedAt = DateTime.Now,
                    UpdatedAt = DateTime.Now,
                    PaymentId = payment.Id
                };
                if (payment.PaidBy != null || payment.PaidBy != Guid.Empty)
                    transaction.PaidBy = payment.PaidBy;
                transaction.ReferenceCode = PaymentHelper.GenerateReferenceCode(transaction.TransactionType);

                chargingSession.Status = ChargingSessionStatus.Paid.ToString();
                chargingSession.UpdatedAt = DateTime.Now;

                connector.IsLocked = false;
                connector.UpdatedAt = DateTime.Now;

                await _unitOfWork.TransactionRepository.CreateAsync(transaction);
                var result = await _unitOfWork.SaveChangesAsync();

                if (result > 0)
                    return new ServiceResult(Const.SUCCESS_CREATE_CODE, "Ghi nhận giao dịch thành công");

                return new ServiceResult(Const.FAIL_CREATE_CODE, Const.FAIL_CREATE_MSG);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }
        }
        public async Task<IServiceResult> GetList(Guid userId)
        {

            try
            {
                var payment = await _unitOfWork.PaymentRepository.GetQueryable()
                    .AsNoTracking()
                    .Where(c => !c.IsDeleted)
                    .Where(p => p.ChargingSessionNavigation.ChargingPost.ChargingStationNavigation.OperatorId == userId)
                    .OrderByDescending(c => c.CreatedAt)
                    .ProjectToType<PaymentViewDetailDto>()
                    .ToListAsync();

                if (payment == null || payment.Count == 0)
                    return new ServiceResult(
                        Const.WARNING_NO_DATA_CODE,
                        "Không tìm thấy giao dịch nào");

                else
                    return new ServiceResult(Const.SUCCESS_READ_CODE, Const.SUCCESS_READ_MSG, payment);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }
        }
        public async Task<IServiceResult> GetById(Guid paymentId)
        {
            try
            {
                var payment = await _unitOfWork.PaymentRepository.GetQueryable()
                    .AsNoTracking()
                    .Where(s => !s.IsDeleted && s.Id == paymentId)
                    .ProjectToType<PaymentViewDetailDto>()
                    .FirstOrDefaultAsync();

                if (payment == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy đơn thanh toán");

                return new ServiceResult(Const.SUCCESS_READ_CODE, Const.SUCCESS_READ_MSG, payment);
            }
            catch (Exception ex)
            {
                return new ServiceResult(Const.ERROR_EXCEPTION, ex.Message);
            }

        }

        private static string JsonResponse(string rspCode, string message)
        {
            return $"{{\"RspCode\":\"{rspCode}\",\"Message\":\"{message}\"}}";
        }

    }
}
