using BusinessLogic.IServices;
using Microsoft.Extensions.Configuration;
using System.Net;
using System.Net.Mail;

namespace BusinessLogic.Services
{
    public class EmailService(IConfiguration configuration) : IEmailService
    {
        private readonly IConfiguration _config = configuration;
        public void Send(string toEmail, string subject, string htmlMessage)
        {
            try
            {
                var host = _config["EmailSettings:Host"];
                var portStr = _config["EmailSettings:Port"];
                if (string.IsNullOrWhiteSpace(host) || !int.TryParse(portStr, out var port))
                {
                    Console.WriteLine($"[EmailService] Cảnh báo: EmailSettings chưa được cấu hình Host/Port. Bỏ qua việc gửi email tới {toEmail}.");
                    return;
                }

                var username = _config["EmailSettings:Username"] ?? "";
                var password = _config["EmailSettings:Password"] ?? "";
                var fromEmail = _config["EmailSettings:From"] ?? "no-reply@evcharging.vn";
                bool.TryParse(_config["EmailSettings:EnableSSL"], out var enableSsl);

                using SmtpClient client = new(host, port)
                {
                    Credentials = new NetworkCredential(username, password),
                    EnableSsl = enableSsl
                };
                var mail = new MailMessage
                {
                    From = new MailAddress(fromEmail, "EV Charging Station Management System"),
                    To = { toEmail },
                    Subject = subject,
                    Body = htmlMessage,
                    IsBodyHtml = true,
                };

                client.Send(mail);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[EmailService] Lỗi khi gửi email: {ex.Message}");
            }
        }
    }
}
