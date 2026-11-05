using System.Text.Json;
using System.Globalization;
using BusinessLogic.Base;
using BusinessLogic.IServices;
using Common;
using Common.Helper;
using Common.DTOs.PaymentDto;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.DataProtection;
using System.Security.Cryptography;

namespace APIs.Controllers;

[ApiController]
[Route("api/[controller]")]
public class PaymentController(IPaymentService service, IDataProtectionProvider protection) : ControllerBase
{
    [HttpPost("sepay-sandbox")]
    [Authorize(Roles = "EVDriver")]
    public async Task<IActionResult> CreateSandbox([FromQuery] Guid sessionId) =>
        Result(await service.CreateSandboxPayment(sessionId, User.GetUserId()));

    [HttpGet("sepay-sandbox/link/{sessionId:guid}")]
    [Authorize(Roles = "EVDriver")]
    public async Task<IActionResult> SandboxLink(Guid sessionId)
    {
        var owner = User.GetUserId();
        if (await service.GetSandboxForm(sessionId, owner) == null) return NotFound();
        var ticket = protection.CreateProtector("EVCSMS.SePaySandbox.Checkout.v1").Protect(
            $"{sessionId}|{owner}|{DateTimeOffset.UtcNow.AddMinutes(15).ToUnixTimeSeconds()}");
        // Relative URL lets the app retain its reachable emulator/LAN API host.
        return Ok(new { data = "Payment/sepay-sandbox/checkout?ticket=" + Uri.EscapeDataString(ticket) });
    }

    [AllowAnonymous]
    [HttpGet("sepay-sandbox/checkout")]
    public async Task<IActionResult> SandboxCheckout([FromQuery] string ticket)
    {
        Response.Headers.CacheControl = "no-store";
        Response.Headers["Referrer-Policy"] = "no-referrer";
        try
        {
            var parts = protection.CreateProtector("EVCSMS.SePaySandbox.Checkout.v1").Unprotect(ticket).Split('|');
            if (parts.Length != 3 || !Guid.TryParse(parts[0], out var session) ||
                !Guid.TryParse(parts[1], out var owner) || !long.TryParse(parts[2], out var expires) ||
                expires <= DateTimeOffset.UtcNow.ToUnixTimeSeconds()) return BadRequest();
            var html = await service.GetSandboxForm(session, owner);
            return html == null ? NotFound() : Content(html, "text/html; charset=utf-8");
        }
        catch (CryptographicException) { return BadRequest(); }
    }
    [HttpGet("methods")]
    [AllowAnonymous]
    public IActionResult Methods() => Result(service.GetMethods());

    [HttpGet("session/{sessionId:guid}")]
    [AllowAnonymous]
    public async Task<IActionResult> SessionPayment(Guid sessionId) => Result(await service.GetSessionPayment(sessionId, User.TryGetUserId()));

    [HttpPost]
    [AllowAnonymous]
    public async Task<IActionResult> CreatePaymentURL([FromQuery] Guid sessionId) => Result(await service.CreatePaymentURL(sessionId, User.TryGetUserId()));

    [HttpPost("sepay-test")]
    [AllowAnonymous]
    public async Task<IActionResult> CreateSePayPayment([FromQuery] Guid sessionId) =>
        Result(await service.CreateSePayPayment(sessionId, User.TryGetUserId()));

    [HttpPost("sepay-test/confirm")]
    [AllowAnonymous]
    public async Task<IActionResult> ConfirmSePayPayment([FromQuery] Guid sessionId) =>
        Result(await service.ConfirmSePayPayment(sessionId, User.TryGetUserId()));

    [HttpPost("sepay/webhook")]
    [AllowAnonymous]
    public async Task<IActionResult> SePayWebhook([FromBody] JsonElement payload)
    {
        string content = "";
        decimal amount = 0;
        if (payload.TryGetProperty("transactionContent", out var cProp) ||
            payload.TryGetProperty("content", out cProp))
            content = cProp.GetString() ?? "";

        if (payload.TryGetProperty("amountIn", out var aProp) ||
            payload.TryGetProperty("transferAmount", out aProp))
            decimal.TryParse(aProp.ToString(), NumberStyles.Number, CultureInfo.InvariantCulture, out amount);

        return Result(await service.ProcessSePayWebhook(content, amount));
    }

    [HttpPost("offline")]
    [AllowAnonymous]
    public async Task<IActionResult> CreatePaymentOfflineRecord([FromQuery] Guid sessionId) => Result(await service.CreatePaymentOfflineRecord(sessionId, User.TryGetUserId()));

    [HttpPatch("offline-status")]
    [Authorize(Roles = "Staff")]
    public async Task<IActionResult> UpdatePaymentOfflineRecord([FromQuery] Guid paymentId, [FromBody] ConfirmCashPaymentDto request) =>
        Result(await service.UpdatePaymentOfflineRecord(paymentId, User.GetUserId(), request.ReceivedAmount!.Value));

    [HttpGet("vnpay/ipn")]
    [AllowAnonymous]
    public async Task<IActionResult> VNPayIPN()
    {
        if (Request.Query.Any(parameter => parameter.Value.Count != 1))
            return Content("{\"RspCode\":\"99\",\"Message\":\"Duplicate callback fields\"}", "application/json");

        var query = Request.Query.ToDictionary(q => q.Key, q => q.Value.ToString());
        return Content(await service.ProcessVNPayIPN(query), "application/json");
    }

    [HttpGet("vnpay/return")]
    [AllowAnonymous]
    public IActionResult VNPayReturn() => Content(
        "<!doctype html><html lang=\"vi\"><meta charset=\"utf-8\"><title>EV Charging</title>" +
        "<body><h1>Kiểm tra kết quả trong ứng dụng EV Charging</h1>" +
        "<p>Vui lòng quay lại ứng dụng và chọn Kiểm tra trạng thái. Chỉ trạng thái được máy chủ xác nhận mới là kết quả thanh toán.</p></body></html>",
        "text/html; charset=utf-8");

    [HttpGet("{paymentId:guid}")]
    [Authorize(Roles = "Admin,Staff")]
    public async Task<IActionResult> GetById(Guid paymentId) => Result(await service.GetById(paymentId, User.IsInRole("Admin") ? null : User.GetUserId()));

    [HttpGet]
    [Authorize(Roles = "Admin,Staff")]
    public async Task<IActionResult> GetList([FromQuery] bool pendingOnly = false) => Result(await service.GetList(User.GetUserId(), pendingOnly));

    private IActionResult Result(IServiceResult result)
    {
        if (result.Status == Const.SUCCESS_READ_CODE) return Ok(new { data = result.Data, message = result.Message });
        if (result.Status == Const.WARNING_NO_DATA_CODE) return NotFound(new { message = result.Message });
        if (result.Status == Const.FAIL_CREATE_CODE || result.Status == Const.ERROR_VALIDATION_CODE) return Conflict(new { message = result.Message });
        return StatusCode(500, new { message = result.Message });
    }
}
