    using BusinessLogic.IServices;
    using Common;
    using Common.DTOs.VoucherDto;
    using Common.Helper;
    using Microsoft.AspNetCore.Authorization;
    using Microsoft.AspNetCore.Mvc;

    namespace APIs.Controllers
    {
    [Route("api/[controller]")]
    [ApiController]
    public class VoucherController : ControllerBase
    {
        private readonly IVoucherService _voucherService;

        public VoucherController(IVoucherService voucherService)
        {
            _voucherService = voucherService;
        }

        // LẤY DANH SÁCH VOUCHER CÒN HIỆU LỰC
        // GET: api/voucher (Admin, Staff, EVDriver)
        [HttpGet]
        [Authorize(Roles = "Admin,Staff,EVDriver")]
        public async Task<IActionResult> GetAvailableVouchers()
        {
            var result = await _voucherService.GetAvailableVouchers();

            if (result.Status == Const.SUCCESS_READ_CODE)
                return Ok(new { data = result.Data, message = result.Message });

            if (result.Status == Const.WARNING_NO_DATA_CODE)
                return NotFound(new { message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }

        // TẠO VOUCHER MỚI
        // POST: api/voucher (Admin, Staff)
        [HttpPost]
        [Authorize(Roles = "Admin,Staff")]
        public async Task<IActionResult> CreateVoucher([FromBody] VoucherCreateDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var result = await _voucherService.CreateVoucher(dto);

            if (result.Status == Const.SUCCESS_CREATE_CODE)
                return Ok(new { data = result.Data, message = result.Message });

            if (result.Status == Const.FAIL_CREATE_CODE)
                return Conflict(new { message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }

        // CẬP NHẬT VOUCHER
        // PUT: api/voucher/{id} (Admin, Staff)
        [HttpPut("{id}")]
        [Authorize(Roles = "Admin,Staff")]
        public async Task<IActionResult> UpdateVoucher([FromRoute] Guid id, [FromBody] VoucherUpdateDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var result = await _voucherService.UpdateVoucher(dto, id);

            if (result.Status == Const.SUCCESS_UPDATE_CODE)
                return Ok(new { data = result.Data, message = result.Message });

            if (result.Status == Const.FAIL_UPDATE_CODE)
                return Conflict(new { message = result.Message });

            if (result.Status == Const.WARNING_NO_DATA_CODE)
                return NotFound(new { message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }

        // Người dùng dùng để đổi voucher 
        // POST: api/voucher/redeem/{voucherId} (EVDriver)
        [HttpPost("redeem/{voucherId}")]
        [Authorize(Roles = "EVDriver")]
        public async Task<IActionResult> RedeemVoucher([FromRoute] Guid voucherId)
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

            var result = await _voucherService.RedeemVoucher(userId, voucherId);

            if (result.Status == Const.SUCCESS_CREATE_CODE)
                return Ok(new { data = result.Data, message = result.Message });

            if (result.Status == Const.FAIL_CREATE_CODE)
                return Conflict(new { message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }
        // USER SỬ DỤNG VOUCHER
        // POST: api/voucher/use/{userVoucherId}/{sessionId} (EVDriver)
        [HttpPost("use/{userVoucherId}/{sessionId}")]
        [Authorize(Roles = "EVDriver")]
        public async Task<IActionResult> UseVoucher([FromRoute] Guid userVoucherId, [FromRoute] Guid sessionId)
        {
            var result = await _voucherService.UseVoucher(userVoucherId, sessionId);

            if (result.Status == Const.SUCCESS_UPDATE_CODE)
                return Ok(new { data = result.Data, message = result.Message });

            if (result.Status == Const.FAIL_UPDATE_CODE)
                return Conflict(new { message = result.Message });

            if (result.Status == Const.WARNING_NO_DATA_CODE)
                return NotFound(new { message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }

        // EXPIRE VOUCHER (chạy thủ công hoặc dành cho job test)
        // PUT: api/voucher/expire/{userVoucherId} (Admin, Staff)
        [HttpPut("expire/{userVoucherId}")]
        [Authorize(Roles = "Admin,Staff")]
        public async Task<IActionResult> ExpireVoucher([FromRoute] Guid userVoucherId)
        {
            var result = await _voucherService.ExpireVoucher(userVoucherId);

            if (result.Status == Const.SUCCESS_UPDATE_CODE)
                return Ok(new { message = result.Message });

            if (result.Status == Const.FAIL_UPDATE_CODE)
                return Conflict(new { message = result.Message });

            if (result.Status == Const.WARNING_NO_DATA_CODE)
                return NotFound(new { message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }
        // ADMIN LẤY TẤT CẢ VOUCHER (kể cả Inactive)
        // GET: api/voucher/admin (Admin, Staff)
        [HttpGet("admin")]
        [Authorize(Roles = "Admin,Staff")]
        public async Task<IActionResult> GetAllVouchersForAdmin()
        {
            var result = await _voucherService.GetAllVouchersForAdmin();

            if (result.Status == Const.SUCCESS_READ_CODE)
                return Ok(new { data = result.Data, message = result.Message });

            if (result.Status == Const.WARNING_NO_DATA_CODE)
                return NotFound(new { message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }


        // EVDRIVER LẤY VOUCHER CỦA MÌNH
        // GET: api/voucher/my (EVDriver)
        [HttpGet("my")]
        [Authorize(Roles = "EVDriver")]
        public async Task<IActionResult> GetMyVouchers()
        {
            Guid userId;
            try
            {
                userId = User.GetUserId(); // lấy từ token
            }
            catch
            {
                return Unauthorized(new { message = "Không xác định được userId từ token." });
            }

            var result = await _voucherService.GetMyVouchers(userId);

            if (result.Status == Const.SUCCESS_READ_CODE)
                return Ok(new { data = result.Data, message = result.Message });

            if (result.Status == Const.WARNING_NO_DATA_CODE)
                return NotFound(new { message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }

        // XOÁ VOUCHER (soft delete)
        // DELETE: api/voucher/{id} (Admin, Staff)
        [HttpDelete("{id}")]
                [Authorize(Roles = "Admin,Staff")]
                public async Task<IActionResult> DeleteVoucher([FromRoute] Guid id)
                {
                    var result = await _voucherService.DeleteVoucher(id);

                    if (result.Status == Const.SUCCESS_DELETE_CODE)
                        return Ok(new { message = result.Message });

                    if (result.Status == Const.FAIL_DELETE_CODE)
                        return Conflict(new { message = result.Message });

                    if (result.Status == Const.WARNING_NO_DATA_CODE)
                        return NotFound(new { message = result.Message });

                    return StatusCode(500, new { message = result.Message });
                }
    }
    }
