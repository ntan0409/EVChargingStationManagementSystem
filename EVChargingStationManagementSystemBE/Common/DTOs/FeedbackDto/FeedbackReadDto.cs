using System;

namespace Common.DTOs.FeedbackDto
{
    public class FeedbackReadDto
    {
        public Guid Id { get; set; }
        public Guid AccountId { get; set; }
        public string Subject { get; set; }
        public double Stars { get; set; }
        public string Message { get; set; }
        public DateTime CreatedAt { get; set; }
        public bool IsResolved { get; set; }
    }
}
