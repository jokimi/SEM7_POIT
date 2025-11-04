using JsonRPCServer.Models;
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

        public JsonRpcService(ICalculatorService calculator)
        {
            _calculator = calculator;
        }

        public async Task<JsonRpcResponse> ProcessRequestAsync(JsonRpcRequest request)
        {
            return await Task.Run(() =>
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
                    object result = ProcessMethod(request.Method, request.Params);
                    return new JsonRpcResponse
                    {
                        Result = result,
                        Id = request.Id
                    };
                }
                catch (Exception ex)
                {
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

        private object ProcessMethod(string method, object? parameters)
        {
            return method.ToUpper() switch
            {
                "SUM" => ProcessSum(parameters),
                "SUB" => ProcessSub(parameters),
                "MUL" => ProcessMul(parameters),
                "DIV" => ProcessDiv(parameters),
                "FACT" => ProcessFact(parameters),
                _ => throw new Exception($"Method '{method}' not found")
            };
        }

        private double ProcessSum(object? parameters)
        {
            var (x, y) = ParseTwoDoubles(parameters);
            return _calculator.Sum(x, y);
        }

        private double ProcessSub(object? parameters)
        {
            var (x, y) = ParseTwoDoubles(parameters);
            return _calculator.Sub(x, y);
        }

        private double ProcessMul(object? parameters)
        {
            var (x, y) = ParseTwoDoubles(parameters);
            return _calculator.Mul(x, y);
        }

        private double ProcessDiv(object? parameters)
        {
            var (x, y) = ParseTwoDoubles(parameters);
            return _calculator.Div(x, y);
        }

        private long ProcessFact(object? parameters)
        {
            int x = ParseSingleInt(parameters);
            return _calculator.Fact(x);
        }

        private (double, double) ParseTwoDoubles(object? parameters)
        {
            if (parameters is JsonElement element)
            {
                if (element.ValueKind == JsonValueKind.Array)
                {
                    // Позиционные параметры
                    var array = element.EnumerateArray().ToArray();
                    if (array.Length == 2)
                    {
                        return (array[0].GetDouble(), array[1].GetDouble());
                    }
                }
                else if (element.ValueKind == JsonValueKind.Object)
                {
                    // Именованные параметры
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
                    // Позиционные параметры
                    var array = element.EnumerateArray().ToArray();
                    if (array.Length == 1)
                    {
                        return array[0].GetInt32();
                    }
                }
                else if (element.ValueKind == JsonValueKind.Object)
                {
                    // Именованные параметры
                    var obj = element.EnumerateObject().ToDictionary(p => p.Name, p => p.Value);
                    if (obj.ContainsKey("x"))
                    {
                        return obj["x"].GetInt32();
                    }
                }
                else if (element.ValueKind == JsonValueKind.Number)
                {
                    // Просто число
                    return element.GetInt32();
                }
            }

            throw new ArgumentException("Invalid parameters format");
        }
    }
}