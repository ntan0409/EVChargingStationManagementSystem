using System.Security.Cryptography;
using System.Text;

namespace Common.Helper
{
    public static class PaymentHelper
    {
        public static string CreateHmac512(string key, string data)
        {
            using var hmac = new HMACSHA512(Encoding.UTF8.GetBytes(key));
            var hash = hmac.ComputeHash(Encoding.UTF8.GetBytes(data));
            return Convert.ToHexString(hash).ToUpperInvariant();
        }
        //Transaction Reference
        public static string GenerateTxnRef(Guid sessionId)
        {
            // 17 ký tự thời gian (UTC tới mili giây) + 3 ký tự ngẫu nhiên + sessionId
            // => 20 ký tự đầu (timestamp + random) luôn khác nhau giữa các lần gọi
            var ts17 = DateTime.UtcNow.ToString("yyyyMMddHHmmssfff"); // 17
            var rand3 = Guid.NewGuid().ToString("N")[..3]; // 3
            return $"{ts17}{rand3}{sessionId:N}"; // ví dụ: 20250202143015999abc439852bb9ddb4b50950f...
        }

        public static string GenerateReferenceCode(string transactionType)
        {
            // Chọn tiền tố theo loại giao dịch
            string prefix = transactionType?.ToUpper() switch
            {
                "ONLINEPAYMENT" => "ONL",
                "OFFLINEPAYMENT" => "OFF",
                "ADJUSMENT" => "ADJ",
                "REFUND" => "RFD",
                _ => "GEN" // mặc định nếu không khớp loại nào
            };

            var datePart = DateTime.UtcNow.ToString("yyyyMMdd");
            var randomPart = Guid.NewGuid().ToString("N").Substring(0, 6).ToUpper();

            return $"{prefix}-{datePart}-{randomPart}";
        }

        public static string CreateVnPayUrl(string baseUrl, Dictionary<string, string> parameters, string secret)
        {
            // Sắp xếp parameters theo key
            var sortedParams = new SortedDictionary<string, string>(parameters);

            // Tạo encoded string cho hash
            var encodedForHash = string.Join('&', sortedParams.Select(kvp => $"{kvp.Key}={Uri.EscapeDataString(kvp.Value)}"));

            // Tạo hash
            var secureHash = CreateHmac512(secret, encodedForHash);

            // Tạo query string
            var query = string.Join('&', sortedParams.Select(kvp => $"{kvp.Key}={Uri.EscapeDataString(kvp.Value)}"));

            // Tạo URL hoàn chỉnh
            return $"{baseUrl}?{query}&vnp_SecureHashType=HmacSHA512&vnp_SecureHash={secureHash}";
        }

        public static Dictionary<string, string> CreateVnPayParameters(
            string tmnCode,
            long amount,
            string txnRef,
            string orderInfo,
            string returnUrl,
            string ipAddress,
            string locale = "vn")
        {
            return new Dictionary<string, string>
            {
                ["vnp_Version"] = "2.1.0",
                ["vnp_Command"] = "pay",
                ["vnp_TmnCode"] = tmnCode,
                ["vnp_Amount"] = amount.ToString(),
                ["vnp_CreateDate"] = DateTime.UtcNow.ToString("yyyyMMddHHmmss"),
                ["vnp_CurrCode"] = "VND",
                ["vnp_ExpireDate"] = DateTime.Now.AddDays(1).ToString("yyyyMMddHHmmss"),
                ["vnp_IpAddr"] = ipAddress,
                ["vnp_Locale"] = locale,
                ["vnp_OrderInfo"] = orderInfo,
                ["vnp_OrderType"] = "other",
                ["vnp_ReturnUrl"] = returnUrl,
                ["vnp_TxnRef"] = txnRef
            };
        }

        public static string CreateDataString(IDictionary<string, string> queryParams)
        {
            if (queryParams == null || queryParams.Count == 0)
                return string.Empty;

            // Sử dụng Ordinal để đảm bảo thứ tự byte-wise, giống yêu cầu so khớp chữ ký
            var sorted = new SortedDictionary<string, string>(queryParams, StringComparer.Ordinal);

            // Lọc bỏ các khóa không có giá trị (null/empty)
            var parts = sorted
                .Where(kv => !string.IsNullOrEmpty(kv.Value))
                .Select(kv => $"{kv.Key}={kv.Value}");

            return string.Join("&", parts);
        }
    }
}
