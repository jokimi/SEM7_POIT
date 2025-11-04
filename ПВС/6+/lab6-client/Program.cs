using Grpc.Net.Client;
using gRPCServer;

namespace gRPCClient
{
    class Program
    {
        static async Task Main(string[] args)
        {
            using var channel = GrpcChannel.ForAddress("http://localhost:5086");
            var client = new Calculator.CalculatorClient(channel);

            Console.WriteLine("gRPC Calculator Client");
            Console.WriteLine("======================");

            bool exit = false;

            while (!exit)
            {
                ShowMenu();
                var choice = Console.ReadLine();

                switch (choice)
                {
                    case "1":
                        await PerformSum(client);
                        break;
                    case "2":
                        await PerformSub(client);
                        break;
                    case "3":
                        await PerformMul(client);
                        break;
                    case "4":
                        await PerformDiv(client);
                        break;
                    case "5":
                        await PerformFact(client);
                        break;
                    case "6":
                        await PerformAllOperations(client);
                        break;
                    case "0":
                        exit = true;
                        Console.WriteLine("Выход из программы...");
                        break;
                    default:
                        Console.WriteLine("Неверный выбор. Попробуйте снова.");
                        break;
                }

                if (!exit)
                {
                    Console.WriteLine("\nНажмите любую клавишу для продолжения...");
                    Console.ReadKey();
                    Console.Clear();
                }
            }

            Console.WriteLine("\nПрограмма завершена. Нажмите любую клавишу для выхода...");
            Console.ReadKey();
        }

        static void ShowMenu()
        {
            Console.WriteLine("\nВыберите операцию:");
            Console.WriteLine("1. Сложение (SUM)");
            Console.WriteLine("2. Вычитание (SUB)");
            Console.WriteLine("3. Умножение (MUL)");
            Console.WriteLine("4. Деление (DIV)");
            Console.WriteLine("5. Факториал (FACT)");
            Console.WriteLine("6. Выполнить все операции");
            Console.WriteLine("0. Выход");
            Console.Write("Ваш выбор: ");
        }

        static async Task PerformSum(Calculator.CalculatorClient client)
        {
            Console.WriteLine("\n--- СЛОЖЕНИЕ ---");
            try
            {
                Console.Write("Введите первое число: ");
                double x = GetDoubleInput();

                Console.Write("Введите второе число: ");
                double y = GetDoubleInput();

                await TestSum(client, x, y);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Ошибка ввода: {ex.Message}");
            }
        }

        static async Task PerformSub(Calculator.CalculatorClient client)
        {
            Console.WriteLine("\n--- ВЫЧИТАНИЕ ---");
            try
            {
                Console.Write("Введите первое число: ");
                double x = GetDoubleInput();

                Console.Write("Введите второе число: ");
                double y = GetDoubleInput();

                await TestSub(client, x, y);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Ошибка ввода: {ex.Message}");
            }
        }

        static async Task PerformMul(Calculator.CalculatorClient client)
        {
            Console.WriteLine("\n--- УМНОЖЕНИЕ ---");
            try
            {
                Console.Write("Введите первое число: ");
                double x = GetDoubleInput();

                Console.Write("Введите второе число: ");
                double y = GetDoubleInput();

                await TestMul(client, x, y);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Ошибка ввода: {ex.Message}");
            }
        }

        static async Task PerformDiv(Calculator.CalculatorClient client)
        {
            Console.WriteLine("\n--- ДЕЛЕНИЕ ---");
            try
            {
                Console.Write("Введите делимое: ");
                double x = GetDoubleInput();

                Console.Write("Введите делитель: ");
                double y = GetDoubleInput();

                await TestDiv(client, x, y);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Ошибка ввода: {ex.Message}");
            }
        }

        static async Task PerformFact(Calculator.CalculatorClient client)
        {
            Console.WriteLine("\n--- ФАКТОРИАЛ ---");
            Console.WriteLine("Поддерживаются числа от 0 до 20");

            try
            {
                Console.Write("Введите число для вычисления факториала (0-20): ");
                int x = GetIntInput(0, 20);

                await TestFact(client, x);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Ошибка ввода: {ex.Message}");
            }
        }

        static async Task PerformAllOperations(Calculator.CalculatorClient client)
        {
            Console.WriteLine("\n--- ВЫПОЛНЕНИЕ ВСЕХ ОПЕРАЦИЙ ---");
            try
            {
                Console.Write("Введите первое число: ");
                double x = GetDoubleInput();

                Console.Write("Введите второе число: ");
                double y = GetDoubleInput();

                Console.Write("Введите число для факториала (0-20): ");
                int factNum = GetIntInput(0, 20);

                Console.WriteLine("\nРезультаты:");
                await TestSum(client, x, y);
                await TestSub(client, x, y);
                await TestMul(client, x, y);
                await TestDiv(client, x, y);
                await TestFact(client, factNum);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Ошибка ввода: {ex.Message}");
            }
        }

        static double GetDoubleInput()
        {
            while (true)
            {
                string input = Console.ReadLine();
                if (double.TryParse(input, out double result))
                {
                    return result;
                }
                Console.Write("Неверный формат числа. Введите число снова: ");
            }
        }

        static int GetIntInput(int minValue = int.MinValue, int maxValue = int.MaxValue)
        {
            while (true)
            {
                string input = Console.ReadLine();
                if (int.TryParse(input, out int result))
                {
                    if (result >= minValue && result <= maxValue)
                    {
                        return result;
                    }
                    else
                    {
                        Console.Write($"Число должно быть в диапазоне от {minValue} до {maxValue}. Введите снова: ");
                    }
                }
                else
                {
                    Console.Write("Неверный формат целого числа. Введите число снова: ");
                }
            }
        }

        static async Task TestSum(Calculator.CalculatorClient client, double x, double y)
        {
            try
            {
                var request = new BinaryOperationRequest { X = x, Y = y };
                var response = await client.SumAsync(request);

                if (response.ResultCase == CalculationResult.ResultOneofCase.Value)
                    Console.WriteLine($"SUM({x}, {y}) = {response.Value}");
                else
                    Console.WriteLine($"SUM Error: {response.Error}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"SUM Exception: {ex.Message}");
            }
        }

        static async Task TestSub(Calculator.CalculatorClient client, double x, double y)
        {
            try
            {
                var request = new BinaryOperationRequest { X = x, Y = y };
                var response = await client.SubAsync(request);

                if (response.ResultCase == CalculationResult.ResultOneofCase.Value)
                    Console.WriteLine($"SUB({x}, {y}) = {response.Value}");
                else
                    Console.WriteLine($"SUB Error: {response.Error}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"SUB Exception: {ex.Message}");
            }
        }

        static async Task TestMul(Calculator.CalculatorClient client, double x, double y)
        {
            try
            {
                var request = new BinaryOperationRequest { X = x, Y = y };
                var response = await client.MulAsync(request);

                if (response.ResultCase == CalculationResult.ResultOneofCase.Value)
                    Console.WriteLine($"MUL({x}, {y}) = {response.Value}");
                else
                    Console.WriteLine($"MUL Error: {response.Error}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"MUL Exception: {ex.Message}");
            }
        }

        static async Task TestDiv(Calculator.CalculatorClient client, double x, double y)
        {
            try
            {
                var request = new BinaryOperationRequest { X = x, Y = y };
                var response = await client.DivAsync(request);

                if (response.ResultCase == CalculationResult.ResultOneofCase.Value)
                    Console.WriteLine($"DIV({x}, {y}) = {response.Value}");
                else
                    Console.WriteLine($"DIV Error: {response.Error}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"DIV Exception: {ex.Message}");
            }
        }

        static async Task TestFact(Calculator.CalculatorClient client, int x)
        {
            try
            {
                var request = new UnaryOperationRequest { X = x };
                var response = await client.FactAsync(request);

                if (response.ResultCase == CalculationResult.ResultOneofCase.Value)
                    Console.WriteLine($"FACT({x}) = {response.Value}");
                else
                    Console.WriteLine($"FACT Error: {response.Error}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"FACT Exception: {ex.Message}");
            }
        }
    }
}