using Infrastructure.Models;
using System;
using System.Collections.Generic;

namespace Infrastructure.Data.Seed
{
    public static class ChargingPostSeed
    {
        public static List<ChargingPost> GetChargingPosts() =>
        [
            // Station Hanoi (55555555-5555-5555-5555-555555555555)
            new ChargingPost
            {
                Id = Guid.Parse("99999999-9999-9999-9999-999999999999"),
                PostName = "Post A1 (Car 50kW)",
                ConnectorType = "Type2",
                VehicleTypeSupported = "Car",
                MaxPowerKw = 50,
                TotalConnectors = 2,
                AvailableConnectors = 2,
                Status = "Available",
                CreatedAt = new DateTime(2025, 1, 1),
                UpdatedAt = new DateTime(2025, 1, 1),
                IsDeleted = false,
                StationId = Guid.Parse("55555555-5555-5555-5555-555555555555")
            },

            // Station 6666... (Vincom Đồng Khởi - Quận 1)
            new ChargingPost
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000001"),
                PostName = "Trụ Ô tô 1 (60kW)",
                ConnectorType = "CCS2",
                VehicleTypeSupported = "Car",
                MaxPowerKw = 60,
                TotalConnectors = 2,
                AvailableConnectors = 2,
                Status = "Available",
                CreatedAt = new DateTime(2025, 1, 1),
                UpdatedAt = new DateTime(2025, 1, 1),
                IsDeleted = false,
                StationId = Guid.Parse("66666666-6666-6666-6666-666666666666")
            },
            new ChargingPost
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000002"),
                PostName = "Trụ Ô tô 2 (120kW SuperCharge)",
                ConnectorType = "CCS2",
                VehicleTypeSupported = "Car",
                MaxPowerKw = 120,
                TotalConnectors = 2,
                AvailableConnectors = 2,
                Status = "Available",
                CreatedAt = new DateTime(2025, 1, 1),
                UpdatedAt = new DateTime(2025, 1, 1),
                IsDeleted = false,
                StationId = Guid.Parse("66666666-6666-6666-6666-666666666666")
            },

            // Station ...0001 (Landmark 81 - Bình Thạnh)
            new ChargingPost
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000003"),
                PostName = "Trụ Ô tô 1 (60kW)",
                ConnectorType = "CCS2",
                VehicleTypeSupported = "Car",
                MaxPowerKw = 60,
                TotalConnectors = 2,
                AvailableConnectors = 2,
                Status = "Available",
                CreatedAt = new DateTime(2025, 1, 1),
                UpdatedAt = new DateTime(2025, 1, 1),
                IsDeleted = false,
                StationId = Guid.Parse("10000000-0000-0000-0000-000000000001")
            },
            new ChargingPost
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000004"),
                PostName = "Trụ Ô tô 2 (150kW UltraFast)",
                ConnectorType = "CCS2",
                VehicleTypeSupported = "Car",
                MaxPowerKw = 150,
                TotalConnectors = 2,
                AvailableConnectors = 2,
                Status = "Available",
                CreatedAt = new DateTime(2025, 1, 1),
                UpdatedAt = new DateTime(2025, 1, 1),
                IsDeleted = false,
                StationId = Guid.Parse("10000000-0000-0000-0000-000000000001")
            },
            new ChargingPost
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000005"),
                PostName = "Trụ Xe Máy 1 (7kW)",
                ConnectorType = "Type2",
                VehicleTypeSupported = "Bike",
                MaxPowerKw = 7,
                TotalConnectors = 2,
                AvailableConnectors = 2,
                Status = "Available",
                CreatedAt = new DateTime(2025, 1, 1),
                UpdatedAt = new DateTime(2025, 1, 1),
                IsDeleted = false,
                StationId = Guid.Parse("10000000-0000-0000-0000-000000000001")
            },

            // Station ...0002 (Crescent Mall Phú Mỹ Hưng - Quận 7)
            new ChargingPost
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000006"),
                PostName = "Trụ Ô tô 1 (60kW)",
                ConnectorType = "CCS2",
                VehicleTypeSupported = "Car",
                MaxPowerKw = 60,
                TotalConnectors = 2,
                AvailableConnectors = 2,
                Status = "Available",
                CreatedAt = new DateTime(2025, 1, 1),
                UpdatedAt = new DateTime(2025, 1, 1),
                IsDeleted = false,
                StationId = Guid.Parse("10000000-0000-0000-0000-000000000002")
            },
            new ChargingPost
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000007"),
                PostName = "Trụ Ô tô 2 (120kW SuperCharge)",
                ConnectorType = "CCS2",
                VehicleTypeSupported = "Car",
                MaxPowerKw = 120,
                TotalConnectors = 2,
                AvailableConnectors = 2,
                Status = "Available",
                CreatedAt = new DateTime(2025, 1, 1),
                UpdatedAt = new DateTime(2025, 1, 1),
                IsDeleted = false,
                StationId = Guid.Parse("10000000-0000-0000-0000-000000000002")
            },
            new ChargingPost
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000008"),
                PostName = "Trụ Xe Máy 1 (7kW)",
                ConnectorType = "Type2",
                VehicleTypeSupported = "Bike",
                MaxPowerKw = 7,
                TotalConnectors = 2,
                AvailableConnectors = 2,
                Status = "Available",
                CreatedAt = new DateTime(2025, 1, 1),
                UpdatedAt = new DateTime(2025, 1, 1),
                IsDeleted = false,
                StationId = Guid.Parse("10000000-0000-0000-0000-000000000002")
            },

            // Station ...0003 (Menas Mall Sân Bay - Tân Bình)
            new ChargingPost
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000009"),
                PostName = "Trụ Ô tô 1 (60kW)",
                ConnectorType = "CCS2",
                VehicleTypeSupported = "Car",
                MaxPowerKw = 60,
                TotalConnectors = 2,
                AvailableConnectors = 2,
                Status = "Available",
                CreatedAt = new DateTime(2025, 1, 1),
                UpdatedAt = new DateTime(2025, 1, 1),
                IsDeleted = false,
                StationId = Guid.Parse("10000000-0000-0000-0000-000000000003")
            },
            new ChargingPost
            {
                Id = Guid.Parse("20000000-0000-0000-0000-00000000000a"),
                PostName = "Trụ Ô tô 2 (120kW SuperCharge)",
                ConnectorType = "CCS2",
                VehicleTypeSupported = "Car",
                MaxPowerKw = 120,
                TotalConnectors = 2,
                AvailableConnectors = 2,
                Status = "Available",
                CreatedAt = new DateTime(2025, 1, 1),
                UpdatedAt = new DateTime(2025, 1, 1),
                IsDeleted = false,
                StationId = Guid.Parse("10000000-0000-0000-0000-000000000003")
            },

            // Station ...0004 (Vincom Thảo Điền - TP. Thủ Đức)
            new ChargingPost
            {
                Id = Guid.Parse("20000000-0000-0000-0000-00000000000b"),
                PostName = "Trụ Ô tô 1 (60kW)",
                ConnectorType = "CCS2",
                VehicleTypeSupported = "Car",
                MaxPowerKw = 60,
                TotalConnectors = 2,
                AvailableConnectors = 2,
                Status = "Available",
                CreatedAt = new DateTime(2025, 1, 1),
                UpdatedAt = new DateTime(2025, 1, 1),
                IsDeleted = false,
                StationId = Guid.Parse("10000000-0000-0000-0000-000000000004")
            },
            new ChargingPost
            {
                Id = Guid.Parse("20000000-0000-0000-0000-00000000000c"),
                PostName = "Trụ Ô tô 2 (150kW UltraFast)",
                ConnectorType = "CCS2",
                VehicleTypeSupported = "Car",
                MaxPowerKw = 150,
                TotalConnectors = 2,
                AvailableConnectors = 2,
                Status = "Available",
                CreatedAt = new DateTime(2025, 1, 1),
                UpdatedAt = new DateTime(2025, 1, 1),
                IsDeleted = false,
                StationId = Guid.Parse("10000000-0000-0000-0000-000000000004")
            },
            new ChargingPost
            {
                Id = Guid.Parse("20000000-0000-0000-0000-00000000000d"),
                PostName = "Trụ Xe Máy 1 (7kW)",
                ConnectorType = "Type2",
                VehicleTypeSupported = "Bike",
                MaxPowerKw = 7,
                TotalConnectors = 2,
                AvailableConnectors = 2,
                Status = "Available",
                CreatedAt = new DateTime(2025, 1, 1),
                UpdatedAt = new DateTime(2025, 1, 1),
                IsDeleted = false,
                StationId = Guid.Parse("10000000-0000-0000-0000-000000000004")
            },

            // Station ...0005 (KCNC FPT - TP. Thủ Đức)
            new ChargingPost
            {
                Id = Guid.Parse("20000000-0000-0000-0000-00000000000e"),
                PostName = "Trụ Ô tô 1 (60kW)",
                ConnectorType = "CCS2",
                VehicleTypeSupported = "Car",
                MaxPowerKw = 60,
                TotalConnectors = 2,
                AvailableConnectors = 2,
                Status = "Available",
                CreatedAt = new DateTime(2025, 1, 1),
                UpdatedAt = new DateTime(2025, 1, 1),
                IsDeleted = false,
                StationId = Guid.Parse("10000000-0000-0000-0000-000000000005")
            },
            new ChargingPost
            {
                Id = Guid.Parse("20000000-0000-0000-0000-00000000000f"),
                PostName = "Trụ Ô tô 2 (120kW SuperCharge)",
                ConnectorType = "CCS2",
                VehicleTypeSupported = "Car",
                MaxPowerKw = 120,
                TotalConnectors = 2,
                AvailableConnectors = 2,
                Status = "Available",
                CreatedAt = new DateTime(2025, 1, 1),
                UpdatedAt = new DateTime(2025, 1, 1),
                IsDeleted = false,
                StationId = Guid.Parse("10000000-0000-0000-0000-000000000005")
            },
            new ChargingPost
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000010"),
                PostName = "Trụ Xe Máy 1 (7kW)",
                ConnectorType = "Type2",
                VehicleTypeSupported = "Bike",
                MaxPowerKw = 7,
                TotalConnectors = 2,
                AvailableConnectors = 2,
                Status = "Available",
                CreatedAt = new DateTime(2025, 1, 1),
                UpdatedAt = new DateTime(2025, 1, 1),
                IsDeleted = false,
                StationId = Guid.Parse("10000000-0000-0000-0000-000000000005")
            },

            // Station ...0006 (Vạn Hạnh Mall - Quận 10)
            new ChargingPost
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000011"),
                PostName = "Trụ Ô tô 1 (60kW)",
                ConnectorType = "CCS2",
                VehicleTypeSupported = "Car",
                MaxPowerKw = 60,
                TotalConnectors = 2,
                AvailableConnectors = 2,
                Status = "Available",
                CreatedAt = new DateTime(2025, 1, 1),
                UpdatedAt = new DateTime(2025, 1, 1),
                IsDeleted = false,
                StationId = Guid.Parse("10000000-0000-0000-0000-000000000006")
            },
            new ChargingPost
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000012"),
                PostName = "Trụ Ô tô 2 (120kW SuperCharge)",
                ConnectorType = "CCS2",
                VehicleTypeSupported = "Car",
                MaxPowerKw = 120,
                TotalConnectors = 2,
                AvailableConnectors = 2,
                Status = "Available",
                CreatedAt = new DateTime(2025, 1, 1),
                UpdatedAt = new DateTime(2025, 1, 1),
                IsDeleted = false,
                StationId = Guid.Parse("10000000-0000-0000-0000-000000000006")
            },

            // Station ...0007 (Aeon Mall Bình Tân)
            new ChargingPost
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000013"),
                PostName = "Trụ Ô tô 1 (60kW)",
                ConnectorType = "CCS2",
                VehicleTypeSupported = "Car",
                MaxPowerKw = 60,
                TotalConnectors = 2,
                AvailableConnectors = 2,
                Status = "Available",
                CreatedAt = new DateTime(2025, 1, 1),
                UpdatedAt = new DateTime(2025, 1, 1),
                IsDeleted = false,
                StationId = Guid.Parse("10000000-0000-0000-0000-000000000007")
            },
            new ChargingPost
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000014"),
                PostName = "Trụ Ô tô 2 (120kW SuperCharge)",
                ConnectorType = "CCS2",
                VehicleTypeSupported = "Car",
                MaxPowerKw = 120,
                TotalConnectors = 2,
                AvailableConnectors = 2,
                Status = "Available",
                CreatedAt = new DateTime(2025, 1, 1),
                UpdatedAt = new DateTime(2025, 1, 1),
                IsDeleted = false,
                StationId = Guid.Parse("10000000-0000-0000-0000-000000000007")
            },
            new ChargingPost
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000015"),
                PostName = "Trụ Xe Máy 1 (7kW)",
                ConnectorType = "Type2",
                VehicleTypeSupported = "Bike",
                MaxPowerKw = 7,
                TotalConnectors = 2,
                AvailableConnectors = 2,
                Status = "Available",
                CreatedAt = new DateTime(2025, 1, 1),
                UpdatedAt = new DateTime(2025, 1, 1),
                IsDeleted = false,
                StationId = Guid.Parse("10000000-0000-0000-0000-000000000007")
            },

            // Station ...0008 (Giga Mall Thủ Đức)
            new ChargingPost
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000016"),
                PostName = "Trụ Ô tô 1 (60kW)",
                ConnectorType = "CCS2",
                VehicleTypeSupported = "Car",
                MaxPowerKw = 60,
                TotalConnectors = 2,
                AvailableConnectors = 2,
                Status = "Available",
                CreatedAt = new DateTime(2025, 1, 1),
                UpdatedAt = new DateTime(2025, 1, 1),
                IsDeleted = false,
                StationId = Guid.Parse("10000000-0000-0000-0000-000000000008")
            },
            new ChargingPost
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000017"),
                PostName = "Trụ Ô tô 2 (150kW UltraFast)",
                ConnectorType = "CCS2",
                VehicleTypeSupported = "Car",
                MaxPowerKw = 150,
                TotalConnectors = 2,
                AvailableConnectors = 2,
                Status = "Available",
                CreatedAt = new DateTime(2025, 1, 1),
                UpdatedAt = new DateTime(2025, 1, 1),
                IsDeleted = false,
                StationId = Guid.Parse("10000000-0000-0000-0000-000000000008")
            },

            // Station ...0009 (Vincom Phan Văn Trị - Gò Vấp)
            new ChargingPost
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000018"),
                PostName = "Trụ Ô tô 1 (60kW)",
                ConnectorType = "CCS2",
                VehicleTypeSupported = "Car",
                MaxPowerKw = 60,
                TotalConnectors = 2,
                AvailableConnectors = 2,
                Status = "Available",
                CreatedAt = new DateTime(2025, 1, 1),
                UpdatedAt = new DateTime(2025, 1, 1),
                IsDeleted = false,
                StationId = Guid.Parse("10000000-0000-0000-0000-000000000009")
            },
            new ChargingPost
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000019"),
                PostName = "Trụ Ô tô 2 (120kW SuperCharge)",
                ConnectorType = "CCS2",
                VehicleTypeSupported = "Car",
                MaxPowerKw = 120,
                TotalConnectors = 2,
                AvailableConnectors = 2,
                Status = "Available",
                CreatedAt = new DateTime(2025, 1, 1),
                UpdatedAt = new DateTime(2025, 1, 1),
                IsDeleted = false,
                StationId = Guid.Parse("10000000-0000-0000-0000-000000000009")
            },

            // Station ...0010 (Đầm Sen Park - Quận 11)
            new ChargingPost
            {
                Id = Guid.Parse("20000000-0000-0000-0000-00000000001a"),
                PostName = "Trụ Ô tô 1 (60kW)",
                ConnectorType = "CCS2",
                VehicleTypeSupported = "Car",
                MaxPowerKw = 60,
                TotalConnectors = 2,
                AvailableConnectors = 2,
                Status = "Available",
                CreatedAt = new DateTime(2025, 1, 1),
                UpdatedAt = new DateTime(2025, 1, 1),
                IsDeleted = false,
                StationId = Guid.Parse("10000000-0000-0000-0000-000000000010")
            },
            new ChargingPost
            {
                Id = Guid.Parse("20000000-0000-0000-0000-00000000001b"),
                PostName = "Trụ Ô tô 2 (120kW SuperCharge)",
                ConnectorType = "CCS2",
                VehicleTypeSupported = "Car",
                MaxPowerKw = 120,
                TotalConnectors = 2,
                AvailableConnectors = 2,
                Status = "Available",
                CreatedAt = new DateTime(2025, 1, 1),
                UpdatedAt = new DateTime(2025, 1, 1),
                IsDeleted = false,
                StationId = Guid.Parse("10000000-0000-0000-0000-000000000010")
            }
        ];
    }
}
