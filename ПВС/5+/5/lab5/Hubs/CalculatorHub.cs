using Microsoft.AspNetCore.SignalR;
using SIGNALRServer.Models;
using SIGNALRServer.Services;

namespace SIGNALRServer.Hubs
{
    public interface ICalculatorClient
    {
        Task ReceiveResult(CalculatorResponse response);
        Task ReceiveError(string method, string error);
        Task ReceiveMessage(string message);
    }

    public class CalculatorHub : Hub<ICalculatorClient>
    {
        private readonly ICalculatorService _calculatorService;

        public CalculatorHub(ICalculatorService calculatorService)
        {
            _calculatorService = calculatorService;
        }

        public override async Task OnConnectedAsync()
        {
            await Clients.Caller.ReceiveMessage($"Connected with ID: {Context.ConnectionId}");
            await base.OnConnectedAsync();
        }

        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            await Clients.All.ReceiveMessage($"Client disconnected: {Context.ConnectionId}");
            await base.OnDisconnectedAsync(exception);
        }

        public async Task<CalculatorResponse> Sum(double x, double y)
        {
            try
            {
                var result = _calculatorService.Sum(x, y);

                var response = new CalculatorResponse
                {
                    Success = true,
                    Result = result,
                    Method = "SUM"
                };
                await Clients.All.ReceiveResult(response);
                return response;
            }
            catch (Exception ex)
            {
                var errorResponse = new CalculatorResponse
                {
                    Success = false,
                    Error = ex.Message,
                    Method = "SUM"
                };
                await Clients.Caller.ReceiveError("SUM", ex.Message);
                return errorResponse;
            }
        }

        public async Task<CalculatorResponse> Sub(double x, double y)
        {
            try
            {
                var result = _calculatorService.Sub(x, y);

                var response = new CalculatorResponse
                {
                    Success = true,
                    Result = result,
                    Method = "SUB"
                };

                await Clients.All.ReceiveResult(response);
                return response;
            }
            catch (Exception ex)
            {
                var errorResponse = new CalculatorResponse
                {
                    Success = false,
                    Error = ex.Message,
                    Method = "SUB"
                };
                await Clients.Caller.ReceiveError("SUB", ex.Message);
                return errorResponse;
            }
        }

        public async Task<CalculatorResponse> Mul(double x, double y)
        {
            try
            {
                var result = _calculatorService.Mul(x, y);

                var response = new CalculatorResponse
                {
                    Success = true,
                    Result = result,
                    Method = "MUL"
                };

                await Clients.All.ReceiveResult(response);
                return response;
            }
            catch (Exception ex)
            {
                var errorResponse = new CalculatorResponse
                {
                    Success = false,
                    Error = ex.Message,
                    Method = "MUL"
                };
                await Clients.Caller.ReceiveError("MUL", ex.Message);
                return errorResponse;
            }
        }

        public async Task<CalculatorResponse> Div(double x, double y)
        {
            try
            {
                var result = _calculatorService.Div(x, y);

                var response = new CalculatorResponse
                {
                    Success = true,
                    Result = result,
                    Method = "DIV"
                };

                await Clients.All.ReceiveResult(response);
                return response;
            }
            catch (Exception ex)
            {
                var errorResponse = new CalculatorResponse
                {
                    Success = false,
                    Error = ex.Message,
                    Method = "DIV"
                };
                await Clients.Caller.ReceiveError("DIV", ex.Message);
                return errorResponse;
            }
        }

        public async Task<CalculatorResponse> Fact(int n)
        {
            try
            {
                var result = _calculatorService.Fact(n);

                var response = new CalculatorResponse
                {
                    Success = true,
                    Result = result,
                    Method = "FACT"
                };

                await Clients.All.ReceiveResult(response);
                return response;
            }
            catch (Exception ex)
            {
                var errorResponse = new CalculatorResponse
                {
                    Success = false,
                    Error = ex.Message,
                    Method = "FACT"
                };
                await Clients.Caller.ReceiveError("FACT", ex.Message);
                return errorResponse;
            }
        }

        public async Task BroadcastMessage(string message)
        {
            await Clients.All.ReceiveMessage($"{Context.ConnectionId}: {message}");
        }
    }
}