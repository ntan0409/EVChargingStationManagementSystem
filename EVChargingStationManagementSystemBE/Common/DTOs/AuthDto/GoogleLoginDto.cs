namespace Common.DTOs.AuthDto
{
    public class GoogleLoginDto
    {
        [System.ComponentModel.DataAnnotations.Required]
        public string IdToken { get; set; } = string.Empty;
    }
}
