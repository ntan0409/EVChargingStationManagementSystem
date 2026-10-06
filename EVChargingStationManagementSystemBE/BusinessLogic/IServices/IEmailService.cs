namespace BusinessLogic.IServices
{
    public interface IEmailService
    {
        void Send(string toEmail, string subject, string htmlMessage);
    }
}
