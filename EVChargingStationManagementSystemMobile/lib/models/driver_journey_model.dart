import '../core/network/api_contract.dart';
import 'booking_model.dart';

class DriverJourneyModel {
  final String accountId;
  final bool profileCompleted, canBook, canChangeVehicle;
  final List<String> missingRequirements, eligibleVehicleModelIds;
  final BookingModel? activeBooking;
  final String? currentSessionId, currentSessionStatus;
  DriverJourneyModel({
    required this.accountId,
    required this.profileCompleted,
    required this.canBook,
    required this.canChangeVehicle,
    required this.missingRequirements,
    required this.eligibleVehicleModelIds,
    this.activeBooking,
    this.currentSessionId,
    this.currentSessionStatus,
  });
  factory DriverJourneyModel.fromJson(Map<String, dynamic> json) {
    if (json['profileCompleted'] is! bool ||
        json['canBook'] is! bool ||
        json['canChangeVehicle'] is! bool ||
        json['missingRequirements'] is! List ||
        json['eligibleVehicleModelIds'] is! List)
      throw const FormatException('Invalid eligibility contract');
    return DriverJourneyModel(
      accountId: contractId(json['accountId']),
      profileCompleted: json['profileCompleted'],
      canBook: json['canBook'],
      canChangeVehicle: json['canChangeVehicle'],
      missingRequirements: (json['missingRequirements'] as List).cast<String>(),
      eligibleVehicleModelIds: (json['eligibleVehicleModelIds'] as List)
          .map(contractId)
          .toList(),
      activeBooking: json['activeBooking'] == null
          ? null
          : BookingModel.fromJson(contractMap(json['activeBooking'])),
      currentSessionId: json['currentSessionId'] == null
          ? null
          : contractId(json['currentSessionId']),
      currentSessionStatus: json['currentSessionStatus'],
    );
  }
}
