import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/card_data_provider.dart';
import 'home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isInitializing = true;
  String _statusMessage = 'データを読み込んでいます...';
  
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    final cardDataProvider = Provider.of<CardDataProvider>(context, listen: false);
    
    try {
      setState(() {
        _statusMessage = 'カードデータを読み込んでいます...';
      });
      
      // カードデータの初期化
      await cardDataProvider.initialize();
      
      // 更新があるかチェック（バックグラウンドで実行）
      cardDataProvider.checkForUpdates().then((hasUpdates) {
        if (hasUpdates) {
          // 更新がある場合は後でユーザーに通知
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('カードデータの更新があります。設定画面から更新してください。'),
              action: SnackBarAction(
                label: '更新',
                onPressed: () {
                  // 設定画面に移動するロジック
                },
              ),
            ),
          );
        }
      });
      
      // 初期化処理の遅延（スプラッシュスクリーンを表示する最小時間を確保）
      await Future.delayed(Duration(seconds: 2));
      
      // ホーム画面に遷移
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomeScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _statusMessage = 'エラーが発生しました。再試行してください。';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE4007F), // ラブライブピンク
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // アプリロゴ
            Image.asset(
              'assets/images/app_logo.png',
              width: 200,
              height: 200,
            ),
            SizedBox(height: 24),
            if (_isInitializing)
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            else
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isInitializing = true;
                  });
                  _initializeApp();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFFE4007F),
                ),
                child: Text('再試行'),
              ),
            SizedBox(height: 16),
            Text(
              _statusMessage,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}