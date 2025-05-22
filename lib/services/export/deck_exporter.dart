import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/widgets.dart';

class DeckExporter {
  // デッキの画像を生成
  Future<Uint8List> generateDeckImage(GlobalKey deckWidgetKey) async {
    RenderRepaintBoundary boundary = 
        deckWidgetKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData != null) {
      return byteData.buffer.asUint8List();
    } else {
      throw Exception('Failed to generate image');
    }
  }
  
  // 画像の保存
  Future<File> saveDeckImage(Uint8List imageData, String deckName) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${deckName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(imageData);
    return file;
  }
  
  // SNSでの共有
  Future<void> shareDeckImage(File imageFile, String deckName) async {
    await Share.shareFiles(
      [imageFile.path],
      text: 'ラブライブ！デッキビルダー: 「$deckName」のデッキ構成',
    );
  }
}