using Common.Enum.Connector;
using System.Text.Json.Serialization;

namespace Common.DTOs.ConnectorDto
{
    public class ConnectorViewListDto
    {
        public Guid Id { get; set; }
        public string ConnectorName { get; set; } = string.Empty;

        [JsonConverter(typeof(JsonStringEnumConverter))]
        public ConnectorStatus Status { get; set; } = ConnectorStatus.Unknown;
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public Guid ChargingPostId { get; set; }
    }
}
