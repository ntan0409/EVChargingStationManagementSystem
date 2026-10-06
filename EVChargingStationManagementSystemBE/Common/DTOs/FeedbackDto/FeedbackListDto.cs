using System;

namespace Common.DTOs.FeedbackDto
{
    public class FeedbackListDto
    {
        public Guid Id { get; set; }
        public string Subject { get; set; }
        public double Stars { get; set; }
        public DateTime CreatedAt { get; set; }
        public bool IsResolved { get; set; }
    }
}
