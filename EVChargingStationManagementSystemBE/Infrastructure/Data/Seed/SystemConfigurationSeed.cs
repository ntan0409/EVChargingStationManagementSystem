using Infrastructure.Models;

namespace Infrastructure.Data.Seed
{
    public class SystemConfigurationSeed
    {
        public static List<SystemConfiguration> GetSystemConfigurations()
        {
            return [
                new (){
                    Id = 1,
                    Name = "PRICE_PER_kWH",
                    MinValue = 5000,
                    Description = "Mức giá vnd trên 1 KWH điện, giá trị chỉ hiệu lực khi lưu ở trường MinValue",
                    VersionNo = 1,
                    EffectedDateFrom = new DateTime(2025, 1, 1),
                    Unit = "VND",
                    CreatedAt = new DateTime(2024, 6, 1),
                    UpdatedAt = new DateTime(2024, 6, 1),
                    CreatedBy = Guid.Parse("11111111-1111-1111-1111-111111111111"),
                    UpdatedBy = Guid.Parse("11111111-1111-1111-1111-111111111111")
                },
                new (){
                    Id = 2,
                    Name = "POINT_PER_KWH",
                    MinValue = 1,
                    Description = "Tích điểm trên 1 KWH điện, giá trị chỉ hiệu lực khi lưu ở trường MinValue",
                    VersionNo = 1,
                    EffectedDateFrom = new DateTime(2025, 1, 1),
                    Unit = "point",
                    CreatedAt = new DateTime(2024, 6, 1),
                    UpdatedAt = new DateTime(2024, 6, 1),
                    CreatedBy = Guid.Parse("11111111-1111-1111-1111-111111111111"),
                    UpdatedBy = Guid.Parse("11111111-1111-1111-1111-111111111111")
                },
                new (){
                    Id = 3,
                    Name = "VAT",
                    MinValue = 10,
                    Description = "Mức thuế, giá trị chỉ hiệu lực khi lưu ở trường MinValue",
                    VersionNo = 1,
                    EffectedDateFrom = new DateTime(2025, 1, 1),
                    Unit = "%",
                    CreatedAt = new DateTime(2024, 6, 1),
                    UpdatedAt = new DateTime(2024, 6, 1),
                    CreatedBy = Guid.Parse("11111111-1111-1111-1111-111111111111"),
                    UpdatedBy = Guid.Parse("11111111-1111-1111-1111-111111111111")
                },
                new (){
                    Id = 4,
                    Name = "LOGIN_TOKEN_TIMEOUT",
                    MinValue = 720, // 30 days
                    Description = "Thời gian token login hiệu lực, giá trị chỉ hiệu lực khi lưu ở trường MinValue",
                    VersionNo = 1,
                    EffectedDateFrom = new DateTime(2025, 1, 1),
                    Unit = "Hours",
                    CreatedAt = new DateTime(2024, 6, 1),
                    UpdatedAt = new DateTime(2024, 6, 1),
                    CreatedBy = Guid.Parse("11111111-1111-1111-1111-111111111111"),
                    UpdatedBy = Guid.Parse("11111111-1111-1111-1111-111111111111")
                },
                new (){
                    Id = 5,
                    Name = "BOOKING_TIME_CANCEL_TRIGGER",
                    MinValue = 15,
                    Description = "Thời gian cancel booking nếu đến trễ hơn thời gian đặt ra, giá trị chỉ hiệu lực khi lưu ở trường MinValue",
                    VersionNo = 1,
                    EffectedDateFrom = new DateTime(2025, 1, 1),
                    Unit = "Minutes",
                    CreatedAt = new DateTime(2024, 6, 1),
                    UpdatedAt = new DateTime(2024, 6, 1),
                    CreatedBy = Guid.Parse("11111111-1111-1111-1111-111111111111"),
                    UpdatedBy = Guid.Parse("11111111-1111-1111-1111-111111111111")
                },
                 new(){
                 Id = 6,
                    Name = "CONNECTOR_LIMIT",
                    MinValue = 2,
                    Description = "Giới hạn tổng lượng cổng trên 1  trụ ",
                    VersionNo = 1,
                    EffectedDateFrom = new DateTime(2025, 1, 1),
                    Unit = "port",
                    CreatedAt = new DateTime(2024, 11, 6),
                    UpdatedAt = new DateTime(2024, 11, 6),
                    CreatedBy = Guid.Parse("11111111-1111-1111-1111-111111111111"),
                    UpdatedBy = Guid.Parse("11111111-1111-1111-1111-111111111111")
                }
            ];

        }
    }
}
