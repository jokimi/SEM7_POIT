using System;
using System.Web;
using System.Web.SessionState;
using System.Collections.Generic;

namespace CustomRestHandler
{
    public class RestHandler : IHttpHandler, IRequiresSessionState
    {
        public bool IsReusable => false;

        public void ProcessRequest(HttpContext context)
        {
            context.Response.Headers.Add("Access-Control-Allow-Origin", "*");
            context.Response.Headers.Add("Access-Control-Allow-Methods", "GET,POST,PUT,DELETE");
            context.Response.Headers.Add("Access-Control-Allow-Headers", "Content-Type");

            context.Response.ContentType = "application/json";

            if (context.Application["globalResult"] == null)
                context.Application["globalResult"] = 0;

            if (context.Session["localStack"] == null)
                context.Session["localStack"] = new Stack<int>();

            try
            {
                switch (context.Request.HttpMethod.ToUpper())
                {
                    case "GET":
                        HandleGet(context);
                        break;
                    case "POST":
                        HandlePost(context);
                        break;
                    case "PUT":
                        HandlePut(context);
                        break;
                    case "DELETE":
                        HandleDelete(context);
                        break;
                    default:
                        context.Response.StatusCode = 405;
                        context.Response.Write("{\"error\": \"Method not allowed\"}");
                        break;
                }
            }
            catch (Exception ex)
            {
                context.Response.StatusCode = 500;
                context.Response.Write($"{{\"error\": \"{ex.Message}\"}}");
            }
        }

        private void HandleGet(HttpContext context)
        {
            int globalResult = (int)context.Application["globalResult"];
            var localStack = (Stack<int>)context.Session["localStack"];
            if (localStack.Count == 0)
            {
                context.Response.Write("{\"result\": " + globalResult + "}");
            }
            else
            {
                int stackTop = localStack.Peek();
                context.Response.Write("{\"result\": " + (globalResult + stackTop) + "}");
            }
        }

        private void HandlePost(HttpContext context)
        {
            string resultParam = context.Request.Params["RESULT"];
            if (int.TryParse(resultParam, out int newValue))
            {
                context.Application["globalResult"] = newValue;
                context.Response.Write($"{{\"success\": \"RESULT updated to {newValue}\"}}");
            }
            else
            {
                context.Response.StatusCode = 400;
                context.Response.Write("{\"error\": \"Invalid RESULT parameter\"}");
            }
        }

        private void HandlePut(HttpContext context)
        {
            var localStack = (Stack<int>)context.Session["localStack"];
            string addParam = context.Request.Params["ADD"];

            if (int.TryParse(addParam, out int valueToAdd))
            {
                localStack.Push(valueToAdd);
                context.Response.Write($"{{\"success\": \"Value {valueToAdd} added to your stack\"}}");
            }
            else
            {
                context.Response.StatusCode = 400;
                context.Response.Write("{\"error\": \"Invalid ADD parameter\"}");
            }
        }

        private void HandleDelete(HttpContext context)
        {
            var localStack = (Stack<int>)context.Session["localStack"];

            if (localStack.Count > 0)
            {
                int poppedValue = localStack.Pop();

                context.Response.Write($"{{\"success\": \"Popped {poppedValue} from your stack\"}}");
            }
            else
            {
                context.Response.StatusCode = 400;
                context.Response.Write("{\"error\": \"Your stack is empty!\"}");
            }
        }
    }
}