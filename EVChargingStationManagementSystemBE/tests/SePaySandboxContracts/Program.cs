using Common.Helper;
using System.Text.Json;
using System.Security.Cryptography;
using System.Text;
using System.Net;

var owner = Guid.Parse("11111111-2222-3333-4444-555555555555");
int passed = 0;
void Check(bool ok, string name) { if (!ok) throw new Exception(name); Console.WriteLine("PASS " + name); passed++; }
string Order(string status="CAPTURED", string amount="12000", string currency="VND", string invoice="EVTEST", string? customer=null, string transaction="APPROVED") => JsonSerializer.Serialize(new {
    order_invoice_number=invoice, customer_id=customer??owner.ToString(), order_status=status, order_amount=amount, order_currency=currency,
    transactions=new[]{new {transaction_type="PAYMENT", transaction_status=transaction,transaction_currency="VND",transaction_amount="12000"}} });
bool Paid(string json) { using var doc=JsonDocument.Parse(json); return SePaySandboxHelper.IsPaid(doc.RootElement,"EVTEST",owner,12000); }
Check(Paid(Order()),"captured exact owner invoice amount and approved transaction");
Check(!Paid(Order(status:"AUTHENTICATION_NOT_NEEDED")),"pending cannot settle");
Check(!Paid(Order(status:"CANCELLED")),"cancelled cannot settle");
Check(!Paid(Order(amount:"11999")),"wrong amount cannot settle");
Check(!Paid(Order(currency:"USD")),"wrong currency cannot settle");
Check(!Paid(Order(invoice:"OTHER")),"wrong invoice cannot settle");
Check(!Paid(Order(customer:Guid.NewGuid().ToString())),"wrong owner cannot settle");
Check(!Paid(Order(transaction:"DECLINED")),"declined transaction cannot settle");
Check(!Paid("{}"),"missing payload cannot settle");
Check(!Paid("[]"),"malformed order cannot settle");
var form=SePaySandboxHelper.CheckoutForm("SP-TEST-TEST","fake-secret","EVTEST",owner,12000);
var expected=Convert.ToBase64String(HMACSHA256.HashData(Encoding.UTF8.GetBytes("fake-secret"),Encoding.UTF8.GetBytes($"order_amount=12000,merchant=SP-TEST-TEST,currency=VND,operation=PURCHASE,order_description=EV Charging - Sandbox (tien gia),order_invoice_number=EVTEST,customer_id={owner},payment_method=CARD")));
Check(form.Contains(WebUtility.HtmlEncode(expected)),"signature follows documented ordered raw fields");
Check(form.Contains("https://pay-sandbox.sepay.vn/v1/checkout/init") && !form.Contains("fake-secret"),"sandbox only no secret in browser form");
Check(SePaySandboxHelper.CheckoutForm("<unsafe>","key","\"bad",owner,1).Contains("&lt;unsafe&gt;"),"HTML encoded input values");
if (args.Length==2) {
    using var config=JsonDocument.Parse(File.ReadAllText(args[0])); var s=config.RootElement.GetProperty("SePay");
    var invoice="EVPROBE"+Guid.NewGuid().ToString("N").ToUpperInvariant();
    File.WriteAllText(args[1],SePaySandboxHelper.CheckoutForm(s.GetProperty("GatewayMerchantId").GetString()!,s.GetProperty("GatewaySecretKey").GetString()!,invoice,owner,12000));
    Console.WriteLine("Probe invoice: "+invoice);
}
if (args.Length==1) {
    using var document=JsonDocument.Parse(File.ReadAllText(args[0]));
    var order=document.RootElement;
    Check(SePaySandboxHelper.IsPaid(order, order.GetProperty("order_invoice_number").GetString()!, owner, 12000),
        "actual sandbox CAPTURED response satisfies reconciliation contract");
}
Console.WriteLine($"{passed} PASS, 0 FAIL");
