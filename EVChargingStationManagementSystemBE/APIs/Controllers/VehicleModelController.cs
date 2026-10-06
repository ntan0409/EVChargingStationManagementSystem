using BusinessLogic.IServices;
using Common;
using Common.DTOs.VehicleModelDto;
using Common.Enum.VehicleModel;
using Common.Helper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace APIs.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class VehicleModelController(IVehicleModelService service) : ControllerBase
    {
        private readonly IVehicleModelService _service = service;

        [HttpGet]
        public async Task<IActionResult> GetList()
        {
            var result = await _service.GetList();

            if (result.Status == Const.WARNING_NO_DATA_CODE)
                return NotFound(new { message = result.Message });

            if (result.Status == Const.SUCCESS_READ_CODE)
                return Ok(new { data = result.Data, message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }

        [HttpGet("{vehicleModelId}")]
        public async Task<IActionResult> GetBydId(Guid vehicleModelId)
        {
            var result = await _service.GetById(vehicleModelId);

            if (result.Status == Const.WARNING_NO_DATA_CODE)
                return NotFound(new { message = result.Message });

            if (result.Status == Const.SUCCESS_READ_CODE)
                return Ok(new { data = result.Data, message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Create([FromBody] VehicleModelCreateDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);
            Guid userId;
            try
            {
                userId = User.GetUserId();
            }
            catch
            {
                return Unauthorized(new { message = "Không xác định được userId từ token." });
            }

            var result = await _service.Create(dto, userId);

            if (result.Status == Const.FAIL_CREATE_CODE)
                return Conflict(new { message = result.Message });

            if (result.Status == Const.SUCCESS_CREATE_CODE && result.Data is VehicleModelViewDetailDto viewDto)
                return CreatedAtAction(nameof(GetBydId), new { vehicleModelId = viewDto.Id },
                        new { data = result.Data, message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }

        [HttpPut()]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Update([FromBody] VehicleModelUpdateDto dto, Guid vehicleModelId)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var result = await _service.Update(dto, vehicleModelId);

            if (result.Status == Const.WARNING_NO_DATA_CODE)
                return NotFound(new { message = result.Message });

            if (result.Status == Const.FAIL_UPDATE_CODE)
                return Conflict(new { message = result.Message });

            if (result.Status == Const.SUCCESS_UPDATE_CODE)
                return Ok(new { data = result.Data, message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }

        [HttpPatch("status")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> UpdateStatus(VehicleModelStatus status, Guid vehicleModelId)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var result = await _service.UpdateStatus(status, vehicleModelId);

            if (result.Status == Const.WARNING_NO_DATA_CODE)
                return NotFound(new { message = result.Message });

            if (result.Status == Const.FAIL_UPDATE_CODE)
                return Conflict(new { message = result.Message });

            if (result.Status == Const.SUCCESS_UPDATE_CODE)
                return Ok(new { data = result.Data, message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }

        [HttpDelete()]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Delete(Guid vehicleModelId)
        {
            var result = await _service.Delete(vehicleModelId);

            if (result.Status == Const.WARNING_NO_DATA_CODE)
                return NotFound(new { message = result.Message });

            if (result.Status == Const.FAIL_DELETE_CODE)
                return Conflict(new { message = result.Message });

            if (result.Status == Const.SUCCESS_DELETE_CODE)
                return NoContent();

            return StatusCode(500, new { message = result.Message });
        }
    }
}
