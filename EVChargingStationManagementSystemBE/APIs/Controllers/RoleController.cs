using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Infrastructure.Models;

namespace APIs.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class RoleController(RoleManager<Role> roleManager, UserManager<UserAccount> userManager) : ControllerBase
    {
        private readonly RoleManager<Role> _roleManager = roleManager;
        private readonly UserManager<UserAccount> _userManager = userManager;

        [HttpPost("create")]
        public async Task<IActionResult> CreateRole(string roleName)
        {
            if (await _roleManager.RoleExistsAsync(roleName))
                return BadRequest("Role already exists");

            var result = await _roleManager.CreateAsync(new Role { Name = roleName });

            return result.Succeeded ? Ok("Role created") : BadRequest(result.Errors);
        }

        [HttpPost("add-to-user")]
        public async Task<IActionResult> AddUserToRole(string userId, string roleName)
        {
            var user = await _userManager.FindByIdAsync(userId);
            if (user == null) return NotFound("User not found");

            var result = await _userManager.AddToRoleAsync(user, roleName);

            return result.Succeeded ? Ok("Role assigned") : BadRequest(result.Errors);
        }

        [HttpGet("all")]
        public IActionResult GetAllRoles()
        {
            var roles = _roleManager.Roles.ToList();
            return Ok(roles);
        }
    }
}
