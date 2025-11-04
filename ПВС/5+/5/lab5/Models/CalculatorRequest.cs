namespace SIGNALRServer.Models
{
    public class CalculatorRequest
    {
        public double X { get; set; }
        public double Y { get; set; }
        public int N { get; set; }
    }

    public class CalculatorResponse
    {
        public bool Success { get; set; }
        public object? Result { get; set; }
        public string? Error { get; set; }
        public string Method { get; set; } = string.Empty;
    }
}