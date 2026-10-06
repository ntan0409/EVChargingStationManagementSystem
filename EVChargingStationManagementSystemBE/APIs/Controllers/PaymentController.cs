using BusinessLogic.IServices;
using Common;
using Common.Helper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Text.Json;

namespace APIs.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class PaymentController(IPaymentService service, IConfiguration config) : ControllerBase
    {
        private readonly IPaymentService _service = service;
        private readonly IConfiguration _config = config;

        [HttpPost]
        public async Task<IActionResult> CreatePaymentURL(Guid sessionId)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var result = await _service.CreatePaymentURL(sessionId);

            if (result.Status == Const.SUCCESS_CREATE_CODE)
                return Ok(new { data = result.Data, message = result.Message });

            //if (result.Status == Const.SUCCESS_CREATE_CODE && result.Data is string url)
            //    return Redirect(url);

            if (result.Status == Const.FAIL_CREATE_CODE)
                return Conflict(new { message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }

        [HttpGet("vnpay/ipn")]
        public async Task<IActionResult> VNPayIPN()
        {
            var queryParams = HttpContext.Request.Query.ToDictionary(q => q.Key, q => q.Value.ToString());
            var response = await _service.ProcessVNPayIPN(queryParams);

            var rsp = JsonSerializer.Deserialize<Dictionary<string, string>>(response);
            var rspCode = rsp.ContainsKey("RspCode") ? rsp["RspCode"] : "99";

            string feBaseUrl = _config["VnPay:FEPaymentResultPage"]; 
            string redirectUrl;

            //FE mở comment nhưng dòng này lên sau khi đã implement trang kết quả thanh toán 
            switch (rspCode)
            {
                case "00":
                    redirectUrl = $"{feBaseUrl}/success";
                    break;
                case "02":
                    redirectUrl = $"{feBaseUrl}/failed";
                    break;
                case "97":
                    redirectUrl = $"{feBaseUrl}/invalid";
                    break;
                default:
                    redirectUrl = $"{feBaseUrl}/error";
                    break;
            }
            return Redirect(redirectUrl);

            //Dòng return dưới này là để tạm thời, comment lại sau khi FE đã implement trang kết quả thanh toán
            //return Content(response, "application/json");
        }

        [HttpPost("offline")]
        public async Task<IActionResult> CreatePaymentOfflineRecord(Guid sessionId)
        {
            var result = await _service.CreatePaymentOfflineRecord(sessionId);

            if (result.Status == Const.SUCCESS_CREATE_CODE)
                return Ok(new { message = result.Message });

            if (result.Status == Const.FAIL_CREATE_CODE)
                return Conflict(new { message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }

        [HttpPatch("offline-status")]
        [Authorize(Roles = "Staff")]
        public async Task<IActionResult> UpdatePaymentOfflineRecord(Guid paymentId)
        {
            Guid userId;
            try
            {
                userId = User.GetUserId();
            }
            catch
            {
                return Unauthorized(new { message = "Không xác định được userId từ token." });
            }

            var result = await _service.UpdatePaymentOfflineRecord(paymentId, userId);

            if (result.Status == Const.SUCCESS_UPDATE_CODE)
                return Ok(new { data = result.Data, message = result.Message });

            if (result.Status == Const.WARNING_NO_DATA_CODE)
                return NotFound(new { message = result.Message });

            if (result.Status == Const.FAIL_UPDATE_CODE)
                return Conflict(new { message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }

        [HttpGet("{paymentId}")]
        [Authorize(Roles = "Admin, Staff")]
        public async Task<IActionResult> GetById([FromRoute] Guid paymentId)
        {
            var result = await _service.GetById(paymentId);

            if (result.Status == Const.SUCCESS_READ_CODE)
                return Ok(new { data = result.Data, message = result.Message });

            if (result.Status == Const.WARNING_NO_DATA_CODE)
                return NotFound(new { message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }

        [HttpGet]
        [Authorize(Roles = "Admin, Staff")]
        public async Task<IActionResult> GetList()
        {
            Guid userId;
            try
            {
                userId = User.GetUserId();
            }
            catch
            {
                return Unauthorized(new { message = "Không xác định được userId từ token." });
            }
            var result = await _service.GetList(userId);

            if (result.Status == Const.SUCCESS_READ_CODE)
                return Ok(new { data = result.Data, message = result.Message });

            if (result.Status == Const.WARNING_NO_DATA_CODE)
                return NotFound(new { message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }
    }
}
