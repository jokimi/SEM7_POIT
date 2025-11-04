using Microsoft.AspNetCore.Mvc;
using JsonRPCServer.Services;

namespace JsonRPCServer.Controllers
{
    [ApiController]
    [Route("api/events")]
    public class EventsController : ControllerBase
    {
        private readonly IEventService _eventService;

        public EventsController(IEventService eventService)
        {
            _eventService = eventService;
        }

        [HttpGet]
        public async Task Get()
        {
            Response.Headers.Add("Content-Type", "text/event-stream");
            Response.Headers.Add("Cache-Control", "no-cache");
            Response.Headers.Add("Connection", "keep-alive");
            Response.Headers.Add("Access-Control-Allow-Origin", "*");
            Response.Headers.Add("Access-Control-Allow-Methods", "GET");
            Response.Headers.Add("Access-Control-Allow-Headers", "Cache-Control");

            _eventService.Subscribe(Response);

            try
            {
                await Response.WriteAsync("data: {\"message\": \"Connected to SSE stream\"}\n\n");
                await Response.Body.FlushAsync();

                // Держим соединение открытым
                while (!HttpContext.RequestAborted.IsCancellationRequested)
                {
                    await Task.Delay(5000);
                    if (!HttpContext.RequestAborted.IsCancellationRequested)
                    {
                        await Response.WriteAsync(": ping\n\n");
                        await Response.Body.FlushAsync();
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"SSE connection error: {ex.Message}");
            }
            finally
            {
                _eventService.Unsubscribe(Response);
            }
        }

        [HttpGet("subscribers")]
        public IActionResult GetSubscriberCount()
        {
            var count = _eventService.GetSubscriberCount();
            return Ok(new { subscribers = count });
        }
    }
}