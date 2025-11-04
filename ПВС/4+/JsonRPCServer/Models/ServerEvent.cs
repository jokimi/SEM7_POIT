namespace JsonRPCServer.Models
{
    public class ServerEvent
    {
        public string Event { get; set; } = string.Empty;
        public object Data { get; set; } = new();
        public string? Id { get; set; }
        public int? Retry { get; set; }

        public override string ToString()
        {
            var lines = new List<string>();

            if (!string.IsNullOrEmpty(Id))
                lines.Add($"id: {Id}");

            if (!string.IsNullOrEmpty(Event))
                lines.Add($"event: {Event}");

            if (Retry.HasValue)
                lines.Add($"retry: {Retry}");

            var jsonData = System.Text.Json.JsonSerializer.Serialize(Data);
            lines.Add($"data: {jsonData}");

            return string.Join("\n", lines) + "\n\n";
        }
    }

    public class ResultData
    {
        public double Result { get; set; }
    }

    public class ErrorData
    {
        public string Error { get; set; } = string.Empty;
    }
}