namespace BSTU.Results.Authenticate
{
    public class User
    {
        public string Username { get; set; }
        public string Password { get; set; }
        public string Role { get; set; }
    }

    public static class UserRole
    {
        public const string READER = "READER";
        public const string WRITER = "WRITER";
    }
}