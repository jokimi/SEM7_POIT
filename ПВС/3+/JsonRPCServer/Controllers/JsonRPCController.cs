using JsonRPCServer.Models;
using JsonRPCServer.Services;
using JsonRPCServer.Models;
using JsonRPCServer.Services;
using Microsoft.AspNetCore.Mvc;
using System.Text.Json;

namespace JsonRPCServer.Controllers
{
    [ApiController]
    [Route("api/jsonrpc")]
    public class JsonRpcController : ControllerBase
    {
        private readonly IJsonRpcService _jsonRpcService;

        public JsonRpcController(IJsonRpcService jsonRpcService)
        {
            _jsonRpcService = jsonRpcService;
        }

        [HttpPost]
        public async Task<IActionResult> HandleRequest()
        {
            try
            {
                using var reader = new StreamReader(Request.Body);
                var json = await reader.ReadToEndAsync();

                if (string.IsNullOrEmpty(json))
                {
                    return BadRequest(CreateErrorResponse(null, JsonRpcErrorCodes.ParseError, "Parse error"));
                }

                var document = JsonDocument.Parse(json);

                // Обработка batch запроса
                if (document.RootElement.ValueKind == JsonValueKind.Array)
                {
                    var requests = new List<JsonRpcRequest>();
                    foreach (var element in document.RootElement.EnumerateArray())
                    {
                        var request = ParseRequest(element);
                        if (request != null) requests.Add(request);
                    }

                    var responses = await _jsonRpcService.ProcessBatchAsync(requests);
                    return Ok(responses);
                }
                // Обработка одиночного запроса
                else
                {
                    var request = ParseRequest(document.RootElement);
                    if (request == null)
                    {
                        return BadRequest(CreateErrorResponse(null, JsonRpcErrorCodes.InvalidRequest, "Invalid Request"));
                    }

                    var response = await _jsonRpcService.ProcessRequestAsync(request);
                    return Ok(response);
                }
            }
            catch (JsonException)
            {
                return BadRequest(CreateErrorResponse(null, JsonRpcErrorCodes.ParseError, "Parse error"));
            }
            catch (Exception ex)
            {
                return StatusCode(500, CreateErrorResponse(null, JsonRpcErrorCodes.InternalError, ex.Message));
            }
        }

        private JsonRpcRequest? ParseRequest(JsonElement element)
        {
            try
            {
                return new JsonRpcRequest
                {
                    JsonRpc = element.GetProperty("jsonrpc").GetString() ?? "2.0",
                    Method = element.GetProperty("method").GetString() ?? string.Empty,
                    Params = element.TryGetProperty("params", out var paramsElement) ? (object)paramsElement : null,
                    Id = element.TryGetProperty("id", out var idElement) ? GetIdValue(idElement) : null
                };
            }
            catch
            {
                return null;
            }
        }

        private object? GetIdValue(JsonElement idElement)
        {
            return idElement.ValueKind switch
            {
                JsonValueKind.String => idElement.GetString(),
                JsonValueKind.Number => idElement.TryGetInt32(out int intVal) ? intVal : idElement.GetDouble(),
                _ => null
            };
        }

        private JsonRpcResponse CreateErrorResponse(object? id, int code, string message)
        {
            return new JsonRpcResponse
            {
                Error = new JsonRpcError(code, message),
                Id = id
            };
        }
    }
}