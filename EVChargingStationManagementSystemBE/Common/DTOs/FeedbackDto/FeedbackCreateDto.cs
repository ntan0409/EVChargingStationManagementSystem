using System;
using System.ComponentModel.DataAnnotations;

namespace Common.DTOs.FeedbackDto
{
    public class FeedbackCreateDto
    {

        [Required(ErrorMessage = "Subject không được để trống")]
        [StringLength(200, ErrorMessage = "Subject tối đa 200 ký tự")]
        public string Subject { get; set; }

        [Range(1, 5, ErrorMessage = "Stars phải nằm trong khoảng 1 - 5")]
        public double Stars { get; set; }

        [Required(ErrorMessage = "Message không được để trống")]
        [StringLength(1000, ErrorMessage = "Message tối đa 1000 ký tự")]
        public string Message { get; set; }
    }
}
