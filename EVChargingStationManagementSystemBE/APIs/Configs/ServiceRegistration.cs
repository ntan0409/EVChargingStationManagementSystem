using Common.DTOs.AuthDto;
using Common.DTOs.BookingDto;
using Common.DTOs.ChargingPostDto;
using Common.DTOs.ChargingSessionDto;
using Common.DTOs.ChargingStationDto;
using Common.DTOs.ConnectorDto;
using Common.DTOs.FeedbackDto;
using Common.DTOs.NotificationDto;
using Common.DTOs.ProfileEVDriverDto;
using Common.DTOs.ProfileStaffDto;
using Common.DTOs.ReportDto;
using Common.DTOs.SystemConfigurationDto;
using Common.DTOs.VehicleModelDto;
using Infrastructure.Models;
using Mapster;
using MapsterMapper;

namespace APIs.Configs
{
    public static class ServiceRegistration
    {
        public static IServiceCollection ExtensionServices(this IServiceCollection services)
        {
            services.ConfigMapster();
            return services;
        }
        private static IServiceCollection ConfigMapster(this IServiceCollection services)
        {
            var config = TypeAdapterConfig.GlobalSettings;
            config.Scan(typeof(ServiceRegistration).Assembly); // Auto-scan for mappings

            services.AddSingleton(config);
            services.AddScoped<IMapper, Mapper>();

            // Map dto vào model
            TypeAdapterConfig<RegisterAccountDto, UserAccount>.NewConfig()
                .Map(dest => dest.UserName, src => src.Email)
                .Map(dest => dest.PhoneNumber, src => src.Phone)
                .Ignore(dest => dest.Id)
                .IgnoreNullValues(true);

            // Map model vào dto
            TypeAdapterConfig<SCStaffProfile, StaffViewDto>.NewConfig()
                .Map(dest => dest.Name, src => src.UserAccountNavigation != null ? src.UserAccountNavigation.Name : null)
                .Map(dest => dest.Email, src => src.UserAccountNavigation != null ? src.UserAccountNavigation.Email : null);

            TypeAdapterConfig<VehicleModelUpdateDto, VehicleModel>.NewConfig()
                .IgnoreNullValues(true);

            TypeAdapterConfig<ChargingStationUpdateDto, ChargingStation>.NewConfig()
                .IgnoreNullValues(true);

            TypeAdapterConfig<ChargingPostUpdateDto, ChargingPost>.NewConfig()
                .IgnoreNullValues(true);
            // EVDriver
            //  Khi EVDriver tự cập nhật profile cá nhân
            TypeAdapterConfig<EVDriverUpdateSelfDto, EVDriverProfile>.NewConfig()
                .Ignore(dest => dest.Id)
                .IgnoreNullValues(true);

            TypeAdapterConfig<EVDriverUpdateSelfDto, UserAccount>.NewConfig()
                .Ignore(dest => dest.Id)
                .IgnoreNullValues(true);

            //  Khi Admin cập nhật trạng thái của EVDriver
            TypeAdapterConfig<EVDriverUpdateStatusDto, EVDriverProfile>.NewConfig()
                .Map(dest => dest.Status, src => src.Status)
                .IgnoreNullValues(true);

            //  Map entity → view dto (trả về cho client)
            TypeAdapterConfig<EVDriverProfile, EVDriverViewDto>.NewConfig()
                .Map(dest => dest, src => src.UserAccount) // auto-map các field giống tên: Name, Email, Phone, Address, ProfilePictureUrl
                .Map(dest => dest.VehicleModelIds,
                     src => src.UserVehicles != null
                            ? src.UserVehicles.Select(v => v.VehicleModelId).ToList()
                            : new List<Guid>())
                .Map(dest => dest.AccountId, src => src.AccountId)
                .Map(dest => dest.Id, src => src.Id)
                .IgnoreNullValues(true);


            //  SCStaff
            //  Khi Admin tạo account + profile Staff
            TypeAdapterConfig<StaffAccountCreateDto, UserAccount>.NewConfig()
                .Map(dest => dest.UserName, src => src.Email)
                .Ignore(dest => dest.Id)
                .IgnoreNullValues(true);

            TypeAdapterConfig<StaffAccountCreateDto, SCStaffProfile>.NewConfig()
                .Ignore(dest => dest.Id)
                .Ignore(dest => dest.AccountId)
                .IgnoreNullValues(true);

            //  Khi Admin cập nhật profile Staff (profile + account)
            TypeAdapterConfig<StaffUpdateAdminDto, SCStaffProfile>.NewConfig()
                .IgnoreNullValues(true);

            TypeAdapterConfig<StaffUpdateAdminDto, UserAccount>.NewConfig()
                .Ignore(dest => dest.Id)
                .IgnoreNullValues(true);

            //  Khi Staff tự cập nhật thông tin của mình
            TypeAdapterConfig<StaffUpdateDto, UserAccount>.NewConfig()
                .Ignore(dest => dest.Id)
                .IgnoreNullValues(true);

            //  Khi Admin cập nhật trạng thái Staff
            TypeAdapterConfig<StaffUpdateStatusDto, SCStaffProfile>.NewConfig()
                .Map(dest => dest.Status, src => src.Status)
                .IgnoreNullValues(true);

            //  Map model → view dto (trả về cho client)
            TypeAdapterConfig<SCStaffProfile, StaffViewDto>.NewConfig()
                .Map(dest => dest, src => src.UserAccountNavigation) // map các field trùng tên tự động
                .Map(dest => dest.AccountId, src => src.AccountId)
                .Map(dest => dest.Id, src => src.Id)
                .IgnoreNullValues(true);


            //  Booking Mapping
            //create booking
            TypeAdapterConfig<BookingCreatedDto, Booking>.NewConfig()
         .Ignore(dest => dest.Id)
         .Ignore(dest => dest.CreatedAt)
         .Ignore(dest => dest.UpdatedAt)
         .Ignore(dest => dest.IsDeleted)
         .Ignore(dest => dest.Status)
         .Ignore(dest => dest.EndTime)
         .IgnoreNullValues(true);
            // CheckIn Booking
            TypeAdapterConfig<BookingCheckInDto, Booking>.NewConfig()
                .Ignore(dest => dest.Id)
                .Ignore(dest => dest.BookedBy)
                .Ignore(dest => dest.CreatedAt)
                .Ignore(dest => dest.UpdatedAt)
                .Ignore(dest => dest.IsDeleted)
                .Ignore(dest => dest.Status)
                .IgnoreNullValues(true);

            // Complete Booking
            //TypeAdapterConfig<BookingCompleteDto, Booking>.NewConfig()
            //    .Ignore(dest => dest.Id)
            //    .Ignore(dest => dest.BookedBy)
            //    .Ignore(dest => dest.CreatedAt)
            //    .Ignore(dest => dest.UpdatedAt)
            //    .Ignore(dest => dest.IsDeleted)
            //    .Ignore(dest => dest.Status)
            //    .IgnoreNullValues(true);

            TypeAdapterConfig<Booking, BookingViewDto>.NewConfig()
          .Map(dest => dest.DriverName, src => src.BookedByNavigation != null ? src.BookedByNavigation.Name : null)
          .Map(dest => dest.DriverEmail, src => src.BookedByNavigation != null ? src.BookedByNavigation.Email : null)
          .Map(dest => dest.StationName, src => src.ChargingStationNavigation != null ? src.ChargingStationNavigation.StationName : null)
          .Map(dest => dest.Location, src => src.ChargingStationNavigation != null ? src.ChargingStationNavigation.Location : null)
          .Map(dest => dest.ConnectorName, src => src.ConnectorNavigation != null ? src.ConnectorNavigation.ConnectorName : null)
          .Map(dest => dest.ChargingPostId, src => src.ConnectorNavigation != null ? src.ConnectorNavigation.ChargingPostId : (Guid?)null)
          .Map(dest => dest.DriverPhone,
     src => src.BookedByNavigation != null ? src.BookedByNavigation.PhoneNumber : null)
          .Map(dest => dest.ChargingPostName, src => src.ConnectorNavigation != null ? src.ConnectorNavigation.ChargingPost != null ? src.ConnectorNavigation.ChargingPost.PostName : null : null)
          .IgnoreNullValues(true);

            TypeAdapterConfig<ChargingSession, ChargingSessionViewDetailDto>.NewConfig()
                .Map(dest => dest.TotalEnergyConsumedKWh, src => src.EnergyDeliveredKWh)
                .IgnoreNullValues(true);

            //TypeAdapterConfig<ChargingSession, ChargingSessionViewListDto>.NewConfig()
            //    .IgnoreNullValues(true);

            TypeAdapterConfig<ChargingSessionStopDto, ChargingSession>.NewConfig()
                .IgnoreNullValues(true);

            TypeAdapterConfig<SystemConfigurationUpdateDto, SystemConfiguration>.NewConfig()
                .IgnoreNullValues(true);

            TypeAdapterConfig<ConnectorUpdateDto, Connector>.NewConfig()
                .IgnoreNullValues(true);

            // Create
            TypeAdapterConfig<ReportCreateDTO, Report>.NewConfig()
                .Ignore(dest => dest.Id)
                .Map(dest => dest.CreatedAt, _ => DateTime.UtcNow)
                .Map(dest => dest.UpdatedAt, _ => DateTime.UtcNow)
                .Map(dest => dest.Status, _ => "Open")
                .Map(dest => dest.IsDeleted, _ => false)
                .Ignore(dest => dest.ResolvedAt)
                .Ignore(dest => dest.ReportedBy)
                .Ignore(dest => dest.ChargingStation)
                .Ignore(dest => dest.ChargingPost)
                .IgnoreNullValues(true);
            // Create by EV Driver
            TypeAdapterConfig<ReportCreateByUserDto, Report>.NewConfig()
              .Ignore(dest => dest.Id)
                .Map(dest => dest.CreatedAt, _ => DateTime.UtcNow)
                .Map(dest => dest.UpdatedAt, _ => DateTime.UtcNow)
                .Map(dest => dest.Status, _ => "Open")
                .Map(dest => dest.IsDeleted, _ => false)
                .Ignore(dest => dest.ResolvedAt)
                .Ignore(dest => dest.ReportedBy)
                .Ignore(dest => dest.ChargingStation)
                .Ignore(dest => dest.ChargingPost)
                .IgnoreNullValues(true);


            // Update
            TypeAdapterConfig<ReportUpdateDTO, Report>.NewConfig()
                .Map(dest => dest.UpdatedAt, _ => DateTime.UtcNow)
                .Ignore(dest => dest.CreatedAt)
                .Ignore(dest => dest.ReportedBy)
                .Ignore(dest => dest.ChargingStation)
                .Ignore(dest => dest.ChargingPost)
                .Ignore(dest => dest.IsDeleted)
                .IgnoreNullValues(true);

            // View
            TypeAdapterConfig<Report, ViewReportDTO>.NewConfig()
         .Map(dest => dest.ReportedByName, src => src.ReportedBy != null ? src.ReportedBy.Name : null)
         .Map(dest => dest.StationName, src => src.ChargingStation != null ? src.ChargingStation.StationName : null)
         .Map(dest => dest.PostName, src => src.ChargingPost != null ? src.ChargingPost.PostName : null)
         .IgnoreNullValues(true);

            TypeAdapterConfig<ChargingStation, ChargingStationsViewDetailDto>.NewConfig()
                .Map(dest => dest.OperatorName, src => src.OperatorNavigation != null ? src.OperatorNavigation.Name : "");

            TypeAdapterConfig<ChargingStation, ChargingStationViewGeneralDto>.NewConfig()
                .Map(dest => dest.OperatorName, src => src.OperatorNavigation != null ? src.OperatorNavigation.Name : "")
                .Map(dest => dest.OperatorPhone, src => src.OperatorNavigation != null ? src.OperatorNavigation.PhoneNumber : "");
            //  Mapping FeedbackCreateDto → Feedback (khi tạo mới)
            TypeAdapterConfig<FeedbackCreateDto, Feedback>.NewConfig()
                .Ignore(dest => dest.UserAccount)                  // Không map navigation
                .Map(dest => dest.CreatedAt, _ => DateTime.UtcNow)
                .Map(dest => dest.IsResolved, _ => false);

            //  Mapping Feedback → FeedbackReadDto
            TypeAdapterConfig<Feedback, FeedbackReadDto>.NewConfig()
                .Map(dest => dest.Id, src => src.Id)
                .Map(dest => dest.AccountId, src => src.AccountId)
                .Map(dest => dest.Subject, src => src.Subject)
                .Map(dest => dest.Stars, src => src.Stars)
                .Map(dest => dest.Message, src => src.Message)
                .Map(dest => dest.CreatedAt, src => src.CreatedAt)
                .Map(dest => dest.IsResolved, src => src.IsResolved)
                .IgnoreNullValues(true);

            //  Mapping Feedback → FeedbackListDto
            TypeAdapterConfig<Feedback, FeedbackListDto>.NewConfig()
                .Map(dest => dest.Id, src => src.Id)
                .Map(dest => dest.Subject, src => src.Subject)
                .Map(dest => dest.Stars, src => src.Stars)
                .Map(dest => dest.CreatedAt, src => src.CreatedAt)
                .Map(dest => dest.IsResolved, src => src.IsResolved)
                .IgnoreNullValues(true);

            TypeAdapterConfig<NotificationRecipient, NotificationDto>.NewConfig()
                .Map(dest => dest.Title, src => src.Notification.Title)
                .Map(dest => dest.Message, src => src.Notification.Message)
                .Map(dest => dest.Type, src => src.Notification.Type)
                .Map(dest => dest.CreatedAt, src => src.Notification.CreatedAt)
                .Map(dest => dest.CreatedBy, src => src.Notification.CreatedBy)
                .IgnoreNullValues(true);
            return services;
        }
    }
}
