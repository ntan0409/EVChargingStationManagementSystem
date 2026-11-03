// Synthetic DTOs exclusively for fake-adapter tests. Never runtime payment evidence.
const sessionId = '30000000-0000-0000-0000-000000000001';
const postId = '40000000-0000-0000-0000-000000000001';
const connectorId = '50000000-0000-0000-0000-000000000001';
const paymentId = '60000000-0000-0000-0000-000000000001';
const voucherId = '70000000-0000-0000-0000-000000000001';
const ownedId = '80000000-0000-0000-0000-000000000001';
const transactionId = '90000000-0000-0000-0000-000000000001';
const stationId = 'a0000000-0000-0000-0000-000000000001';
const vehicleId = 'b0000000-0000-0000-0000-000000000001';
const otherId = 'c0000000-0000-0000-0000-000000000001';

Map<String, dynamic> sessionDto({
  String status = 'Charging',
  double energy = 10,
  double cost = 50000,
}) => {
  'id': sessionId,
  'chargingPostId': postId,
  'connectorId': connectorId,
  'status': status,
  'startTime': '2026-11-02T01:00:00Z',
  'endTime': status == 'Charging' ? null : '2026-11-02T02:00:00Z',
  'batteryCapacityKWh': 80,
  'initialBatteryLevelPercent': 20,
  'expectedEnergiesKWh': 80,
  'powerRateKW': 60,
  'totalEnergyConsumedKWh': energy,
  'cost': cost,
};
Map<String, dynamic> paymentDto({String status = 'Initiated'}) => {
  'id': paymentId,
  'chargingSessionId': sessionId,
  'amount': 55000,
  'beforeVatAmount': 50000,
  'taxRate': 10,
  'paymentMethod': 'OFFLINE',
  'status': status,
  'txnRef': 'UNIT-REFERENCE',
  'createdAt': '2026-11-02T02:00:00Z',
  'updatedAt': '2026-11-02T02:01:00Z',
};
Map<String, dynamic> quoteDto({
  String sessionStatus = 'Completed',
  String? paymentStatus,
}) => {
  'sessionId': sessionId,
  'sessionStatus': sessionStatus,
  'beforeVatAmount': 50000,
  'taxRate': 10,
  'amount': 55000,
  'payment': paymentStatus == null ? null : paymentDto(status: paymentStatus),
};
Map<String, dynamic> transactionDto({String status = 'Completed'}) => {
  'id': transactionId,
  'referenceCode': 'UNIT-LEDGER-REFERENCE',
  'amount': 55000,
  'transactionType': 'OfflinePayment',
  'status': status,
  'paymentId': paymentId,
  'initiatedAt': '2026-11-02T02:00:00Z',
  'completedAt': '2026-11-02T02:01:00Z',
};
Map<String, dynamic> voucherDto({
  String type = 'Discount',
  bool expired = false,
}) => {
  'id': voucherId,
  'name': 'Voucher from test backend',
  'description': 'Fixture only',
  'requiredPoints': 100,
  'value': type == 'Discount' ? 10 : 12000,
  'voucherType': type,
  'isActive': true,
  'validFrom': DateTime.now()
      .subtract(const Duration(days: 2))
      .toUtc()
      .toIso8601String(),
  'validTo': DateTime.now()
      .add(Duration(days: expired ? -1 : 2))
      .toUtc()
      .toIso8601String(),
};
Map<String, dynamic> ownedDto({String status = 'Redeemed'}) => {
  'id': ownedId,
  'voucherId': voucherId,
  'voucherName': 'Owned fixture',
  'voucherValue': 10,
  'voucherType': 'Discount',
  'status': status,
  'sessionId': status == 'Used' ? sessionId : null,
  'expiryDate': DateTime.now()
      .add(const Duration(days: 2))
      .toUtc()
      .toIso8601String(),
};
Map<String, dynamic> stationDto({bool detail = false}) => {
  'id': stationId,
  'stationName': 'Station from backend',
  'location': 'Backend location',
  'province': 'Backend province',
  'latitude': '10.8',
  'longitude': '106.7',
  'status': 'Active',
  'pricePerKWh': 5000,
  if (detail)
    'chargingPosts': [
      {...postDto(), 'connectors': <dynamic>[]},
    ],
};
Map<String, dynamic> connectorDto() => {
  'id': connectorId,
  'connectorName': 'Connector from backend',
  'chargingPostId': postId,
  'status': 'InUse',
  'isPluggedIn': true,
  'isLocked': false,
};
Map<String, dynamic> postDto() => {
  'id': postId,
  'stationId': stationId,
  'postName': 'Post from backend',
  'connectorType': 'CCS2',
  'vehicleTypeSupported': 'Car',
  'maxPowerKw': 60,
  'totalConnectors': 1,
  'status': 'Available',
  'connectors': [connectorDto()],
};
Map<String, dynamic> vehicleDto() => {
  'id': vehicleId,
  'modelName': 'Catalog vehicle',
  'modelYear': 2025,
  'vehicleType': 'Car',
  'batteryCapacityKWh': 80,
  'recommendedChargingPowerKW': 60,
  'status': 'Active',
};
