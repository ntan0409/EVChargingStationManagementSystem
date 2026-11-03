import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_contract.dart';
import '../core/network/api_response.dart';
import '../models/station_model.dart';
import '../models/charging_post_model.dart';
import '../models/connector_model.dart';

class ConnectorLocation {
  final StationModel station;
  final ConnectorModel connector;
  ConnectorLocation(this.station, this.connector);
}

class StationService {
  final ApiClient _apiClient;
  StationService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<ApiResponse<List<StationModel>>> getStations() async {
    final response = await _apiClient.get<List<StationModel>>(
      ApiConstants.stations,
      fromJson: (value) => contractList(value, StationModel.fromJson),
    );
    if (response.statusCode == 404) {
      return ApiResponse.success([], statusCode: 404);
    }
    return response;
  }

  Future<ApiResponse<ChargingPostModel>> getPost(String id) => _apiClient.get(
    '/ChargingPost/${Uri.encodeComponent(id)}',
    fromJson: (value) {
      final json = contractMap(value);
      final connectors = json['connectors'];
      if (connectors is! List) {
        throw const FormatException('Missing connector list');
      }
      final post = ChargingPostModel.fromJson({
        ...json,
        'connectors': [
          for (final connector in connectors)
            {
              ...contractMap(connector),
              'connectorType': json['connectorType'],
              'maxPowerKw': json['maxPowerKw'],
            },
        ],
      });
      if (post.id.toLowerCase() != id.toLowerCase() ||
          !isApiId(post.stationId) ||
          post.connectors.any((c) => c.chargingPostId != post.id)) {
        throw const FormatException('Wrong post/connector');
      }
      return post;
    },
  );

  Future<ApiResponse<StationModel>> getStationById(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${ApiConstants.stationById}${Uri.encodeComponent(id)}',
      fromJson: contractMap,
    );
    if (!response.success || response.data == null) {
      return forwardError(response);
    }
    try {
      final station = StationModel.fromJson(response.data!);
      if (station.id.toLowerCase() != id.toLowerCase()) {
        throw const FormatException('Wrong station');
      }
      final posts = await Future.wait(
        station.chargingPosts.map((post) => getPost(post.id)),
      );
      for (final post in posts) {
        if (!post.success || post.data == null) return forwardError(post);
        if (post.data!.stationId != station.id) {
          throw const FormatException('Wrong station post');
        }
      }
      return ApiResponse.success(
        StationModel.fromJson({
          ...response.data!,
          'chargingPosts': posts.map((p) => p.data!.toJson()).toList(),
        }),
        statusCode: response.statusCode,
      );
    } catch (_) {
      return invalidInput('Dữ liệu trạm, trụ hoặc cổng sạc không hợp lệ.');
    }
  }

  Future<ApiResponse<ConnectorLocation>> resolveConnector(String id) async {
    if (!isApiId(id)) {
      return invalidInput(
        'Nhập mã GUID thật của cổng sạc. Không hỗ trợ mã demo.',
      );
    }
    final connectorResponse = await _apiClient.get<ConnectorModel>(
      '/Connector/${Uri.encodeComponent(id)}',
      fromJson: (value) => ConnectorModel.fromJson(contractMap(value)),
    );
    if (!connectorResponse.success || connectorResponse.data == null) {
      return forwardError(connectorResponse);
    }
    final postId = connectorResponse.data!.chargingPostId;
    if (postId == null || !isApiId(postId)) {
      return invalidInput('Cổng sạc thiếu mã trụ hợp lệ.');
    }
    final post = await getPost(postId);
    if (!post.success || post.data == null) return forwardError(post);
    final matches = post.data!.connectors.where(
      (connector) => connector.id.toLowerCase() == id.toLowerCase(),
    );
    if (matches.length != 1) {
      return invalidInput('Cổng không thuộc trụ sạc máy chủ trả về.');
    }
    final station = await _apiClient.get<StationModel>(
      '${ApiConstants.stationById}${Uri.encodeComponent(post.data!.stationId)}',
      fromJson: (value) => StationModel.fromJson(contractMap(value)),
    );
    if (!station.success || station.data == null) return forwardError(station);
    if (station.data!.id != post.data!.stationId) {
      return invalidInput('Trạm không khớp trụ sạc.');
    }
    return ApiResponse.success(
      ConnectorLocation(station.data!, matches.single),
    );
  }
}
