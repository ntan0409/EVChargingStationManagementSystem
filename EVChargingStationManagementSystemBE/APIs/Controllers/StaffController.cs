using BusinessLogic.IServices;
using Common;
using Common.DTOs.ProfileStaffDto;
using Common.Helper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace APIs.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class StaffController(ISCStaffService service) : ControllerBase
    {
        private readonly ISCStaffService _service = service;

        //  [GET] api/staff
        [HttpGet]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> GetAll()
        {
            var result = await _service.GetAll();

            if (result.Status == Const.FAIL_READ_CODE || result.Status == Const.WARNING_NO_DATA_CODE)
                return NotFound(new { message = result.Message });

            if (result.Status == Const.SUCCESS_READ_CODE)
                return Ok(new { data = result.Data, message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }

        [HttpGet("staff-accounts")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> GetAllStaffAccount()
        {
            var result = await _service.GetAllStaffAccount();

            if (result.Status == Const.SUCCESS_READ_CODE)
                return Ok(new { data = result.Data, message = result.Message });

            if (result.Status == Const.WARNING_NO_DATA_CODE)
                return NotFound(new { message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }

        //  [GET] api/staff/{staffId}
        [HttpGet("{staffId}")]
        [Authorize(Roles = "Admin,Staff")]
        public async Task<IActionResult> GetById(Guid staffId)
        {
            var result = await _service.GetById(staffId);

            if (result.Status == Const.FAIL_READ_CODE)
                return NotFound(new { message = result.Message });

            if (result.Status == Const.SUCCESS_READ_CODE)
                return Ok(new { data = result.Data, message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }

        //  [POST] api/staff/account
        [HttpPost("account")]
       [Authorize(Roles = "Admin")]
        public async Task<IActionResult> CreateAccount([FromBody] StaffAccountCreateDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var result = await _service.CreateAccountForStaff(dto);

            if (result.Status == Const.FAIL_CREATE_CODE)
                return Conflict(new { message = result.Message });

            if (result.Status == Const.SUCCESS_CREATE_CODE && result.Data is StaffViewDto viewDto)
                return CreatedAtAction(nameof(GetById), new { staffId = viewDto.Id },
                        new { data = result.Data, message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }

    
        //  [PUT] api/staff/update/admin
        [HttpPut("update/admin")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> UpdateByAdmin([FromBody] StaffUpdateAdminDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var result = await _service.UpdateProfileByAdmin(dto);

            if (result.Status == Const.FAIL_READ_CODE)
                return NotFound(new { message = result.Message });

            if (result.Status == Const.FAIL_UPDATE_CODE)
                return Conflict(new { message = result.Message });

            if (result.Status == Const.SUCCESS_UPDATE_CODE)
                return Ok(new { data = result.Data, message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }

        //  [PUT] api/staff/update/self
        [HttpPut("update/self")]
        [Authorize(Roles = "Staff")]
        public async Task<IActionResult> UpdateByStaff([FromBody] StaffUpdateDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var result = await _service.UpdateProfileByStaff(dto);

            if (result.Status == Const.FAIL_READ_CODE)
                return NotFound(new { message = result.Message });

            if (result.Status == Const.FAIL_UPDATE_CODE)
                return Conflict(new { message = result.Message });

            if (result.Status == Const.SUCCESS_UPDATE_CODE)
                return Ok(new { data = result.Data, message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }

        //  [PATCH] api/staff/status
        [HttpPatch("status")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> UpdateStatus([FromBody] StaffUpdateStatusDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var result = await _service.UpdateStaffStatus(dto);

            if (result.Status == Const.FAIL_READ_CODE)
                return NotFound(new { message = result.Message });

            if (result.Status == Const.FAIL_UPDATE_CODE)
                return Conflict(new { message = result.Message });

            if (result.Status == Const.SUCCESS_UPDATE_CODE)
                return Ok(new { data = result.Data, message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }

        //  [DELETE] api/staff
        [HttpDelete]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Delete(Guid staffId)
        {
            var result = await _service.Delete(staffId);

            if (result.Status == Const.FAIL_READ_CODE)
                return NotFound(new { message = result.Message });

            if (result.Status == Const.FAIL_DELETE_CODE)
                return Conflict(new { message = result.Message });

            if (result.Status == Const.SUCCESS_DELETE_CODE)
                return NoContent();

            return StatusCode(500, new { message = result.Message });
        }
        [HttpGet("profile")]
        [Authorize(Roles = "Admin,Staff")]
        public async Task<IActionResult> GetMyProfile()
        {
            Guid accountId;

            try
            {
                accountId = User.GetUserId();
            }
            catch
            {
                return Unauthorized(new { message = "Không xác định được userId từ token." });
            }

            var result = await _service.GetByAccountId(accountId);

            if (result.Status == Const.WARNING_NO_DATA_CODE)
                return NotFound(new { message = result.Message });

            return Ok(new { data = result.Data, message = result.Message });
        }

    }
}
