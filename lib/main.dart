import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/card_data_service.dart';
import 'services/database/database_helper.dart';
import 'services/image_cache_service.dart';
import 'providers/card_data_provider.dart';
import 'screens/splash_screen.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // サービスの初期化
  final databaseHelper = DatabaseHelper();
  final imageCacheService = ImageCacheService();
  final cardDataService = CardDataService(
    dbHelper: databaseHelper,
    imageCacheService: imageCacheService,
  );
  
  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseHelper>.value(value: databaseHelper),
        Provider<ImageCacheService>.value(value: imageCacheService),
        ChangeNotifierProvider(
          create: (_) => CardDataProvider(
            cardDataService: cardDataService,
          ),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ラブライブ！デッキビルダー',
      theme: ThemeData(
        primaryColor: Color(0xFFE4007F),
        colorScheme: ColorScheme.light(
          primary: Color(0xFFE4007F),
          secondary: Color(0xFF00A0E9),
        ),
      ),
      home: SplashScreen(),
    );
  }
}