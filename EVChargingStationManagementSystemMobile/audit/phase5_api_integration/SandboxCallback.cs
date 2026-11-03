using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace Phase5Integration;

internal static class SandboxCallback
{
    internal const string IpnPath = "/api/Payment/vnpay/ipn";
    internal const string ReturnPath = "/api/Payment/vnpay/return";

    internal static async Task<int> Run(HttpClient callback, HttpClient customer, Uri origin, Guid sessionId, Uri checkout, EVCSMSContext db)
    {
        using var deadline = new CancellationTokenSource(TimeSpan.FromMinutes(45));
        using var listener = new HttpListener();
        listener.Prefixes.Add("http://127.0.0.1:5398/");
        listener.Start();
        using var publicClient = new HttpClient { Timeout = TimeSpan.FromSeconds(15) };
        var relay = Relay(listener, callback, deadline.Token);
        try
        {
            using var probe = await publicClient.GetAsync(new Uri(origin, IpnPath), deadline.Token);
            var rejection = await probe.Content.ReadFromJsonAsync<JsonElement>(deadline.Token);
            if (!probe.IsSuccessStatusCode || rejection.GetProperty("RspCode").GetString() != "97")
                throw new InvalidOperationException("Public IPN did not reject the unsigned probe.");
            using var returned = await publicClient.GetAsync(new Uri(origin, ReturnPath), deadline.Token);
            returned.EnsureSuccessStatusCode();
            Console.WriteLine("IPN: " + new Uri(origin, IpnPath));
            Console.WriteLine("RETURN: " + new Uri(origin, ReturnPath));
            Console.WriteLine("CHECKOUT: " + checkout);
            Console.WriteLine("Waiting up to 45 minutes for a Sandbox IPN.");
            using var poll = new PeriodicTimer(TimeSpan.FromSeconds(3));
            while (await poll.WaitForNextTickAsync(deadline.Token))
            {
                var quote = await customer.GetFromJsonAsync<JsonElement>("/api/Payment/session/" + sessionId, deadline.Token);
                var status = quote.GetProperty("data").GetProperty("payment").GetProperty("status").GetString();
                if (status == "Initiated") continue;
                Console.WriteLine("Sandbox payment status: " + status);
                if (status != "Successed") return 1;
                var payment = quote.GetProperty("data").GetProperty("payment");
                var paymentId = payment.GetProperty("id").GetGuid();
                var ledger = await db.Transactions.AsNoTracking()
                    .Where(transaction => transaction.PaymentId == paymentId)
                    .SingleAsync(deadline.Token);
                if (ledger.Status != "Completed" || ledger.Amount != payment.GetProperty("amount").GetDecimal() ||
                    quote.GetProperty("data").GetProperty("sessionStatus").GetString() != "Paid")
                    throw new InvalidOperationException("Sandbox settlement does not match the payment and charging session.");
                Console.WriteLine("Verified one completed ledger with matching amount and a Paid charging session.");
                return 0;
            }
            return 1;
        }
        catch (OperationCanceledException) when (deadline.IsCancellationRequested)
        {
            Console.WriteLine("Sandbox verification timed out.");
            return 1;
        }
        finally
        {
            await deadline.CancelAsync();
            await relay;
        }
    }

    private static async Task Relay(HttpListener listener, HttpClient callback, CancellationToken cancellation)
    {
        while (!cancellation.IsCancellationRequested)
        {
            HttpListenerContext context;
            try { context = await listener.GetContextAsync().WaitAsync(cancellation); }
            catch (OperationCanceledException) when (cancellation.IsCancellationRequested) { return; }
            try
            {
                var path = context.Request.Url?.AbsolutePath;
                if (context.Request.HttpMethod != "GET" || (path != IpnPath && path != ReturnPath))
                {
                    context.Response.StatusCode = 404;
                    continue;
                }
                using var result = await callback.GetAsync(path + context.Request.Url!.Query, cancellation);
                context.Response.StatusCode = (int)result.StatusCode;
                context.Response.ContentType = result.Content.Headers.ContentType?.ToString();
                await result.Content.CopyToAsync(context.Response.OutputStream, cancellation);
            }
            catch (Exception ex) when (ex is IOException or HttpRequestException or HttpListenerException or OperationCanceledException)
            {
                if (cancellation.IsCancellationRequested) return;
            }
            finally { context.Response.Close(); }
        }
    }
}
