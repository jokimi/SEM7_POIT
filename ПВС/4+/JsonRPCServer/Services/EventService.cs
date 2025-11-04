using JsonRPCServer.Models;

namespace JsonRPCServer.Services
{
    public interface IEventService
    {
        void Subscribe(HttpResponse response);
        void Unsubscribe(HttpResponse response);
        Task BroadcastEventAsync(ServerEvent serverEvent);
        int GetSubscriberCount();
    }

    public class EventService : IEventService
    {
        private readonly List<HttpResponse> _subscribers = new();
        private readonly object _lock = new object();

        public void Subscribe(HttpResponse response)
        {
            lock (_lock)
            {
                if (!_subscribers.Contains(response))
                {
                    _subscribers.Add(response);
                    Console.WriteLine($"New subscriber connected. Total: {_subscribers.Count}");
                }
            }
        }

        public void Unsubscribe(HttpResponse response)
        {
            lock (_lock)
            {
                _subscribers.Remove(response);
                Console.WriteLine($"Subscriber disconnected. Total: {_subscribers.Count}");
            }
        }

        public async Task BroadcastEventAsync(ServerEvent serverEvent)
        {
            List<HttpResponse> subscribersCopy;
            lock (_lock)
            {
                subscribersCopy = new List<HttpResponse>(_subscribers);
            }

            var tasks = subscribersCopy.Select(async response =>
            {
                try
                {
                    await response.WriteAsync(serverEvent.ToString());
                    await response.Body.FlushAsync();
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Error sending event to subscriber: {ex.Message}");
                    Unsubscribe(response);
                }
            });

            await Task.WhenAll(tasks);
        }

        public int GetSubscriberCount()
        {
            lock (_lock)
            {
                return _subscribers.Count;
            }
        }
    }
}