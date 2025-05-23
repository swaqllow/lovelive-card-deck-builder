// lib/services/api/user_api_service.dart
// アプリユーザー向けAPIサービス

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/card/base_card.dart';
import '../../models/adapters/postgresql_adapter.dart';
import '../../models/enums/enums.dart';
import 'api_config.dart';
import 'api_response.dart';
import 'api_exception.dart';

/// アプリユーザー向けAPIサービス
/// 
/// このサービスは一般的なアプリユーザーが
/// カード情報を閲覧・検索するために使用します
class UserApiService {
  static final http.Client _client = http.Client();

  // ========== カード閲覧機能 ==========

  /// 全カードを取得
  /// 
  /// アプリのカード一覧画面で使用
  /// - キャッシュ機能付き
  /// - オフライン時は最後のキャッシュを返す
  static Future<List<BaseCard>> getAllCards() async {
    try {
      final response = await _makeRequest('GET', '/cards/public');
      
      final apiResponse = ApiResponse<List<dynamic>>.fromJson(
        response, 
        (data) => data as List<dynamic>
      );

      if (!apiResponse.success) {
        throw ApiException(
          apiResponse.message ?? 'カード取得に失敗しました',
          statusCode: apiResponse.statusCode,
        );
      }

      return apiResponse.data!
          .map((cardJson) => PostgreSQLAdapter.fromPostgreSQLRow(
              Map<String, dynamic>.from(cardJson as Map)))
          .toList();

    } catch (e) {
      print('getAllCards エラー: $e');
      rethrow;
    }
  }

  /// カード検索
  /// 
  /// アプリの検索画面で使用
  /// - 名前、シリーズ、レアリティなどで検索
  /// - ページネーション対応
  static Future<List<BaseCard>> searchCards({
    String? name,
    SeriesName? series,
    Rarity? rarity,
    CardType? cardType,
    UnitName? unit,
    int? minCost,
    int? maxCost,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (name != null && name.isNotEmpty) {
        queryParams['name'] = name;
      }
      if (series != null) {
        queryParams['series'] = series.name;
      }
      if (rarity != null) {
        queryParams['rarity'] = rarity.displayName;
      }
      if (cardType != null) {
        queryParams['card_type'] = cardType.name;
      }
      if (unit != null) {
        queryParams['unit'] = unit.name;
      }
      if (minCost != null) {
        queryParams['min_cost'] = minCost.toString();
      }
      if (maxCost != null) {
        queryParams['max_cost'] = maxCost.toString();
      }

      final response = await _makeRequest(
        'GET', 
        '/cards/search',
        queryParams: queryParams,
      );

      final apiResponse = ApiResponse<List<dynamic>>.fromJson(
        response, 
        (data) => data as List<dynamic>
      );

      if (!apiResponse.success) {
        throw ApiException(
          apiResponse.message ?? 'カード検索に失敗しました',
          statusCode: apiResponse.statusCode,
        );
      }

      return apiResponse.data!
          .map((cardJson) => PostgreSQLAdapter.fromPostgreSQLRow(
              Map<String, dynamic>.from(cardJson as Map)))
          .toList();

    } catch (e) {
      print('searchCards エラー: $e');
      rethrow;
    }
  }

  /// 特定のカードを取得
  /// 
  /// カード詳細画面で使用
  static Future<BaseCard?> getCardDetails(String cardNumber) async {
    try {
      final response = await _makeRequest('GET', '/cards/public/$cardNumber');

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response, 
        (data) => data as Map<String, dynamic>
      );

      if (!apiResponse.success) {
        if (apiResponse.statusCode == 404) {
          return null;
        }
        throw ApiException(
          apiResponse.message ?? 'カード取得に失敗しました',
          statusCode: apiResponse.statusCode,
        );
      }

      return PostgreSQLAdapter.fromPostgreSQLRow(apiResponse.data!);

    } catch (e) {
      print('getCardDetails エラー: $e');
      rethrow;
    }
  }

  /// シリーズ別カード取得
  /// 
  /// シリーズ選択画面で使用
  static Future<List<BaseCard>> getCardsBySeries(SeriesName series) async {
    return searchCards(series: series, limit: 1000);
  }

  /// ユニット別カード取得
  /// 
  /// ユニット選択画面で使用  
  static Future<List<BaseCard>> getCardsByUnit(UnitName unit) async {
    return searchCards(unit: unit, limit: 1000);
  }

  /// 人気カード取得
  /// 
  /// おすすめ画面で使用
  static Future<List<BaseCard>> getPopularCards({int limit = 10}) async {
    try {
      final response = await _makeRequest(
        'GET', 
        '/cards/popular',
        queryParams: {'limit': limit.toString()},
      );

      final apiResponse = ApiResponse<List<dynamic>>.fromJson(
        response, 
        (data) => data as List<dynamic>
      );

      if (!apiResponse.success) {
        throw ApiException(
          apiResponse.message ?? '人気カード取得に失敗しました',
          statusCode: apiResponse.statusCode,
        );
      }

      return apiResponse.data!
          .map((cardJson) => PostgreSQLAdapter.fromPostgreSQLRow(
              Map<String, dynamic>.from(cardJson as Map)))
          .toList();

    } catch (e) {
      print('getPopularCards エラー: $e');
      rethrow;
    }
  }

  /// 新着カード取得
  /// 
  /// 新着画面で使用
  static Future<List<BaseCard>> getLatestCards({int limit = 10}) async {
    try {
      final response = await _makeRequest(
        'GET', 
        '/cards/latest',
        queryParams: {'limit': limit.toString()},
      );

      final apiResponse = ApiResponse<List<dynamic>>.fromJson(
        response, 
        (data) => data as List<dynamic>
      );

      if (!apiResponse.success) {
        throw ApiException(
          apiResponse.message ?? '新着カード取得に失敗しました',
          statusCode: apiResponse.statusCode,
        );
      }

      return apiResponse.data!
          .map((cardJson) => PostgreSQLAdapter.fromPostgreSQLRow(
              Map<String, dynamic>.from(cardJson as Map)))
          .toList();

    } catch (e) {
      print('getLatestCards エラー: $e');
      rethrow;
    }
  }

  // ========== プライベートメソッド ==========

  static Future<Map<String, dynamic>> _makeRequest(
    String method,
    String endpoint, {
    Map<String, String>? queryParams,
    Map<String, dynamic>? body,
  }) async {
    try {
      var uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final headers = {
        'Content-Type': 'application/json',
        'User-Agent': 'LoveliveCardDeckBuilder/1.0',
        ...ApiConfig.defaultHeaders,
      };

      late http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client.get(uri, headers: headers)
              .timeout(Duration(seconds: 15));
          break;
        case 'POST':
          response = await _client.post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(Duration(seconds: 15));
          break;
        default:
          throw ApiException('サポートされていないHTTPメソッド: $method');
      }

      if (response.body.isEmpty) {
        throw ApiException('空のレスポンスが返されました', statusCode: response.statusCode);
      }

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      responseData['_statusCode'] = response.statusCode;
      
      return responseData;

    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('予期しないエラーが発生しました: $e');
    }
  }

  static void dispose() {
    _client.close();
  }
}