using System.Security.Claims;

namespace Common.Helper
{
    public static class ClaimsHelper
    {
        public static Guid GetUserId(this ClaimsPrincipal user)
        {
            var claim = user.FindFirst("userId")
                        ?? throw new UnauthorizedAccessException("Không tìm thấy userId trong token.");

            return Guid.Parse(claim.Value);
        }

        public static string GetEmail(this ClaimsPrincipal user)
        {
            return user.FindFirst("email")?.Value ?? string.Empty;
        }

        public static string GetRole(this ClaimsPrincipal user)
        {
            return user.FindFirst("role")?.Value ?? string.Empty;
        }
    }
}
