// lib/services/api/system_api_service.dart
// システム内部用APIサービス

/// システム内部用APIサービス
/// 
/// このサービスはアプリの裏側で動作し、
/// データ同期やバージョン管理を行います
class SystemApiService {
  static final http.Client _client = http.Client();

  // ========== データ同期機能 ==========

  /// データバージョン確認
  /// 
  /// アプリ起動時やバックグラウンド処理で使用
  static Future<String> getCurrentDataVersion() async {
    try {
      final response = await _makeRequest('GET', '/system/version');

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response, 
        (data) => data as Map<String, dynamic>
      );

      if (!apiResponse.success) {
        throw ApiException(
          apiResponse.message ?? 'バージョン取得に失敗しました',
          statusCode: apiResponse.statusCode,
        );
      }

      return apiResponse.data!['version'] as String;

    } catch (e) {
      print('getCurrentDataVersion エラー: $e');
      rethrow;
    }
  }

  /// 差分更新取得
  /// 
  /// 定期的なバックグラウンド同期で使用
  static Future<SyncResult> syncCards({String? lastVersion}) async {
    try {
      final queryParams = <String, String>{};
      if (lastVersion != null) {
        queryParams['since_version'] = lastVersion;
      }

      final response = await _makeRequest(
        'GET',
        '/system/sync',
        queryParams: queryParams,
      );

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response, 
        (data) => data as Map<String, dynamic>
      );

      if (!apiResponse.success) {
        throw ApiException(
          apiResponse.message ?? '同期に失敗しました',
          statusCode: apiResponse.statusCode,
        );
      }

      return SyncResult.fromJson(apiResponse.data!);

    } catch (e) {
      print('syncCards エラー: $e');
      rethrow;
    }
  }

  /// 接続テスト
  /// 
  /// アプリの接続状況確認で使用
  static Future<bool> testConnection() async {
    try {
      final response = await _makeRequest('GET', '/system/health');
      return response['status'] == 'ok';
    } catch (e) {
      print('接続テストエラー: $e');
      return false;
    }
  }

  // ========== プライベートメソッド ==========

  static Future<Map<String, dynamic>> _makeRequest(
    String method,
    String endpoint, {
    Map<String, String>? queryParams,
    Map<String, dynamic>? body,
  }) async {
    // UserApiServiceと同じ実装
    // 実際にはベースクラスを作成して共通化すべき
    try {
      var uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final headers = {
        'Content-Type': 'application/json',
        'User-Agent': 'LoveliveCardDeckBuilder-System/1.0',
        'X-System-Request': 'true', // システムリクエストを示す
        ...ApiConfig.defaultHeaders,
      };

      late http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client.get(uri, headers: headers)
              .timeout(Duration(seconds: 30));
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
      throw ApiException('システムAPIエラー: $e');
    }
  }

  static void dispose() {
    _client.close();
  }
}
