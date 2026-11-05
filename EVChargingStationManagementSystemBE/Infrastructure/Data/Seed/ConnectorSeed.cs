using Infrastructure.Models;
using System;
using System.Collections.Generic;

namespace Infrastructure.Data.Seed
{
    public static class ConnectorSeed
    {
        public static List<Connector> GetConnectors()
        {
            var list = new List<Connector>
            {
                // Station Hanoi - Post A1
                new Connector
                {
                    Id = Guid.Parse("cccccccc-cccc-cccc-cccc-cccccccccccc"),
                    ConnectorName = "Cổng sạc A1",
                    IsPluggedIn = false,
                    IsLocked = false,
                    Status = "Available",
                    CreatedAt = new DateTime(2025, 1, 1),
                    UpdatedAt = new DateTime(2025, 1, 1),
                    IsDeleted = false,
                    ChargingPostId = Guid.Parse("99999999-9999-9999-9999-999999999999")
                },
                new Connector
                {
                    Id = Guid.Parse("cccccccc-cccc-cccc-cccc-cccccccccccd"),
                    ConnectorName = "Cổng sạc A2",
                    IsPluggedIn = false,
                    IsLocked = false,
                    Status = "Available",
                    CreatedAt = new DateTime(2025, 1, 1),
                    UpdatedAt = new DateTime(2025, 1, 1),
                    IsDeleted = false,
                    ChargingPostId = Guid.Parse("99999999-9999-9999-9999-999999999999")
                }
            };

            // 27 Posts in HCM (hex 0x01 to 0x1b)
            int connIndex = 1;
            for (int postNum = 1; postNum <= 27; postNum++)
            {
                var postId = Guid.Parse($"20000000-0000-0000-0000-{postNum:x12}");

                // 2 connectors per post
                for (int c = 1; c <= 2; c++)
                {
                    var connId = Guid.Parse($"30000000-0000-0000-0000-{connIndex:x12}");
                    list.Add(new Connector
                    {
                        Id = connId,
                        ConnectorName = $"Cổng sạc {c}",
                        IsPluggedIn = false,
                        IsLocked = false,
                        Status = "Available",
                        CreatedAt = new DateTime(2025, 1, 1),
                        UpdatedAt = new DateTime(2025, 1, 1),
                        IsDeleted = false,
                        ChargingPostId = postId
                    });
                    connIndex++;
                }
            }

            return list;
        }
    }
}
