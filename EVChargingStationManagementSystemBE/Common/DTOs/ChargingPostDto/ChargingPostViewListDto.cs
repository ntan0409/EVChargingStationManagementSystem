using Common.Enum.ChargingPost;
using Common.Enum.VehicleModel;
using System.Text.Json.Serialization;

namespace Common.DTOs.ChargingPostDto
{
    public class ChargingPostViewListDto
    {
        public Guid Id { get; set; }
        public string PostName { get; set; } = string.Empty;
        public string ConnectorType { get; set; } = string.Empty;

        [JsonConverter(typeof(JsonStringEnumConverter))]
        public VehicleTypeEnum VehicleTypeSupported { get; set; } = VehicleTypeEnum.Unknown;
        public int MaxPowerKw { get; set; }
        public int TotalConnectors { get; set; }

        [JsonConverter(typeof(JsonStringEnumConverter))]
        public ChargingPostStatus Status { get; set; } = ChargingPostStatus.Unknown;
        public Guid StationId { get; set; }

        //public ICollection<ChargingSession> ChargingSessions { get; set; } = [];
        //public ICollection<PowerOutputKWPerPost> PowerOutputKWPerPosts { get; set; } = [];
    }
}
