using System.Threading.Tasks;

namespace BSTU.Results.Authenticate
{
    public interface IAuthenticateService
    {
        Task<string> AuthenticateAsync(string login, string password);
        Task<bool> ValidateTokenAsync(string token);
        Task<string> GetUserRoleAsync(string token);
    }
}