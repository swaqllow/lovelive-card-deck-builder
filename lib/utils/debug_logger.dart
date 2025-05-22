// lib/utils/debug_logger.dart
class DebugLogger {
  static void log(String message, {String? tag}) {
    final timestamp = DateTime.now().toIso8601String();
    final formattedMessage = tag != null 
        ? '[$timestamp] $tag: $message'
        : '[$timestamp] $message';
    
    print(formattedMessage);
    
    // 必要に応じてファイルにも出力
    // _writeToLogFile(formattedMessage);
  }
  
  static void error(dynamic error, {String? tag, StackTrace? stackTrace}) {
    log('ERROR: $error', tag: tag);
    if (stackTrace != null) {
      log('StackTrace: $stackTrace', tag: tag);
    }
  }
}