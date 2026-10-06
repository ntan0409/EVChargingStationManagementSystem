using System;
using System.ComponentModel.DataAnnotations;

namespace Common.DTOs.FeedbackDto
{
    public class FeedbackUpdateStatusDto
    {
        [Required]
        public Guid Id { get; set; }

        public bool IsResolved { get; set; }
    }
}
