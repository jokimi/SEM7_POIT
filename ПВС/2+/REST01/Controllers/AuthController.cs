using BSTU.Results.Authenticate;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using REST01.Models;

namespace REST01.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly IAuthenticateService _authService;

        public AuthController(IAuthenticateService authService)
        {
            _authService = authService;
        }

        [HttpPost("SignIn")]
        [AllowAnonymous]
        public async Task<ActionResult<string>> SignIn([FromBody] SignInRequest request)
        {
            if (string.IsNullOrEmpty(request?.Login) || string.IsNullOrEmpty(request?.Password))
            {
                return BadRequest("Login and password are required");
            }

            var token = await _authService.AuthenticateAsync(request.Login, request.Password);

            if (token == null)
            {
                return NotFound("Invalid login or password");
            }

            return Ok(new { token });
        }
    }
}