using Microsoft.AspNetCore.SignalR.Client;
using System.Text.Json;

namespace SignalRClient
{
    public class CalculatorResponse
    {
        public bool Success { get; set; }
        public object? Result { get; set; }
        public string? Error { get; set; }
        public string Method { get; set; } = string.Empty;
    }

    class Program
    {
        private static HubConnection? connection;

        static async Task Main(string[] args)
        {
            Console.WriteLine("SignalR Calculator Client");
            Console.WriteLine("============================\n");

            await StartConnection();

            if (connection?.State == HubConnectionState.Connected)
            {
                await RunCalculator();
            }

            await StopConnection();
        }

        static async Task StartConnection()
        {
            try
            {
                connection = new HubConnectionBuilder()
                    .WithUrl("http://localhost:5127/calculatorHub")
                    .Build();

                connection.On<CalculatorResponse>("ReceiveResult", (response) =>
                {
                    var message = response.Success
                        ? $"[BROADCAST] {response.Method}: {response.Result}"
                        : $"[BROADCAST] {response.Method} Error: {response.Error}";

                    Console.ForegroundColor = response.Success ? ConsoleColor.Green : ConsoleColor.Red;
                    Console.WriteLine(message);
                    Console.ResetColor();
                });

                connection.On<string, string>("ReceiveError", (method, error) =>
                {
                    Console.ForegroundColor = ConsoleColor.Red;
                    Console.WriteLine($"[ERROR] {method}: {error}");
                    Console.ResetColor();
                });

                connection.On<string>("ReceiveMessage", (message) =>
                {
                    Console.ForegroundColor = ConsoleColor.Blue;
                    Console.WriteLine($"[MESSAGE] {message}");
                    Console.ResetColor();
                });

                await connection.StartAsync();
                Console.ForegroundColor = ConsoleColor.Green;
                Console.WriteLine($"Connected to SignalR hub. Connection ID: {connection.ConnectionId}");
                Console.ResetColor();
            }
            catch (Exception ex)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine($"Connection failed: {ex.Message}");
                Console.ResetColor();
            }
        }

        static async Task RunCalculator()
        {
            while (true)
            {
                Console.WriteLine("\nAvailable operations:");
                Console.WriteLine("1. SUM (x + y)");
                Console.WriteLine("2. SUB (x - y)");
                Console.WriteLine("3. MUL (x * y)");
                Console.WriteLine("4. DIV (x / y)");
                Console.WriteLine("5. FACT (n!)");
                Console.WriteLine("0. Exit");
                Console.Write("\nSelect operation (0-5): ");

                var choice = Console.ReadLine();

                if (choice == "0") break;

                try
                {
                    switch (choice)
                    {
                        case "1":
                            await CallSum();
                            break;
                        case "2":
                            await CallSub();
                            break;
                        case "3":
                            await CallMul();
                            break;
                        case "4":
                            await CallDiv();
                            break;
                        case "5":
                            await CallFact();
                            break;
                        default:
                            Console.WriteLine("Invalid choice. Please try again.");
                            break;
                    }
                }
                catch (Exception ex)
                {
                    Console.ForegroundColor = ConsoleColor.Red;
                    Console.WriteLine($"Error: {ex.Message}");
                    Console.ResetColor();
                }

                Console.WriteLine("\nPress any key to continue...");
                Console.ReadKey();
            }
        }

        static async Task CallSum()
        {
            Console.Write("Enter x: ");
            var x = double.Parse(Console.ReadLine() ?? "0");
            Console.Write("Enter y: ");
            var y = double.Parse(Console.ReadLine() ?? "0");

            var result = await connection!.InvokeAsync<CalculatorResponse>("Sum", x, y);
            DisplayResult(result);
        }

        static async Task CallSub()
        {
            Console.Write("Enter x: ");
            var x = double.Parse(Console.ReadLine() ?? "0");
            Console.Write("Enter y: ");
            var y = double.Parse(Console.ReadLine() ?? "0");

            var result = await connection!.InvokeAsync<CalculatorResponse>("Sub", x, y);
            DisplayResult(result);
        }

        static async Task CallMul()
        {
            Console.Write("Enter x: ");
            var x = double.Parse(Console.ReadLine() ?? "0");
            Console.Write("Enter y: ");
            var y = double.Parse(Console.ReadLine() ?? "0");

            var result = await connection!.InvokeAsync<CalculatorResponse>("Mul", x, y);
            DisplayResult(result);
        }

        static async Task CallDiv()
        {
            Console.Write("Enter x: ");
            var x = double.Parse(Console.ReadLine() ?? "0");
            Console.Write("Enter y: ");
            var y = double.Parse(Console.ReadLine() ?? "0");

            var result = await connection!.InvokeAsync<CalculatorResponse>("Div", x, y);
            DisplayResult(result);
        }

        static async Task CallFact()
        {
            Console.Write("Enter n: ");
            var n = int.Parse(Console.ReadLine() ?? "0");

            var result = await connection!.InvokeAsync<CalculatorResponse>("Fact", n);
            DisplayResult(result);
        }

        static void DisplayResult(CalculatorResponse response)
        {
            if (response.Success)
            {
                Console.ForegroundColor = ConsoleColor.Green;
                Console.WriteLine($"{response.Method} Result: {response.Result}");
            }
            else
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine($"{response.Method} Error: {response.Error}");
            }
            Console.ResetColor();
        }

        static async Task StopConnection()
        {
            if (connection != null)
            {
                await connection.StopAsync();
                await connection.DisposeAsync();
                Console.WriteLine("\nDisconnected from SignalR hub.");
            }
        }
    }
}