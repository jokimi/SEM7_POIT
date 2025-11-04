using gRPCServer.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddGrpc();

var app = builder.Build();

app.MapGrpcService<CalculatorService>();
app.MapGet("/", () => "gRPC Server is running. Use gRPC client to communicate.");

app.Run();