using BusinessLogic.Base;
using BusinessLogic.IServices;
using Common;
using Common.DTOs.PaymentDto;
using Common.Helper;
using Infrastructure.Data;
using Infrastructure.Models;
using Mapster;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using System.Globalization;
using System.Text.Json;

namespace BusinessLogic.Services;

public class PaymentService(EVCSMSContext db, IConfiguration config, INotificationService notify) : IPaymentService
{
    private static IServiceResult Fail(string message) => new ServiceResult(Const.FAIL_CREATE_CODE, message);
    private static IServiceResult Missing() => new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy hóa đơn hoặc phiên sạc của bạn.");
    private static IServiceResult Ok(object data, string message = "Lấy dữ liệu thành công") => new ServiceResult(Const.SUCCESS_READ_CODE, message, data);
    private bool GatewayConfigured => string.Equals(config["VnPay:Enabled"], "true", StringComparison.OrdinalIgnoreCase) &&
        config["VnPay:Mode"] == "Sandbox" &&
        !string.IsNullOrWhiteSpace(config["VnPay:TmnCode"]) &&
        !string.IsNullOrWhiteSpace(config["VnPay:HashSecret"]) &&
        config["VnPay:PaymentUrl"] == "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html" &&
        IsCallback(config["VnPay:ReturnUrl"], "/api/Payment/vnpay/return") &&
        IsCallback(config["VnPay:IpnUrl"], "/api/Payment/vnpay/ipn");

    private static bool IsCallback(string? value, string path) =>
        Uri.TryCreate(value, UriKind.Absolute, out var url) && url.Scheme == Uri.UriSchemeHttps &&
        !url.IsLoopback && url.HostNameType == UriHostNameType.Dns && url.Host.Contains('.') &&
        url.AbsolutePath.Equals(path, StringComparison.OrdinalIgnoreCase) &&
        url.UserInfo.Length == 0 && url.Query.Length == 0 && url.Fragment.Length == 0;

    private const string SePayMethod = "SePayTest";
    private static readonly HttpClient SePayHttp = new(new HttpClientHandler { AllowAutoRedirect = false })
    {
        Timeout = TimeSpan.FromSeconds(4)
    };

    private bool SePayConfigured => string.Equals(config["SePay:Enabled"], "true", StringComparison.OrdinalIgnoreCase) &&
        !string.IsNullOrWhiteSpace(config["SePay:TestToken"]) &&
        !string.IsNullOrWhiteSpace(config["SePay:TestBankAccountId"]);

    public IServiceResult GetMethods() => Ok(new[]
    {
        new { id = "SePayTest", name = "SePay Test Mode", available = SePayConfigured },
        new { id = "Offline", name = "Thanh toán tại quầy (chờ nhân viên xác nhận)", available = true }
    });

    private async Task<decimal?> TaxRate()
    {
        var now = DateTime.Now;
        var tax = await db.SystemConfigurations.AsNoTracking().Where(c => !c.IsDeleted && c.Name == "VAT" &&
            c.EffectedDateFrom <= now && (c.EffectedDateTo == null || c.EffectedDateTo >= now))
            .OrderByDescending(c => c.EffectedDateFrom).FirstOrDefaultAsync();
        return tax?.MinValue is >= 0 and <= 100 ? tax.MinValue : null;
    }

    private static decimal Total(decimal cost, decimal tax) => decimal.Round(cost * (1 + tax / 100), 0, MidpointRounding.AwayFromZero);

    public async Task<IServiceResult> GetSessionPayment(Guid sessionId, Guid? accountId = null)
    {
        var session = await db.ChargingSessions.AsNoTracking().FirstOrDefaultAsync(s =>
            s.Id == sessionId && !s.IsDeleted && (accountId == null || s.UserId == null || s.UserId == accountId));
        if (session == null) return Missing();
        var payment = await db.Set<Payment>().AsNoTracking().Where(p => !p.IsDeleted && p.ChargingSessionId == sessionId)
            .OrderByDescending(p => p.CreatedAt).FirstOrDefaultAsync();
        if (SePayConfigured && payment is { PaymentMethod: SePayMethod, Status: "Initiated" } &&
            (accountId == null || payment.PaidBy == accountId) && session.Status == "Completed" &&
            await FindSePayTransfer(payment))
        {
            await DatabaseWork.Write(db, async () =>
            {
                var pending = await db.Set<Payment>().FirstOrDefaultAsync(p =>
                    p.Id == payment.Id && p.ChargingSessionId == sessionId &&
                    p.PaymentMethod == SePayMethod && p.Status == "Initiated" && !p.IsDeleted);
                var active = await db.ChargingSessions.Include(s => s.Connector).FirstOrDefaultAsync(s =>
                    s.Id == sessionId && s.Status == "Completed" && !s.IsDeleted);
                if (pending == null || active == null || pending.Amount != payment.Amount ||
                    pending.TxnRef != payment.TxnRef || await db.Transactions.AnyAsync(t => t.PaymentId == pending.Id))
                    return Fail("Yêu cầu thanh toán đã thay đổi.");
                await Settle(pending, active, "OnlinePayment", "SePay Test Mode confirmation");
                await db.SaveChangesAsync();
                return Ok(pending.Id);
            });
            session = await db.ChargingSessions.AsNoTracking().SingleAsync(s => s.Id == sessionId);
            payment = await db.Set<Payment>().AsNoTracking().SingleAsync(p => p.Id == payment.Id);
        }
        var tax = payment?.TaxRate ?? await TaxRate();
        if (tax == null) return Fail("Máy chủ chưa cấu hình thuế VAT hợp lệ.");
        return Ok(new SessionPaymentDto
        {
            SessionId = session.Id, SessionStatus = session.Status,
            BeforeVatAmount = payment?.BeforeVatAmount ?? session.Cost, TaxRate = tax.Value,
            Amount = payment?.Amount ?? Total(session.Cost, tax.Value),
            Payment = payment?.Adapt<PaymentViewDetailDto>()
        });
    }

    private async Task<bool> FindSePayTransfer(Payment payment)
    {
        var accountId = config["SePay:TestBankAccountId"]!;
        var code = Uri.EscapeDataString(payment.TxnRef);
        var amount = payment.Amount.ToString("0", CultureInfo.InvariantCulture);
        using var request = new HttpRequestMessage(HttpMethod.Get,
            $"https://userapi-sandbox.sepay.vn/v2/transactions?bank_account_id={Uri.EscapeDataString(accountId)}&transaction_content={code}&transfer_type=in&amount_in_min={amount}&amount_in_max={amount}&timestamp_format=iso8601");
        request.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", config["SePay:TestToken"]);
        try
        {
            using var response = await SePayHttp.SendAsync(request);
            if (!response.IsSuccessStatusCode) return false;
            using var payload = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
            if (!payload.RootElement.TryGetProperty("data", out var rows) || rows.ValueKind != JsonValueKind.Array)
                return false;
            var earliest = new DateTimeOffset(payment.CreatedAt).AddSeconds(-1);
            return rows.EnumerateArray().Any(row =>
                row.TryGetProperty("bank_account_id", out var account) &&
                string.Equals(account.ToString(), accountId, StringComparison.OrdinalIgnoreCase) &&
                row.TryGetProperty("transaction_content", out var content) &&
                string.Equals(content.ToString().Trim(), payment.TxnRef, StringComparison.OrdinalIgnoreCase) &&
                row.TryGetProperty("transaction_date", out var date) &&
                DateTimeOffset.TryParse(date.ToString(), CultureInfo.InvariantCulture, DateTimeStyles.None, out var occurred) &&
                occurred >= earliest &&
                row.TryGetProperty("amount_in", out var incoming) &&
                decimal.TryParse(incoming.ToString(), NumberStyles.Number, CultureInfo.InvariantCulture, out var received) &&
                received == payment.Amount &&
                row.TryGetProperty("amount_out", out var outgoing) &&
                decimal.TryParse(outgoing.ToString(), NumberStyles.Number, CultureInfo.InvariantCulture, out var sent) && sent == 0);
        }
        catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException or JsonException)
        {
            return false;
        }
    }

    public Task<IServiceResult> CreateSePayPayment(Guid sessionId, Guid? accountId = null) =>
        Create(sessionId, accountId, false, sePay: true);

    public Task<IServiceResult> CreatePaymentURL(Guid sessionId, Guid? accountId = null) => Create(sessionId, accountId, false);
    public Task<IServiceResult> CreatePaymentOfflineRecord(Guid sessionId, Guid? accountId = null) => Create(sessionId, accountId, true);

    private Task<IServiceResult> Create(Guid sessionId, Guid? accountId, bool offline, bool sePay = false) => DatabaseWork.Write(db, async () =>
    {
        var session = await db.ChargingSessions.Include(s => s.ChargingPost).ThenInclude(p => p.ChargingStationNavigation)
            .FirstOrDefaultAsync(s => s.Id == sessionId && !s.IsDeleted && (accountId == null || s.UserId == null || s.UserId == accountId));
        if (session == null) return Missing();
        if (session.Status != "Completed") return Fail("Chỉ thanh toán phiên đã dừng và chưa thanh toán.");
        if (accountId == null && session.UserId != null)
            accountId = session.UserId;

        // Lost responses must be reconciled by GET, never by issuing another charge.
        if (await db.Set<Payment>().AnyAsync(p => !p.IsDeleted && p.ChargingSessionId == sessionId &&
            (p.Status == "Initiated" || p.Status == "Successed")))
            return Fail("Đã có yêu cầu thanh toán. Hãy kiểm tra trạng thái trước khi tạo lại.");
        var previous = await db.Set<Payment>().AsNoTracking().Where(p => !p.IsDeleted && p.ChargingSessionId == sessionId)
            .OrderByDescending(p => p.CreatedAt).FirstOrDefaultAsync();
        var tax = previous?.TaxRate ?? await TaxRate();
        if (tax == null || session.Cost < 0) return Fail("Hóa đơn hoặc thuế máy chủ chưa hợp lệ.");
        if (sePay && !SePayConfigured) return Fail("SePay Test Mode chưa được cấu hình.");
        if (!offline && !sePay && !GatewayConfigured) return Fail("VNPay chưa được cấu hình trên máy chủ.");
        var beforeVat = previous?.BeforeVatAmount ?? session.Cost;
        var amount = previous?.Amount ?? Total(beforeVat, tax.Value);
        if (!offline && amount <= 0) return Fail("Số tiền không đủ để tạo yêu cầu thanh toán online.");
        var operatorId = session.ChargingPost.ChargingStationNavigation.OperatorId;
        if (offline && (operatorId == null || operatorId == Guid.Empty))
            return Fail("Trạm chưa có nhân viên nhận thanh toán tại quầy.");
        var now = DateTime.Now;
        var payment = new Payment
        {
            Id = Guid.NewGuid(), ChargingSessionId = session.Id, PaidBy = accountId,
            TxnRef = sePay ? "EV" + Guid.NewGuid().ToString("N").ToUpperInvariant() : PaymentHelper.GenerateTxnRef(session.Id), TaxRate = tax.Value,
            BeforeVatAmount = beforeVat, Amount = amount, PaymentMethod = offline ? "OFFLINE" : sePay ? SePayMethod : "VNPaySandbox",
            Status = "Initiated", CreatedAt = now, UpdatedAt = now
        };
        db.Set<Payment>().Add(payment);
        await db.SaveChangesAsync();
        if (offline)
        {
            if (operatorId != null && operatorId != Guid.Empty && accountId != null)
            {
                await notify.NotifyStaffOffLinePaymentRecord(operatorId.Value, accountId.Value,
                    "Có yêu cầu thanh toán tại quầy cho phiên sạc " + session.Id + ". Chỉ xác nhận sau khi nhận tiền.");
                await db.SaveChangesAsync();
            }
            return Ok(payment.Adapt<PaymentViewDetailDto>(), "Đã ghi nhận yêu cầu; đang chờ nhân viên xác nhận, chưa thanh toán.");
        }
        if (sePay)
            return Ok(payment.Adapt<PaymentViewDetailDto>(), "Đang chờ giao dịch mô phỏng từ SePay.");
        var parameters = PaymentHelper.CreateVnPayParameters(config["VnPay:TmnCode"]!,
            checked((long)(payment.Amount * 100)), payment.TxnRef, "Thanh toan phien sac EV",
            config["VnPay:ReturnUrl"]!, "127.0.0.1", "vn");
        return Ok(PaymentHelper.CreateVnPayUrl(config["VnPay:PaymentUrl"]!, parameters, config["VnPay:HashSecret"]!),
            "Đã tạo URL thanh toán; chưa xác nhận thanh toán.");
    });

    public async Task<string> ProcessVNPayIPN(Dictionary<string, string> query)
    {
        // Authenticate the provider before reading or changing money-related records.
        if (!GatewayConfigured || !PaymentHelper.VerifySignature(query, config["VnPay:HashSecret"]!))
            return Json("97", "Invalid signature");
        if (!query.TryGetValue("vnp_TmnCode", out var merchant) || merchant != config["VnPay:TmnCode"] ||
            !query.TryGetValue("vnp_TxnRef", out var reference) ||
            !query.TryGetValue("vnp_ResponseCode", out var responseCode) ||
            !query.TryGetValue("vnp_TransactionStatus", out var providerStatus) ||
            !query.TryGetValue("vnp_Amount", out var amountText) ||
            !long.TryParse(amountText, NumberStyles.None, CultureInfo.InvariantCulture, out var amount))
            return Json("99", "Invalid callback fields");
        var result = await DatabaseWork.Write(db, async () =>
        {
            var payment = await db.Set<Payment>().FirstOrDefaultAsync(p => !p.IsDeleted && p.TxnRef == reference);
            if (payment == null) return Ack("01", "Order not found");
            if (payment.Amount * 100 != amount) return Ack("04", "Invalid amount");
            var session = await db.ChargingSessions.Include(s => s.Connector).FirstOrDefaultAsync(s =>
                s.Id == payment.ChargingSessionId && !s.IsDeleted);
            if (session == null || payment.PaymentMethod != "VNPaySandbox" || (payment.PaidBy != null && session.UserId != null && payment.PaidBy != session.UserId)) return Ack("01", "Order not found");
            if (payment.Status != "Initiated" || session.Status == "Paid" ||
                await db.Transactions.AnyAsync(t => t.PaymentId == payment.Id && t.Status == "Completed"))
                return Ack("02", "Order already confirmed");
            if (session.Status != "Completed") return Ack("99", "Session is not ready for payment");
            payment.BankCode = query.GetValueOrDefault("vnp_BankCode");
            payment.UpdatedAt = DateTime.Now;
            if (responseCode == "00" && providerStatus == "00")
                await Settle(payment, session, "OnlinePayment", "VNPAY Sandbox confirmation");
            else
                payment.Status = responseCode == "24" ? "Cancelled" : "Failed";
            await db.SaveChangesAsync();
            // RspCode acknowledges receipt, not the customer's payment outcome.
            return Ack("00", "Confirm Success");
        });
        return result.Status == Const.SUCCESS_UPDATE_CODE && result.Data != null
            ? JsonSerializer.Serialize(result.Data) : Json("99", "Unable to confirm callback");
    }

    public Task<IServiceResult> UpdatePaymentOfflineRecord(Guid paymentId, Guid userId, decimal receivedAmount) => DatabaseWork.Write(db, async () =>
    {
        var payment = await db.Set<Payment>().FirstOrDefaultAsync(p => !p.IsDeleted && p.Id == paymentId);
        if (payment == null) return Missing();
        var session = await db.ChargingSessions.Include(s => s.Connector).Include(s => s.ChargingPost)
            .ThenInclude(p => p.ChargingStationNavigation).FirstOrDefaultAsync(s => !s.IsDeleted && s.Id == payment.ChargingSessionId);
        if (session == null || session.ChargingPost.ChargingStationNavigation.OperatorId != userId ||
            session.ChargingPost.IsDeleted || session.ChargingPost.ChargingStationNavigation.IsDeleted ||
            !await db.Users.AnyAsync(u => u.Id == userId && !u.IsDeleted && (u.Status == "Active" || u.Status == "Assigned")) ||
            !await (from userRole in db.UserRoles
                    join role in db.Roles on userRole.RoleId equals role.Id
                    where userRole.UserId == userId && role.NormalizedName == "STAFF"
                    select userRole).AnyAsync())
            return Missing();
        if (payment.PaymentMethod != "OFFLINE" || payment.Status != "Initiated" || session.Status != "Completed")
            return Fail("Yêu cầu không ở trạng thái chờ nhân viên xác nhận.");
        if ((payment.PaidBy != null && session.UserId != null && payment.PaidBy != session.UserId) || payment.Amount < 0 || payment.BeforeVatAmount != session.Cost || payment.TaxRate is < 0 or > 100 || payment.Amount != Total(payment.BeforeVatAmount, payment.TaxRate))
            return Fail("Hóa đơn không khớp với phiên sạc.");
        if (receivedAmount != payment.Amount) return Fail("Số tiền thực thu không khớp hóa đơn.");
        if (await db.Transactions.AnyAsync(t => t.PaymentId == payment.Id))
            return Fail("Yêu cầu đã có bút toán.");
        await Settle(payment, session, "OfflinePayment", "Staff confirmed cash received", userId);
        await db.SaveChangesAsync();
        return Ok(payment.Adapt<PaymentViewDetailDto>(), "Đã xác nhận thu tiền.");
    });

    private async Task Settle(Payment payment, ChargingSession session, string type, string note, Guid? recordedBy = null)
    {
        payment.Status = "Successed";
        payment.UpdatedAt = DateTime.Now;
        session.Status = "Paid";
        session.UpdatedAt = DateTime.Now;
        session.Connector.IsLocked = false;
        session.Connector.UpdatedAt = DateTime.Now;
        var driver = await db.EVDrivers.FirstOrDefaultAsync(d => !d.IsDeleted && d.AccountId == session.UserId);
        var points = await db.SystemConfigurations.AsNoTracking().Where(c => !c.IsDeleted && c.Name == "POINT_PER_KWH" &&
            c.EffectedDateFrom <= DateTime.Now && (c.EffectedDateTo == null || c.EffectedDateTo >= DateTime.Now))
            .OrderByDescending(c => c.EffectedDateFrom).FirstOrDefaultAsync();
        if (driver != null && points?.MinValue is >= 0)
        {
            driver.Point += checked((int)((decimal)session.EnergyDeliveredKWh * points.MinValue.Value));
            driver.UpdatedAt = DateTime.Now;
        }
        db.Transactions.Add(new Transaction
        {
            Id = Guid.NewGuid(), PaymentId = payment.Id, PaidBy = payment.PaidBy, RecordedBy = recordedBy, Amount = payment.Amount,
            TransactionType = type, Status = "Completed", Note = note,
            ReferenceCode = PaymentHelper.GenerateReferenceCode(type), InitiatedAt = payment.CreatedAt,
            CompletedAt = DateTime.Now, CreatedAt = DateTime.Now, UpdatedAt = DateTime.Now
        });
    }

    public async Task<IServiceResult> GetList(Guid userId, bool pendingOnly = false) => Ok(await db.Set<Payment>().AsNoTracking()
        .Where(p => !p.IsDeleted && p.ChargingSessionNavigation.ChargingPost.ChargingStationNavigation.OperatorId == userId)
        .Where(p => !pendingOnly || p.PaymentMethod == "OFFLINE" && p.Status == "Initiated" && p.ChargingSessionNavigation.Status == "Completed")
        .OrderByDescending(p => p.CreatedAt).ProjectToType<PaymentViewDetailDto>().ToListAsync());

    public async Task<IServiceResult> GetById(Guid paymentId, Guid? operatorId)
    {
        var payment = await db.Set<Payment>().AsNoTracking().FirstOrDefaultAsync(p => !p.IsDeleted && p.Id == paymentId &&
            (operatorId == null || p.ChargingSessionNavigation.ChargingPost.ChargingStationNavigation.OperatorId == operatorId));
        return payment == null ? Missing() : Ok(payment.Adapt<PaymentViewDetailDto>());
    }

    private static IServiceResult Ack(string code, string message) => Ok(new { RspCode = code, Message = message });
    private static string Json(string code, string message) => JsonSerializer.Serialize(new { RspCode = code, Message = message });
}
