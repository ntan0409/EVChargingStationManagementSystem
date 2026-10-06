using BusinessLogic.IServices;
using Common;
using Common.DTOs.AuthDto;
using Common.Helper;
using Microsoft.AspNetCore.Mvc;

namespace APIs.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController(IAuthService authService) : ControllerBase
    {
        private readonly IAuthService _authService = authService;

        [HttpPost("register")]
        public async Task<IActionResult> Register(RegisterAccountDto dto)
        {

            var result = await _authService.RegisterAccount(dto);

            if (result.Status == Const.FAIL_CREATE_CODE)
            {
                return BadRequest(new { result.Message });
            }

            return Ok(new { result.Message });
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginDto dto)
        {
            var result = await _authService.Login(dto);

            if (result.Status == Const.FAIL_READ_CODE)
            {
                return BadRequest(result.Message);
            }

            return Ok(result.Data);
        }

        [HttpPost("login-google")]
        public async Task<IActionResult> LoginWithGoogle([FromBody] GoogleLoginDto dto)
        {
            var result = await _authService.LoginWithGoogleAsync(dto.IdToken);

            if (result.Status == Const.FAIL_READ_CODE || result.Status == Const.FAIL_CREATE_CODE)
                return BadRequest(result.Message);

            return Ok(result.Data);
        }

        [HttpPatch("confirm-email")]
        public async Task<IActionResult> ConfirmEmail(ConfirmEmailDto dto)
        {
            var result = await _authService.ConfirmEmail(dto);

            if (result.Status == Const.FAIL_VERIFY_OTP_CODE)
                return Conflict(new {message = result.Message, errors = result.Data });

            if (result.Status == Const.WARNING_NO_DATA_CODE)
                return NotFound(new { message = result.Message });

            return Ok(new { message = result.Message });
        }

        [HttpPost("resend-confirm-email")]
        public async Task<IActionResult> ResendConfirmEmail(string Email)
        {
            var result = await _authService.ResendConfirmEmail(Email);

            if (result.Status == Const.WARNING_NO_DATA_CODE)
                return NotFound(new { message = result.Message });

            if (result.Status == Const.FAIL_UPDATE_CODE)
                return BadRequest(new { message = result.Message, errors = result.Data });
            return Ok(new { message = result.Message });
        }

        [HttpPost("forgot-password")]
        public async Task<IActionResult> ForgotPassword(string Email)
        {
            var result = await _authService.ForgotPassword(Email);

            if (result.Status == Const.WARNING_NO_DATA_CODE)
                return NotFound(new { message = result.Message });

            return Ok(new { message = result.Message });
        }

        [HttpPost("reset-password")]
        public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordDto dto)
        {
            var result = await _authService.ResetPassword(dto);

            if (result.Status == Const.WARNING_NO_DATA_CODE)
                return NotFound(new { message = result.Message });

            if (result.Status == Const.FAIL_RESET_PASSWORD_CODE)
                return BadRequest(new { message = result.Message, errors = result.Data });

            return Ok(new { message = result.Message });
        }

        [HttpPost("change-password")]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordDto dto)
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

            var result = await _authService.ChangePassword(dto, userId);

            if (result.Status == Const.WARNING_NO_DATA_CODE)
                return NotFound(new { message = result.Message });

            if (result.Status == Const.FAIL_UPDATE_CODE)
                return BadRequest(new { message = result.Message, errors = result.Data });

            return Ok(new { message = result.Message });
        }

    }
}
