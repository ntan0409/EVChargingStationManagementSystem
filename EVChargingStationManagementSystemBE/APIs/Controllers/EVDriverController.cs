
using BusinessLogic.IServices;
using Common;
using Common.DTOs.ProfileEVDriverDto;
using Common.Helper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using BusinessLogic.Services;

namespace APIs.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class EVDriverController : ControllerBase
    {
        private readonly IEVDriverService _evDriverService;
        [HttpGet("eligibility")]
        [Authorize(Roles = "EVDriver")]
        public async Task<IActionResult> Eligibility([FromServices] DriverJourneyService journey)
        {
            var state = await journey.GetState(User.GetUserId());
            return state == null ? NotFound(new { message = "Không tìm thấy hồ sơ tài xế." }) : Ok(new { data = state });
        }

        public EVDriverController(IEVDriverService evDriverService)
        {
            _evDriverService = evDriverService;
        }

        //  GET: api/evdriver/all (Admin)
        [HttpGet("all")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> GetAll()
        {
            var result = await _evDriverService.GetAll();

            if (result.Status == Const.SUCCESS_READ_CODE)
                return Ok(new { data = result.Data, message = result.Message });

            if (result.Status == Const.WARNING_NO_DATA_CODE)
                return NotFound(new { message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }

        //  GET: api/evdriver/{driverId} (Driver hoặc Admin)
        [HttpGet("{driverId}")]
        [Authorize(Roles = "Admin,EVDriver")]
        public async Task<IActionResult> GetById([FromRoute] Guid driverId)
        {
            if (!User.IsInRole("Admin"))
            {
                var own = await _evDriverService.GetMyProfile(User.GetUserId());
                if (own.Data is not EVDriverViewDto profile || profile.Id != driverId) return Forbid();
            }
            var result = await _evDriverService.GetById(driverId);

            if (result.Status == Const.SUCCESS_READ_CODE)
                return Ok(new { data = result.Data, message = result.Message });

            if (result.Status == Const.WARNING_NO_DATA_CODE)
                return NotFound(new { message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }

        [HttpGet("account/{accountId}")]
        [Authorize(Roles = "Admin,EVDriver")]
        public async Task<IActionResult> GetByAccountId(Guid accountId)
        {
            if (!User.IsInRole("Admin") && User.GetUserId() != accountId) return Forbid();
            var result = await _evDriverService.GetByAccountId(accountId);

            if (result.Status == Const.FAIL_READ_CODE)
                return NotFound(new { message = result.Message });

            if (result.Status == Const.SUCCESS_READ_CODE)
                return Ok(new { data = result.Data, message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }


        //  PUT: api/evdriver/update (Driver tự cập nhật)
        [HttpPut("update")]
        [Authorize(Roles = "EVDriver")]
        public async Task<IActionResult> UpdateProfile([FromBody] EVDriverUpdateSelfDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            // Garage changes used by charging must belong to the authenticated driver.
            var ownProfile = await _evDriverService.GetMyProfile(User.GetUserId());
            if (ownProfile.Data is not EVDriverViewDto profile || profile.Id != dto.DriverId)
                return Forbid();

            var result = await _evDriverService.UpdateProfile(dto);

            if (result.Status == Const.SUCCESS_UPDATE_CODE)
                return Ok(new { data = result.Data, message = result.Message });

            if (result.Status == Const.FAIL_UPDATE_CODE)
                return Conflict(new { message = result.Message });

            if (result.Status == Const.WARNING_NO_DATA_CODE)
                return NotFound(new { message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }

        //  PATCH: api/evdriver/{driverId}/status (Admin)
        [HttpPatch("{driverId}/status")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> UpdateStatus([FromRoute] Guid driverId, [FromBody] EVDriverUpdateStatusDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            // gọi service với cả driverId và dto
            var result = await _evDriverService.UpdateStatus(driverId, dto);

            if (result.Status == Const.SUCCESS_UPDATE_CODE)
                return Ok(new { data = result.Data, message = result.Message });

            if (result.Status == Const.FAIL_UPDATE_CODE)
                return Conflict(new { message = result.Message });

            if (result.Status == Const.WARNING_NO_DATA_CODE)
                return NotFound(new { message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }


        //  DELETE: api/evdriver/{driverId} (Admin)
        [HttpDelete("{driverId}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Delete([FromRoute] Guid driverId)
        {
            var result = await _evDriverService.Delete(driverId);

            if (result.Status == Const.SUCCESS_DELETE_CODE)
                return NoContent();

            if (result.Status == Const.FAIL_DELETE_CODE)
                return Conflict(new { message = result.Message });

            if (result.Status == Const.WARNING_NO_DATA_CODE)
                return NotFound(new { message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }
        [HttpGet("profile")]
        [Authorize(Roles = "EVDriver")]
        public async Task<IActionResult> GetMyProfile()
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

            var result = await _evDriverService.GetMyProfile(userId);

            if (result.Status == Const.SUCCESS_READ_CODE)
                return Ok(new { data = result.Data, message = result.Message });

            if (result.Status == Const.WARNING_NO_DATA_CODE)
                return NotFound(new { message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }

        //  DELETE: api/evdriver/vehicle/{vehicleModelId} (EVDriver)
        [HttpDelete("vehicle/{vehicleModelId}")]
        [Authorize(Roles = "EVDriver")]
        public async Task<IActionResult> DeleteMyVehicle([FromRoute] Guid vehicleModelId)
        {
            Guid accountId;

            try
            {
                // Lấy accountId từ token (claim)
                accountId = User.GetUserId();
            }
            catch
            {
                return Unauthorized(new { message = "Không xác định được userId từ token." });
            }

            var result = await _evDriverService.DeleteMyVehicle(accountId, vehicleModelId);

            if (result.Status == Const.SUCCESS_DELETE_CODE)
                return Ok(new { message = result.Message });

            if (result.Status == Const.WARNING_NO_DATA_CODE)
                return NotFound(new { message = result.Message });

            if (result.Status == Const.FAIL_DELETE_CODE)
                return Conflict(new { message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }

    }
}





