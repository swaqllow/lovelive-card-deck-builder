import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'dart:convert';

class ImageCacheService {
  // メモリ内キャッシュ
  final Map<String, Image> _imageCache = {};
  
  // 画像URLのハッシュ値を取得（ファイル名として使用）
  String _getImageHash(String url) {
    final bytes = utf8.encode(url);
    final digest = md5.convert(bytes);
    return digest.toString();
  }
  
  // 画像のキャッシュディレクトリを取得
  Future<Directory> get _cacheDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/image_cache');
    
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    
    return cacheDir;
  }
  
  // 画像をキャッシュ
  Future<void> cacheImage(String imageUrl, {bool forceUpdate = false}) async {
    if (imageUrl.isEmpty) return;
    
    final imageHash = _getImageHash(imageUrl);
    final cacheDirectory = await _cacheDir;
    final cachedFilePath = '${cacheDirectory.path}/$imageHash.jpg';
    final cachedFile = File(cachedFilePath);
    
    // 既にキャッシュされているか確認
    if (!forceUpdate && await cachedFile.exists()) {
      return; // 既にキャッシュされていて強制更新でなければ何もしない
    }
    
    try {
      // 画像をダウンロード
      final response = await http.get(Uri.parse(imageUrl));
      
      if (response.statusCode == 200) {
        // ファイルに保存
        await cachedFile.writeAsBytes(response.bodyBytes);
        
        // メモリキャッシュをクリア（既に古いバージョンがあれば）
        _imageCache.remove(imageUrl);
      }
    } catch (e) {
      print('Error caching image $imageUrl: $e');
    }
  }
  
  // キャッシュされた画像を取得
  Future<ImageProvider> getImage(String imageUrl) async {
    // メモリキャッシュから取得
    if (_imageCache.containsKey(imageUrl)) {
      return _imageCache[imageUrl]!.image;
    }
    
    // ファイルキャッシュをチェック
    final imageHash = _getImageHash(imageUrl);
    final cacheDirectory = await _cacheDir;
    final cachedFilePath = '${cacheDirectory.path}/$imageHash.jpg';
    final cachedFile = File(cachedFilePath);
    
    if (await cachedFile.exists()) {
      // ファイルキャッシュから画像を読み込み
      final cachedImage = Image.file(cachedFile);
      _imageCache[imageUrl] = cachedImage; // メモリキャッシュに追加
      return cachedImage.image;
    }
    
    // キャッシュされていない場合は画像をダウンロードしてキャッシュ
    await cacheImage(imageUrl);
    
    // キャッシュされたか再確認
    if (await cachedFile.exists()) {
      final cachedImage = Image.file(cachedFile);
      _imageCache[imageUrl] = cachedImage;
      return cachedImage.image;
    }
    
    // 取得できない場合はプレースホルダを返す
    return AssetImage('assets/images/card_placeholder.png');
  }
  
  // 特定の画像がキャッシュされているか確認
  Future<bool> isImageCached(String imageUrl) async {
    if (_imageCache.containsKey(imageUrl)) {
      return true;
    }
    
    final imageHash = _getImageHash(imageUrl);
    final cacheDirectory = await _cacheDir;
    final cachedFilePath = '${cacheDirectory.path}/$imageHash.jpg';
    final cachedFile = File(cachedFilePath);
    
    return await cachedFile.exists();
  }
  
  // キャッシュサイズを取得
  Future<int> getCacheSize() async {
    final cacheDirectory = await _cacheDir;
    int totalSize = 0;
    
    await for (final entity in cacheDirectory.list()) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }
    
    return totalSize;
  }
  
  // 古いキャッシュをクリアするメソッド（一定期間使用されていないファイルを削除）
  Future<void> clearOldCache({int daysOld = 30}) async {
    final cacheDirectory = await _cacheDir;
    final now = DateTime.now();
    
    await for (final entity in cacheDirectory.list()) {
      if (entity is File) {
        final stat = await entity.stat();
        final fileAge = now.difference(stat.modified);
        
        if (fileAge.inDays > daysOld) {
          await entity.delete();
          
          // ファイル名（ハッシュ値）からURLを特定するのは難しいので、
          // メモリキャッシュは次回アクセス時に自動的に再構築される
        }
      }
    }
  }
  
  // キャッシュ全体をクリア
  Future<void> clearAllCache() async {
    final cacheDirectory = await _cacheDir;
    
    if (await cacheDirectory.exists()) {
      await cacheDirectory.delete(recursive: true);
      await cacheDirectory.create();
    }
    
    _imageCache.clear();
  }
}