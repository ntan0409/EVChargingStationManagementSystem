-- EVCSMS classroom fixtures. All locations, account identities and capacities are demo values.
-- Run on the development LocalDB only. Existing rows are preserved.
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET ARITHABORT ON;
SET NUMERIC_ROUNDABORT OFF;
IF DB_NAME() NOT IN (N'EVCSMS', N'EVCSMS_TeamDemo') OR ISNULL(CONVERT(nvarchar(128), SERVERPROPERTY('IsLocalDB')), N'0') <> N'1'
    THROW 50001, 'Use the EVCSMS database on SQL Server LocalDB.', 1;

BEGIN TRANSACTION;
DECLARE @now datetime2 = SYSDATETIME();
DECLARE @staffRole uniqueidentifier = (SELECT Id FROM dbo.AspNetRoles WHERE NormalizedName = 'STAFF');
DECLARE @driverRole uniqueidentifier = (SELECT Id FROM dbo.AspNetRoles WHERE NormalizedName = 'EVDRIVER');
DECLARE @creator uniqueidentifier = (
    SELECT TOP (1) u.Id FROM dbo.AspNetUsers u
    JOIN dbo.AspNetUserRoles ur ON ur.UserId = u.Id
    JOIN dbo.AspNetRoles r ON r.Id = ur.RoleId
    WHERE r.NormalizedName = 'ADMIN' AND u.IsDeleted = 0 ORDER BY u.Id
);
IF @staffRole IS NULL OR @driverRole IS NULL OR @creator IS NULL
    THROW 50002, 'Apply the project migrations and ensure the seeded roles exist first.', 1;

DECLARE @sites TABLE (Number int PRIMARY KEY, District nvarchar(50), Province nvarchar(50), Lat varchar(15), Lon varchar(15));
INSERT @sites VALUES
    (1, N'Thủ Đức', N'TP. Hồ Chí Minh', N'10.8451', N'106.7781'),
    (2, N'Quận 7', N'TP. Hồ Chí Minh', N'10.7318', N'106.7218'),
    (3, N'Tân Bình', N'TP. Hồ Chí Minh', N'10.8006', N'106.6520'),
    (4, N'Biên Hòa', N'Đồng Nai', N'10.9460', N'106.8243'),
    (5, N'Thủ Dầu Một', N'Bình Dương', N'10.9817', N'106.6519'),
    (6, N'Ninh Kiều', N'Cần Thơ', N'10.0340', N'105.7802'),
    (7, N'Hải Châu', N'Đà Nẵng', N'16.0551', N'108.2208'),
    (8, N'Cầu Giấy', N'Hà Nội', N'21.0368', N'105.7880'),
    (9, N'Long Biên', N'Hà Nội', N'21.0420', N'105.9002'),
    (10, N'Lê Chân', N'Hải Phòng', N'20.8416', N'106.6787');
DECLARE @models TABLE (Number int PRIMARY KEY, ModelName nvarchar(100), Brand nvarchar(40), Battery int, Power int);
INSERT @models VALUES
    (1, N'VF 3', N'VinFast', 19, 25),
    (2, N'VF 5 Plus', N'VinFast', 37, 50),
    (3, N'VF 6 Eco', N'VinFast', 60, 80),
    (4, N'VF 6 Plus', N'VinFast', 60, 90),
    (5, N'VF 7 Eco', N'VinFast', 60, 90),
    (6, N'VF 7 Plus', N'VinFast', 75, 120),
    (7, N'VF 8 Eco', N'VinFast', 88, 120),
    (8, N'VF 8 Plus', N'VinFast', 88, 150),
    (9, N'VF 9 Eco', N'VinFast', 92, 150),
    (10, N'VF 9 Plus', N'VinFast', 123, 150),
    (11, N'Herio Green', N'VinFast', 37, 50),
    (12, N'Ioniq 5', N'Hyundai', 72, 120);

-- Reserved fixture IDs make repeated runs insert-only and prevent duplicate fixtures.
DECLARE @fixtures TABLE (Kind int, Number int, Id uniqueidentifier, PRIMARY KEY (Kind, Number));
INSERT @fixtures
SELECT k.Kind, n.Number, CONVERT(uniqueidentifier, CONCAT(
    '6de60000-8a51-4319-a', RIGHT(CONCAT('00', k.Kind), 3), '-',
    RIGHT(CONCAT('000000000000', n.Number), 12)))
FROM (VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10)) k(Kind)
CROSS JOIN (
    SELECT TOP (60) ROW_NUMBER() OVER (ORDER BY a.n,b.n) AS Number
    FROM (VALUES (0),(1),(2),(3),(4),(5)) a(n)
    CROSS JOIN (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) b(n)
) n;

DECLARE @accounts TABLE (Id uniqueidentifier PRIMARY KEY, RoleId uniqueidentifier, FullName nvarchar(100), Email nvarchar(100), Status varchar(20));
INSERT @accounts
SELECT f.Id, CASE f.Kind WHEN 1 THEN @staffRole ELSE @driverRole END,
       CONCAT(CASE f.Kind WHEN 1 THEN N'Nhân viên demo ' ELSE N'Tài xế demo ' END, s.District),
       CONCAT(CASE f.Kind WHEN 1 THEN 'staff' ELSE 'driver' END, s.Number, '@evcsms-demo.invalid'),
       CASE f.Kind WHEN 1 THEN 'Assigned' ELSE 'Active' END
FROM @sites s JOIN @fixtures f ON f.Number = s.Number AND f.Kind IN (1,2);

INSERT dbo.AspNetUsers (Id, Name, UserName, NormalizedUserName, Email, NormalizedEmail, EmailConfirmed,
    LoginType, Status, RegistrationDate, CreatedAt, UpdatedAt, IsDeleted,
    SecurityStamp, ConcurrencyStamp, PhoneNumberConfirmed, TwoFactorEnabled, LockoutEnabled, AccessFailedCount)
SELECT a.Id, a.FullName, a.Email, UPPER(a.Email), a.Email, UPPER(a.Email), 1,
    'System', a.Status, @now, @now, @now, 0,
    NEWID(), NEWID(), 0, 0, 1, 0
FROM @accounts a WHERE NOT EXISTS (SELECT 1 FROM dbo.AspNetUsers u WHERE u.Id = a.Id);

INSERT dbo.AspNetUserRoles (UserId, RoleId)
SELECT a.Id, a.RoleId FROM @accounts a
WHERE NOT EXISTS (SELECT 1 FROM dbo.AspNetUserRoles ur WHERE ur.UserId = a.Id AND ur.RoleId = a.RoleId);

INSERT dbo.SCStaffProfile (Id, AccountId, WorkingLocation, Status, CreatedAt, UpdatedAt, IsDeleted)
SELECT p.Id, u.Id, CONCAT(N'Trạm demo ', s.District), 'Active', @now, @now, 0
FROM @sites s JOIN @fixtures p ON p.Kind = 3 AND p.Number = s.Number
JOIN @fixtures u ON u.Kind = 1 AND u.Number = s.Number
WHERE NOT EXISTS (SELECT 1 FROM dbo.SCStaffProfile x WHERE x.AccountId = u.Id);

INSERT dbo.EVDriverProfile (Id, AccountId, Point, Status, CreatedAt, UpdatedAt, IsDeleted, IsBookingLocked, MissedBookingCount)
SELECT p.Id, u.Id, 0, 'Active', @now, @now, 0, 0, 0
FROM @sites s JOIN @fixtures p ON p.Kind = 4 AND p.Number = s.Number
JOIN @fixtures u ON u.Kind = 2 AND u.Number = s.Number
WHERE NOT EXISTS (SELECT 1 FROM dbo.EVDriverProfile x WHERE x.AccountId = u.Id);

INSERT dbo.VehicleModel (Id, ModelName, Brand, ModelYear, VehicleType, BatteryCapacityKWh,
    RecommendedChargingPowerKW, ImageUrl, Status, CreatedAt, UpdatedAt, IsDeleted, CreatedBy)
SELECT f.Id, m.ModelName, m.Brand, 2025, 'Car', m.Battery, m.Power, '', 'Active', @now, @now, 0, @creator
FROM @models m JOIN @fixtures f ON f.Kind = 5 AND f.Number = m.Number
WHERE NOT EXISTS (SELECT 1 FROM dbo.VehicleModel v WHERE v.Id = f.Id);

INSERT dbo.UserVehicle (DriverId, VehicleModelId)
SELECT p.Id, v.Id FROM @sites s
JOIN @fixtures p ON p.Kind = 4 AND p.Number = s.Number
JOIN @fixtures v ON v.Kind = 5 AND v.Number = s.Number
WHERE NOT EXISTS (SELECT 1 FROM dbo.UserVehicle x WHERE x.DriverId = p.Id AND x.VehicleModelId = v.Id);

INSERT dbo.ChargingStation (Id, StationName, Location, Province, Latitude, Longitude, Status, OperatorId,
    TotalCarChargingPosts, AvailableCarChargingPosts, TotalCarChargingConnectors, AvailableCarConnectors,
    TotalBikeChargingPosts, AvailableBikeChargingPosts, TotalBikeConnectors, AvailableBikeConnectors,
    CreatedAt, UpdatedAt, IsDeleted)
SELECT st.Id, CONCAT(N'Trạm demo ', s.District), CONCAT(N'Khu vực ', s.District), s.Province, s.Lat, s.Lon,
    CASE WHEN s.Number = 10 THEN 'Maintenance' ELSE 'Active' END, staff.Id,
    3, CASE WHEN s.Number = 10 THEN 0 ELSE 3 END, 6, CASE WHEN s.Number = 10 THEN 0 ELSE 6 END,
    0, 0, 0, 0, @now, @now, 0
FROM @sites s JOIN @fixtures st ON st.Kind = 6 AND st.Number = s.Number
JOIN @fixtures staff ON staff.Kind = 1 AND staff.Number = s.Number
WHERE NOT EXISTS (SELECT 1 FROM dbo.ChargingStation x WHERE x.Id = st.Id);

INSERT dbo.ChargingPost (Id, StationId, PostName, ConnectorType, VehicleTypeSupported, MaxPowerKw,
    TotalConnectors, AvailableConnectors, Status, CreatedAt, UpdatedAt, IsDeleted)
SELECT p.Id, st.Id, CONCAT(N'Trụ ', spec.Slot, ' - ', spec.Plug, ' ', spec.Kw, ' kW'), spec.Plug, 'Car', spec.Kw,
    2, CASE WHEN s.Number = 10 THEN 0 ELSE 2 END,
    CASE WHEN s.Number = 10 THEN 'Maintained' ELSE 'Available' END, @now, @now, 0
FROM @sites s JOIN @fixtures st ON st.Kind = 6 AND st.Number = s.Number
CROSS JOIN (VALUES (1,'CCS2',60),(2,'CCS2',120),(3,'Type2',22)) spec(Slot,Plug,Kw)
JOIN @fixtures p ON p.Kind = 7 AND p.Number = (s.Number - 1) * 3 + spec.Slot
WHERE NOT EXISTS (SELECT 1 FROM dbo.ChargingPost x WHERE x.Id = p.Id);

INSERT dbo.Connector (Id, ChargingPostId, ConnectorName, Status, IsLocked, IsPluggedIn, CreatedAt, UpdatedAt, IsDeleted)
SELECT c.Id, p.Id, CONCAT(N'Cổng ', slots.Slot), CASE WHEN p.Status = 'Available' THEN 'Available' ELSE 'OutOfService' END, 0, 0, @now, @now, 0
FROM @fixtures f JOIN dbo.ChargingPost p ON p.Id = f.Id
CROSS JOIN (VALUES (1),(2)) slots(Slot)
JOIN @fixtures c ON c.Kind = 8 AND c.Number = (f.Number - 1) * 2 + slots.Slot
WHERE f.Kind = 7 AND NOT EXISTS (SELECT 1 FROM dbo.Connector x WHERE x.Id = c.Id);

INSERT dbo.Feedbacks (Id, AccountId, Subject, Stars, Message, CreatedAt, IsResolved)
SELECT f.Id, d.Id, N'Góp ý demo về điểm sạc', 4,
    CONCAT(N'Dữ liệu mẫu: bổ sung biển chỉ dẫn ở ', s.District, N'.'), @now, 0
FROM @sites s JOIN @fixtures f ON f.Kind = 9 AND f.Number = s.Number
JOIN @fixtures d ON d.Kind = 2 AND d.Number = s.Number
WHERE NOT EXISTS (SELECT 1 FROM dbo.Feedbacks x WHERE x.Id = f.Id);

INSERT dbo.Reports (Id, Title, ReportType, Severity, Description, Status, CreatedAt, UpdatedAt, IsDeleted,
    ReportedById, StationId, PostId)
SELECT r.Id, N'Kiểm tra định kỳ trụ sạc demo', 'Maintenance', 'Low',
    N'Phiếu mẫu dùng để trình diễn danh sách báo cáo.', 'Open', @now, @now, 0, u.Id, st.Id, p.Id
FROM @sites s JOIN @fixtures r ON r.Kind = 10 AND r.Number = s.Number
JOIN @fixtures u ON u.Kind = 1 AND u.Number = s.Number
JOIN @fixtures st ON st.Kind = 6 AND st.Number = s.Number
JOIN @fixtures p ON p.Kind = 7 AND p.Number = (s.Number - 1) * 3 + 1
WHERE s.Number % 2 = 0 AND NOT EXISTS (SELECT 1 FROM dbo.Reports x WHERE x.Id = r.Id);

COMMIT TRANSACTION;

SELECT 'VehicleModel' AS Fixture, COUNT(*) AS [Rows] FROM dbo.VehicleModel v JOIN @fixtures f ON f.Kind=5 AND f.Id=v.Id
UNION ALL SELECT 'ChargingStation', COUNT(*) FROM dbo.ChargingStation v JOIN @fixtures f ON f.Kind=6 AND f.Id=v.Id
UNION ALL SELECT 'ChargingPost', COUNT(*) FROM dbo.ChargingPost v JOIN @fixtures f ON f.Kind=7 AND f.Id=v.Id
UNION ALL SELECT 'Connector', COUNT(*) FROM dbo.Connector v JOIN @fixtures f ON f.Kind=8 AND f.Id=v.Id
UNION ALL SELECT 'Staff', COUNT(*) FROM dbo.SCStaffProfile v JOIN @fixtures f ON f.Kind=3 AND f.Id=v.Id
UNION ALL SELECT 'Driver', COUNT(*) FROM dbo.EVDriverProfile v JOIN @fixtures f ON f.Kind=4 AND f.Id=v.Id
UNION ALL SELECT 'Feedback', COUNT(*) FROM dbo.Feedbacks v JOIN @fixtures f ON f.Kind=9 AND f.Id=v.Id
UNION ALL SELECT 'Report', COUNT(*) FROM dbo.Reports v JOIN @fixtures f ON f.Kind=10 AND f.Id=v.Id;
