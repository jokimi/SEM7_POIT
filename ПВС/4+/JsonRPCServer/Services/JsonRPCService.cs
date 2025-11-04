using JsonRPCServer.Models;
using JsonRPCServer.Services;
using System.Text.Json;

namespace JsonRPCServer.Services
{
    public interface IJsonRpcService
    {
        Task<JsonRpcResponse> ProcessRequestAsync(JsonRpcRequest request);
        Task<List<JsonRpcResponse>> ProcessBatchAsync(List<JsonRpcRequest> requests);
    }

    public class JsonRpcService : IJsonRpcService
    {
        private readonly ICalculatorService _calculator;
        private readonly IEventService _eventService;

        public JsonRpcService(ICalculatorService calculator, IEventService eventService)
        {
            _calculator = calculator;
            _eventService = eventService;
        }

        public async Task<JsonRpcResponse> ProcessRequestAsync(JsonRpcRequest request)
        {
            return await Task.Run(async () =>
            {
                if (request.JsonRpc != "2.0" || string.IsNullOrEmpty(request.Method))
                {
                    return new JsonRpcResponse
                    {
                        Error = new JsonRpcError(JsonRpcErrorCodes.InvalidRequest, "Invalid Request"),
                        Id = request.Id
                    };
                }

                try
                {
                    object result = await ProcessMethodWithEventsAsync(request.Method, request.Params);
                    return new JsonRpcResponse
                    {
                        Result = result,
                        Id = request.Id
                    };
                }
                catch (Exception ex)
                {
                    await SendErrorEventAsync(request.Method, ex.Message);
                    return new JsonRpcResponse
                    {
                        Error = new JsonRpcError(JsonRpcErrorCodes.ServerError, ex.Message),
                        Id = request.Id
                    };
                }
            });
        }

        public async Task<List<JsonRpcResponse>> ProcessBatchAsync(List<JsonRpcRequest> requests)
        {
            var tasks = requests.Select(ProcessRequestAsync);
            var results = await Task.WhenAll(tasks);
            return results.ToList();
        }

        private async Task<object> ProcessMethodWithEventsAsync(string method, object? parameters)
        {
            var result = method.ToUpper() switch
            {
                "SUM" => await ProcessSumWithEventAsync(parameters),
                "SUB" => await ProcessSubWithEventAsync(parameters),
                "MUL" => await ProcessMulWithEventAsync(parameters),
                "DIV" => await ProcessDivWithEventAsync(parameters),
                "FACT" => await ProcessFactWithEventAsync(parameters),
                _ => throw new Exception($"Method '{method}' not found")
            };

            return result;
        }

        private async Task<double> ProcessSumWithEventAsync(object? parameters)
        {
            var (x, y) = ParseTwoDoubles(parameters);
            var result = _calculator.Sum(x, y);

            await _eventService.BroadcastEventAsync(new ServerEvent
            {
                Event = "SUM",
                Data = new { result = result },
                Id = Guid.NewGuid().ToString()
            });

            return result;
        }

        private async Task<double> ProcessSubWithEventAsync(object? parameters)
        {
            var (x, y) = ParseTwoDoubles(parameters);
            var result = _calculator.Sub(x, y);

            await _eventService.BroadcastEventAsync(new ServerEvent
            {
                Event = "SUB",
                Data = new { result = result },
                Id = Guid.NewGuid().ToString()
            });

            return result;
        }

        private async Task<double> ProcessMulWithEventAsync(object? parameters)
        {
            var (x, y) = ParseTwoDoubles(parameters);
            var result = _calculator.Mul(x, y);

            await _eventService.BroadcastEventAsync(new ServerEvent
            {
                Event = "MUL",
                Data = new { result = result },
                Id = Guid.NewGuid().ToString()
            });

            return result;
        }

        private async Task<double> ProcessDivWithEventAsync(object? parameters)
        {
            var (x, y) = ParseTwoDoubles(parameters);

            try
            {
                var result = _calculator.Div(x, y);

                await _eventService.BroadcastEventAsync(new ServerEvent
                {
                    Event = "DIV",
                    Data = new { result = result },
                    Id = Guid.NewGuid().ToString()
                });

                return result;
            }
            catch (DivideByZeroException)
            {
                await _eventService.BroadcastEventAsync(new ServerEvent
                {
                    Event = "DIV",
                    Data = new { error = "y = 0" },
                    Id = Guid.NewGuid().ToString()
                });
                throw;
            }
        }

        private async Task<long> ProcessFactWithEventAsync(object? parameters)
        {
            int x = ParseSingleInt(parameters);

            try
            {
                var result = _calculator.Fact(x);

                await _eventService.BroadcastEventAsync(new ServerEvent
                {
                    Event = "FACT",
                    Data = new { result = result },
                    Id = Guid.NewGuid().ToString()
                });

                return result;
            }
            catch (OverflowException)
            {
                await _eventService.BroadcastEventAsync(new ServerEvent
                {
                    Event = "FACT",
                    Data = new { error = "overflow" },
                    Id = Guid.NewGuid().ToString()
                });
                throw;
            }
        }

        private async Task SendErrorEventAsync(string method, string errorMessage)
        {
            var eventType = method.ToUpper();
            var errorData = new { error = errorMessage };

            await _eventService.BroadcastEventAsync(new ServerEvent
            {
                Event = eventType,
                Data = errorData,
                Id = Guid.NewGuid().ToString()
            });
        }

        private (double, double) ParseTwoDoubles(object? parameters)
        {
            if (parameters is JsonElement element)
            {
                if (element.ValueKind == JsonValueKind.Array)
                {
                    var array = element.EnumerateArray().ToArray();
                    if (array.Length == 2)
                    {
                        return (array[0].GetDouble(), array[1].GetDouble());
                    }
                }
                else if (element.ValueKind == JsonValueKind.Object)
                {
                    var obj = element.EnumerateObject().ToDictionary(p => p.Name, p => p.Value);
                    if (obj.ContainsKey("x") && obj.ContainsKey("y"))
                    {
                        return (obj["x"].GetDouble(), obj["y"].GetDouble());
                    }
                }
            }
            throw new ArgumentException("Invalid parameters format");
        }

        private int ParseSingleInt(object? parameters)
        {
            if (parameters is JsonElement element)
            {
                if (element.ValueKind == JsonValueKind.Array)
                {
                    var array = element.EnumerateArray().ToArray();
                    if (array.Length == 1)
                    {
                        return array[0].GetInt32();
                    }
                }
                else if (element.ValueKind == JsonValueKind.Object)
                {
                    var obj = element.EnumerateObject().ToDictionary(p => p.Name, p => p.Value);
                    if (obj.ContainsKey("x"))
                    {
                        return obj["x"].GetInt32();
                    }
                }
                else if (element.ValueKind == JsonValueKind.Number)
                {
                    return element.GetInt32();
                }
            }
            throw new ArgumentException("Invalid parameters format");
        }
    }
}