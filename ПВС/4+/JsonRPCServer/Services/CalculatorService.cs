namespace JsonRPCServer.Services
{
    public interface ICalculatorService
    {
        double Sum(double x, double y);
        double Sub(double x, double y);
        double Mul(double x, double y);
        double Div(double x, double y);
        long Fact(int x);
    }

    public class CalculatorService : ICalculatorService
    {
        public double Sum(double x, double y) => x + y;

        public double Sub(double x, double y) => x - y;

        public double Mul(double x, double y) => x * y;

        public double Div(double x, double y)
        {
            if (y == 0)
                throw new DivideByZeroException("Division by zero is not allowed");
            return x / y;
        }

        public long Fact(int x)
        {
            if (x < 0)
                throw new ArgumentException("Factorial is not defined for negative numbers");

            if (x > 20)
                throw new OverflowException($"Factorial for {x} would exceed long capacity");

            long result = 1;
            for (int i = 2; i <= x; i++)
            {
                checked { result *= i; }
            }
            return result;
        }
    }
}