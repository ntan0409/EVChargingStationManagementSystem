using Common.DTOs.ChargingPostDto;
using Common.Enum.ChargingStation;
using System.Text.Json.Serialization;

namespace Common.DTOs.ChargingStationDto
{
    public class ChargingStationsViewDetailDto
    {
        public Guid Id { get; set; }
        public string StationName { get; set; } = string.Empty;
        public string Location { get; set; } = string.Empty;
        public string Province { get; set; } = string.Empty;
        public string Latitude { get; set; } = string.Empty;
        public string Longitude { get; set; } = string.Empty;
        public int TotalBikeChargingPosts { get; set; }
        public int AvailableBikeChargingPosts { get; set; }
        public int TotalCarChargingPosts { get; set; }
        public int AvailableCarChargingPosts { get; set; }
        public int TotalBikeConnectors { get; set; }
        public int AvailableBikeConnectors { get; set; }
        public int TotalCarChargingConnectors { get; set; }
        public int AvailableCarConnectors { get; set; }

        [JsonConverter(typeof(JsonStringEnumConverter))]
        public ChargingStationStatus Status { get; set; } = ChargingStationStatus.Unknown;
        public Guid OperatorId { get; set; }
        public string? OperatorName { get; set; } = string.Empty;
        public ICollection<ChargingPostViewListDto> ChargingPosts { get; set; } = [];
    }
}
