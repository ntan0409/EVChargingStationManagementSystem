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
                var port = int.Parse(_config["EmailSettings:Port"]);
                using SmtpClient client = new(_config["EmailSettings:Host"], port)
                {
                    Credentials = new NetworkCredential(_config["EmailSettings:Username"], _config["EmailSettings:Password"]),
                    EnableSsl = bool.Parse(_config["EmailSettings:EnableSSL"])
                };
                var mail = new MailMessage
                {
                    From = new MailAddress(_config["EmailSettings:From"], "EV Charging Station Management System"),
                    To = { toEmail },
                    Subject = subject,
                    Body = htmlMessage,
                    IsBodyHtml = true,
                };

                client.Send(mail);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error sending email: {ex.Message}");
                throw;
            }
        }
    }
}
