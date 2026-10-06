using Infrastructure.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Infrastructure.Data.Seed
{
    public static class ConnectorSeed
    {
        public static List<Connector> GetConnectors() =>
        [
            new Connector
        {
            Id = Guid.Parse("cccccccc-cccc-cccc-cccc-cccccccccccc"),
            ConnectorName = "Connector A1",
            IsPluggedIn = false,
            IsLocked = false,
            Status = "Available",
            CreatedAt = new DateTime(2025, 1, 1),
            UpdatedAt = new DateTime(2025, 1, 1),
            IsDeleted = false,
            ChargingPostId = Guid.Parse("99999999-9999-9999-9999-999999999999") // Post A1
        }
        ];
    }

}
