using System.Globalization;
using System.Net;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

namespace Common.Helper;

public static class SePaySandboxHelper
{
    // Ordered exactly as specified by the SePay checkout signing contract.
    public static string CheckoutForm(string merchant, string secret, string invoice, Guid owner, decimal amount)
    {
        var fields = new Dictionary<string, string>
        {
            ["order_amount"] = amount.ToString("0", CultureInfo.InvariantCulture),
            ["merchant"] = merchant, ["currency"] = "VND", ["operation"] = "PURCHASE",
            ["order_description"] = "EV Charging - Sandbox (tien gia)",
            ["order_invoice_number"] = invoice, ["customer_id"] = owner.ToString(),
            ["payment_method"] = "CARD"
        };
        var signature = Convert.ToBase64String(HMACSHA256.HashData(Encoding.UTF8.GetBytes(secret),
            Encoding.UTF8.GetBytes(string.Join(",", fields.Select(f => $"{f.Key}={f.Value}")))));
        fields["signature"] = signature;
        var inputs = string.Concat(fields.Select(f => $"<input type=\"hidden\" name=\"{f.Key}\" value=\"{WebUtility.HtmlEncode(f.Value)}\">"));
        return "<!doctype html><html lang=\"vi\"><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">" +
            "<title>EV Charging - SePay Sandbox</title><body><h2>Thanh toán thử — tiền giả</h2>" +
            "<p>Chỉ dùng thông tin thẻ thử trên trang Sandbox. Sau khi hoàn tất, quay lại ứng dụng để xem kết quả.</p>" +
            "<form id=\"checkout\" method=\"post\" action=\"https://pay-sandbox.sepay.vn/v1/checkout/init\">" +
            inputs + "<button>Tiếp tục tới SePay Sandbox</button></form><script>document.getElementById('checkout').submit()</script></body></html>";
    }

    public static bool IsPaid(JsonElement order, string invoice, Guid owner, decimal amount)
    {
        static string? Text(JsonElement e, string key) => e.ValueKind == JsonValueKind.Object &&
            e.TryGetProperty(key, out var v) ? v.ToString() : null;
        static bool Money(JsonElement e, string key, decimal expected) =>
            decimal.TryParse(Text(e, key), NumberStyles.Number, CultureInfo.InvariantCulture, out var n) && n == expected;
        return order.ValueKind == JsonValueKind.Object && Text(order, "order_invoice_number") == invoice &&
            Guid.TryParse(Text(order, "customer_id"), out var customer) && customer == owner &&
            Text(order, "order_status") == "CAPTURED" && Text(order, "order_currency") == "VND" &&
            Money(order, "order_amount", amount) &&
            order.TryGetProperty("transactions", out var rows) && rows.ValueKind == JsonValueKind.Array &&
            rows.EnumerateArray().Any(t => Text(t, "transaction_type") == "PAYMENT" &&
                Text(t, "transaction_status") == "APPROVED" && Text(t, "transaction_currency") == "VND" &&
                Money(t, "transaction_amount", amount));
    }
}
