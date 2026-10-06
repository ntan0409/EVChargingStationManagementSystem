using BusinessLogic.IServices;
using Common;
using Common.DTOs.ConnectorDto;
using Common.Enum.Connector;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace APIs.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ConnectorController(IConnectorService service) : ControllerBase
    {
        private readonly IConnectorService _service = service;

        [HttpGet]
        public async Task<IActionResult> GetList(Guid chargingPostId)
        {
            var result = await _service.GetList(chargingPostId);

            if (result.Status == Const.SUCCESS_READ_CODE)
                return Ok(new { data = result.Data, message = result.Message });

            if (result.Status == Const.WARNING_NO_DATA_CODE)
                return NotFound(new { message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }

        [HttpGet("{connectorId}")]
        public async Task<IActionResult> GetById([FromRoute] Guid connectorId)
        {
            var result = await _service.GetById(connectorId);

            if (result.Status == Const.SUCCESS_READ_CODE)
                return Ok(new { data = result.Data, message = result.Message });

            if (result.Status == Const.WARNING_NO_DATA_CODE)
                return NotFound(new { message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Create([FromBody] ConnectorCreateDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var result = await _service.Create(dto);

            if (result.Status == Const.SUCCESS_CREATE_CODE && result.Data is ConnectorViewListDto createdDto)
                return CreatedAtAction(nameof(GetById), new { connectorId = createdDto.Id },
                        new { data = result.Data, message = result.Message });

            if (result.Status == Const.FAIL_CREATE_CODE)
                return Conflict(new { message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }

        [HttpPut]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Update([FromBody] ConnectorUpdateDto dto, Guid connectorId)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var result = await _service.Update(dto, connectorId);

            if (result.Status == Const.SUCCESS_UPDATE_CODE)
                return Ok(new { data = result.Data, message = result.Message });

            if (result.Status == Const.WARNING_NO_DATA_CODE)
                return NotFound(new { message = result.Message });

            if (result.Status == Const.FAIL_UPDATE_CODE)
                return Conflict(new { message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }

        //[HttpPatch("status")]
        //[Authorize(Roles = "Admin, Staff")]
        //public async Task<IActionResult> UpdateStatus([FromQuery] ConnectorUpdateStatus status, Guid connectorId)
        //{
        //    var result = await _service.UpdateStatus(status, connectorId);

        //    if (result.Status == Const.SUCCESS_UPDATE_CODE)
        //        return Ok(new { data = result.Data, message = result.Message });

        //    if (result.Status == Const.WARNING_NO_DATA_CODE)
        //        return NotFound(new { message = result.Message });

        //    if (result.Status == Const.FAIL_UPDATE_CODE)
        //        return Conflict(new { message = result.Message });

        //    return StatusCode(500, new { message = result.Message });
        //}

        [HttpPatch("connector-toggle")]
        public async Task<IActionResult> UpdateConnectorCount(bool toggle, Guid connectorId)
        {
            var result = await _service.UpdateConnectorCount(toggle, connectorId);

            if (result.Status == Const.SUCCESS_UPDATE_CODE)
                return Ok(new { data = result.Data, message = result.Message });

            if (result.Status == Const.WARNING_NO_DATA_CODE)
                return NotFound(new { message = result.Message });

            if (result.Status == Const.FAIL_UPDATE_CODE)
                return Conflict(new { message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }

        [HttpDelete]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Delete(Guid connectorId)
        {
            var result = await _service.Delete(connectorId);

            if (result.Status == Const.SUCCESS_DELETE_CODE)
                return NoContent();

            if (result.Status == Const.WARNING_NO_DATA_CODE)
                return NotFound(new { message = result.Message });

            if (result.Status == Const.FAIL_DELETE_CODE)
                return Conflict(new { message = result.Message });

            return StatusCode(500, new { message = result.Message });
        }
    }
}
