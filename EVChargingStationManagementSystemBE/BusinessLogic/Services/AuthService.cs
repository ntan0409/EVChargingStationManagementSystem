using BusinessLogic.Base;
using BusinessLogic.IServices;
using Common;
using Common.DTOs.AuthDto;
using Google.Apis.Auth;
using Infrastructure.IUnitOfWork;
using Infrastructure.Models;
using Mapster;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using System.Web;

namespace BusinessLogic.Services
{
    public class AuthService(UserManager<UserAccount> userManager, SignInManager<UserAccount> signInManager, IConfiguration configuration, IEmailService emailService, IUnitOfWork unitOfWork) : IAuthService
    {
        private readonly UserManager<UserAccount> _userManager = userManager;
        private readonly SignInManager<UserAccount> _signInManager = signInManager;
        private readonly IConfiguration _configuration = configuration;
        private readonly IEmailService _emailSender = emailService;
        private readonly IUnitOfWork _unitOfWork = unitOfWork;
        public async Task<IServiceResult> RegisterAccount(RegisterAccountDto dto)
        {
            var phoneExists = await _unitOfWork.UserAccountRepository.GetQueryable()
            .AsNoTracking()
            .AnyAsync(u => !u.IsDeleted && u.PhoneNumber == dto.Phone);

            if (phoneExists)
                return new ServiceResult(Const.FAIL_CREATE_CODE, "Số điện thoại của bạn đã được đăng ký");
            var user = new UserAccount();
            dto.Adapt(user);
            user.RegistrationDate = DateTime.UtcNow;
            user.Status = "Active";
            user.CreatedAt = DateTime.UtcNow;
            user.UpdatedAt = DateTime.UtcNow;

            var result = await _userManager.CreateAsync(user, dto.Password);

            // Sau khi tạo tài khoản thành công thì tạo profile cho EVDriver
            if (result.Succeeded)
            {
                //var createdUser = await _unitOfWork.UserAccountRepository.GetByIdAsync(user.Id);
                var createdUser = await unitOfWork.UserAccountRepository.GetQueryable()
                    .AsNoTracking().Where(u => u.Id == user.Id).FirstOrDefaultAsync();
                if (createdUser == null)
                    return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy tài khoản", result.Errors);

                EVDriverProfile eVDriver = new()
                {
                    Id = Guid.NewGuid(),
                    AccountId = createdUser.Id,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };
                await _unitOfWork.EVDriverRepository.CreateAsync(eVDriver);
            }

            if (!result.Succeeded)
                return new ServiceResult(Const.FAIL_CREATE_CODE, Const.FAIL_CREATE_MSG, result.Errors);

            // B2: gán role cho user
            //VD nếu muốn thêm nhiều role cho 1 user
            //await _userManager.AddToRolesAsync(user, new[] { "EVDriver", "BusinessManager" });
            var roleResult = await _userManager.AddToRoleAsync(user, "EVDriver");
            if (!roleResult.Succeeded)
                return new ServiceResult(Const.FAIL_CREATE_CODE, "Failed to assign role", roleResult.Errors);

            await _unitOfWork.SaveChangesAsync();

            var token = await _userManager.GenerateEmailConfirmationTokenAsync(user);

            // Encode token để truyền qua querystring
            var encodedToken = HttpUtility.UrlEncode(token);

            //var confirmationLink = $"{_configuration["Jwt:Issuer"]}/api/Auth/confirmemail?userId={user.Id}&token={encodedToken}";
            var confirmationLink = $"{_configuration["EmailSettings:ConfirmationURL"]}?userId={user.Id}&token={encodedToken}";

            // Bước 4: Gửi mail cho user (bạn cần service gửi mail riêng)
            _emailSender.Send(user.Email,
                "Xác nhận tài khoản",
                $"Xin chào {user.Name}, vui lòng xác nhận tài khoản bằng cách bấm vào link: <a href='{confirmationLink}'>Xác nhận Email</a>");

            return new ServiceResult(Const.SUCCESS_CREATE_CODE, "Success register new account");
        }

        public async Task<IServiceResult> Login(LoginDto dto)
        {
            var user = await _userManager.FindByEmailAsync(dto.Email);
            if (user == null)
                return new ServiceResult(Const.FAIL_READ_CODE, "Invalid email or email not exist");

            var result = await _signInManager.CheckPasswordSignInAsync(user, dto.Password, false);
            if (!result.Succeeded)
                //throw new UnauthorizedAccessException("Invalid username or password.");
                return new ServiceResult(Const.FAIL_READ_CODE, "Invalid username or password.");

            user.LastLogin = DateTime.Now;
            await _userManager.UpdateAsync(user);

            var authClaims = new List<Claim>
            {
                new("userId", user.Id.ToString()),
                //new("username", user.UserName.ToString()),
                new("email", user.Email),
                new("name", user.Name),
                new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            };

            var userRoles = await _userManager.GetRolesAsync(user);
            foreach (var role in userRoles)
                authClaims.Add(new Claim("role", role));

            var authSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]));

            var t_e = await _unitOfWork.SystemConfigurationRepository.GetByIdAsync(
                    c => !c.IsDeleted && c.Name == "LOGIN_TOKEN_TIMEOUT"
                );

            double tokenTimeoutHours = 1; // Default to 1 hour if not set
            if (t_e != null && _unitOfWork.SystemConfigurationRepository.Validate(t_e))
                tokenTimeoutHours = (double)(t_e.MinValue ?? 1);

            var token = new JwtSecurityToken(
                issuer: _configuration["Jwt:Issuer"],
                audience: _configuration["Jwt:Audience"],
                expires: DateTime.Now.AddHours(tokenTimeoutHours),
                claims: authClaims,
                signingCredentials: new SigningCredentials(authSigningKey, SecurityAlgorithms.HmacSha256)
            );
            return new ServiceResult
            (
                Const.SUCCESS_READ_CODE,
                Const.SUCCESS_READ_MSG,
                new
                {
                    token = new JwtSecurityTokenHandler().WriteToken(token),
                    expiration = token.ValidTo
                }
            );
        }

        //public async Task<IServiceResult> ConfirmEmail(ConfirmEmailDto dto)
        public async Task<IServiceResult> ConfirmEmail(ConfirmEmailDto dto)
        {
            //var user = await _userManager.FindByIdAsync(dto.UserId);
            var user = await _userManager.FindByIdAsync(dto.UserId);

            if (user == null)
                return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy tài khoản");

            var token = HttpUtility.UrlDecode(dto.Token);
            var result = await _userManager.ConfirmEmailAsync(user, token);

            if (result.Succeeded)
                return new ServiceResult(Const.SUCCESS_VERIFY_OTP_CODE, "Email đã xác nhận thành công!");
            else
                return new ServiceResult(Const.FAIL_VERIFY_OTP_CODE, "Xác thực email thất bại.", result.Errors);
        }

        public async Task<IServiceResult> ResendConfirmEmail(string email)
        {
            var user = await _userManager.FindByEmailAsync(email);
            if (user == null)
                return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Email không tồn tại trong hệ thống");

            if (await _userManager.IsEmailConfirmedAsync(user))
                return new ServiceResult(Const.FAIL_UPDATE_CODE, "Email này đã được xác nhận rồi.");

            var token = await _userManager.GenerateEmailConfirmationTokenAsync(user);

            // Encode token để tránh lỗi ký tự đặc biệt trong URL
            var encodedToken = HttpUtility.UrlEncode(token);

            //var confirmationLink = $"{_configuration["Jwt:Issuer"]}/api/Auth/confirmemail?userId={user.Id}&token={encodedToken}";
            var confirmationLink = $"{_configuration["EmailSettings:ConfirmationURL"]}?userId={user.Id}&token={encodedToken}";

            // Gửi mail xác nhận
            _emailSender.Send(
                user.Email,
                "Xác nhận lại tài khoản",
                $"Xin chào {user.Name},<br/>" +
                $"Có vẻ như bạn chưa xác nhận tài khoản của mình.<br/>" +
                $"Vui lòng bấm vào link sau để xác nhận email: <a href='{confirmationLink}'>Xác nhận Email</a><br/><br/>" +
                $"Nếu bạn không yêu cầu thao tác này, vui lòng bỏ qua email này."
            );

            return new ServiceResult(Const.SUCCESS_SEND_OTP_CODE, "Đã gửi lại email xác nhận thành công.");
        }

        public async Task<IServiceResult> ForgotPassword(string email)
        {
            var user = await _userManager.FindByEmailAsync(email);
            if (user == null)
                return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Email không tồn tại trong hệ thống");

            // Sinh token đặt lại mật khẩu
            var token = await _userManager.GeneratePasswordResetTokenAsync(user);

            // Mã hóa token để truyền qua URL
            var encodedToken = HttpUtility.UrlEncode(token);

            //var resetLink = $"{_configuration["Jwt:Issuer"]}/api/Auth/resetpassword?userId={user.Id}&token={encodedToken}";
            var resetLink = $"{_configuration["EmailSettings:ResetPasswordURL"]}?userId={user.Id}&token={encodedToken}";

            // Gửi email cho người dùng
            _emailSender.Send(
                user.Email,
                "Đặt lại mật khẩu",
                $"Xin chào {user.Name},<br/>" +
                $"Vui lòng đặt lại mật khẩu của bạn bằng cách bấm vào link sau:<br/>" +
                $"<a href='{resetLink}'>Đặt lại mật khẩu</a><br/><br/>" +
                $"Nếu bạn không yêu cầu thao tác này, hãy bỏ qua email này."
            );

            return new ServiceResult(Const.SUCCESS_SEND_OTP_CODE, "Đã gửi mail đặt lại mật khẩu.");
        }

        public async Task<IServiceResult> ResetPassword(ResetPasswordDto dto)
        {
            var user = await _userManager.FindByIdAsync(dto.UserId.ToString());

            if (user == null)
                return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm thấy tài khoản");

            var token = HttpUtility.UrlDecode(dto.Token);
            var result = await _userManager.ResetPasswordAsync(user, token, dto.NewPassword);

            if (result.Succeeded)
                return new ServiceResult(Const.SUCCESS_UPDATE_CODE, "Đặt lại mật khẩu thành công");
            else
                return new ServiceResult(Const.FAIL_UPDATE_CODE, "Đặt lại mật khẩu thất bại", result.Errors);
        }

        public async Task<IServiceResult> ChangePassword(ChangePasswordDto dto, Guid userId)
        {
            var user = await _userManager.FindByIdAsync(userId.ToString());
            if (user == null)
                return new ServiceResult(Const.WARNING_NO_DATA_CODE, "Không tìm được tài khoản hợp lệ");

            var result = await _userManager.ChangePasswordAsync(user, dto.OldPassword, dto.NewPassword);

            if (!result.Succeeded)
            {
                var errors = result.Errors.Select(e => e.Description);
                return new ServiceResult(Const.FAIL_UPDATE_CODE, "Đổi mật khẩu thất bại", errors);
            }

            return new ServiceResult(Const.SUCCESS_UPDATE_CODE, "Đổi mật khẩu thành công");
        }

        public async Task<IServiceResult> LoginWithGoogleAsync(string idToken)
        {
            var payload = await GoogleJsonWebSignature.ValidateAsync(idToken);
            if (payload == null)
                return new ServiceResult(Const.FAIL_READ_CODE, "Invalid Google token");

            var email = payload.Email;
            var name = payload.Name;
            var googleId = payload.Subject;
            var avatar = payload.Picture;

            // Kiểm tra tài khoản đã tồn tại chưa
            var user = await _userManager.FindByEmailAsync(email);

            if (user == null)
            {
                // Tạo mới nếu chưa có
                user = new UserAccount
                {
                    Id = Guid.NewGuid(),
                    UserName = email,
                    Email = email,
                    Name = name,
                    ProviderUserId = googleId,
                    ProfilePictureUrl = avatar,
                    EmailConfirmed = true,
                    RegistrationDate = DateTime.UtcNow,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow,
                    Status = "Active"
                };

                var createResult = await _userManager.CreateAsync(user);
                if (!createResult.Succeeded)
                    return new ServiceResult(Const.FAIL_CREATE_CODE, "Cannot create account", createResult.Errors);

                // Gán role mặc định
                var roleResult = await _userManager.AddToRoleAsync(user, "EVDriver");
                if (!roleResult.Succeeded)
                    return new ServiceResult(Const.FAIL_CREATE_CODE, "Failed to assign role", roleResult.Errors);

                // Tạo EVDriverProfile
                EVDriverProfile eVDriver = new()
                {
                    Id = Guid.NewGuid(),
                    AccountId = user.Id,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };
                await _unitOfWork.EVDriverRepository.CreateAsync(eVDriver);
                await _unitOfWork.SaveChangesAsync();
            }
            else if (string.IsNullOrEmpty(user.ProviderUserId))
            {
                // Nếu user đã có mà chưa gắn ProviderUserId -> gắn thêm
                user.ProviderUserId = googleId;
                user.ProfilePictureUrl = avatar;
                await _userManager.UpdateAsync(user);
            }

            user.LastLogin = DateTime.Now;
            await _userManager.UpdateAsync(user);

            // Tạo JWT token
            var authClaims = new List<Claim>
            {
                new("userId", user.Id.ToString()),
                new("email", user.Email),
                new("name", user.Name),
                new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            };

            var userRoles = await _userManager.GetRolesAsync(user);
            foreach (var role in userRoles)
                authClaims.Add(new Claim("role", role));

            var authSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]));

            var t_e = await _unitOfWork.SystemConfigurationRepository.GetByIdAsync(
                    c => !c.IsDeleted && c.Name == "LOGIN_TOKEN_TIMEOUT"
                );

            double tokenTimeoutHours = 1; // Default to 1 hour if not set
            if (t_e != null && _unitOfWork.SystemConfigurationRepository.Validate(t_e))
                tokenTimeoutHours = (double)(t_e.MinValue ?? 1);

            var token = new JwtSecurityToken(
                issuer: _configuration["Jwt:Issuer"],
                audience: _configuration["Jwt:Audience"],
                expires: DateTime.Now.AddHours(tokenTimeoutHours),
                claims: authClaims,
                signingCredentials: new SigningCredentials(authSigningKey, SecurityAlgorithms.HmacSha256)
            );

            return new ServiceResult
            (
                Const.SUCCESS_READ_CODE,
                Const.SUCCESS_READ_MSG,
                new
                {
                    token = new JwtSecurityTokenHandler().WriteToken(token),
                    expiration = token.ValidTo
                }
            );
        }
    }
}
