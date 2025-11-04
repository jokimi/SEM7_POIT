using Grpc.Core;
using static gRPCServer.Calculator;

namespace gRPCServer.Services
{
    public class CalculatorService : CalculatorBase
    {
        public override Task<CalculationResult> Sum(BinaryOperationRequest request, ServerCallContext context)
        {
            var result = new CalculationResult { Value = request.X + request.Y };
            return Task.FromResult(result);
        }

        public override Task<CalculationResult> Sub(BinaryOperationRequest request, ServerCallContext context)
        {
            var result = new CalculationResult { Value = request.X - request.Y };
            return Task.FromResult(result);
        }

        public override Task<CalculationResult> Mul(BinaryOperationRequest request, ServerCallContext context)
        {
            var result = new CalculationResult { Value = request.X * request.Y };
            return Task.FromResult(result);
        }

        public override Task<CalculationResult> Div(BinaryOperationRequest request, ServerCallContext context)
        {
            if (request.Y == 0)
            {
                return Task.FromResult(new CalculationResult
                {
                    Error = "Division by zero is not allowed"
                });
            }

            var result = new CalculationResult { Value = request.X / request.Y };
            return Task.FromResult(result);
        }

        public override Task<CalculationResult> Fact(UnaryOperationRequest request, ServerCallContext context)
        {
            try
            {
                if (request.X < 0)
                {
                    return Task.FromResult(new CalculationResult
                    {
                        Error = "Factorial is not defined for negative numbers"
                    });
                }

                if (request.X > 20)
                {
                    return Task.FromResult(new CalculationResult
                    {
                        Error = $"Factorial for numbers greater than 20 is not supported (requested: {request.X})"
                    });
                }

                var result = new CalculationResult { Value = CalculateFactorial(request.X) };
                return Task.FromResult(result);
            }
            catch (OverflowException ex)
            {
                return Task.FromResult(new CalculationResult
                {
                    Error = $"Factorial overflow: {ex.Message}"
                });
            }
            catch (ArgumentException ex)
            {
                return Task.FromResult(new CalculationResult
                {
                    Error = $"Invalid input: {ex.Message}"
                });
            }
        }

        private double CalculateFactorial(int n)
        {
            if (n < 0)
                throw new ArgumentException("Factorial is not defined for negative numbers");

            if (n == 0 || n == 1)
                return 1;

            double result = 1;
            for (int i = 2; i <= n; i++)
            {
                checked
                {
                    result *= i;
                }
            }
            return result;
        }
    }
}