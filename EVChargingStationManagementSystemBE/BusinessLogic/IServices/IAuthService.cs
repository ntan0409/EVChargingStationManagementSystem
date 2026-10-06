using BusinessLogic.Base;
using Common.DTOs.AuthDto;

namespace BusinessLogic.IServices
{
    public interface IAuthService
    {
        Task<IServiceResult> RegisterAccount(RegisterAccountDto request);
        Task<IServiceResult> Login(LoginDto dto);
        Task<IServiceResult> LoginWithGoogleAsync(string idToken);
        Task<IServiceResult> ConfirmEmail(ConfirmEmailDto dto);
        Task<IServiceResult> ResendConfirmEmail(string email);
        Task<IServiceResult> ForgotPassword(string email);
        Task<IServiceResult> ResetPassword(ResetPasswordDto dto);
        Task<IServiceResult> ChangePassword(ChangePasswordDto dto, Guid userId);
    }
}
