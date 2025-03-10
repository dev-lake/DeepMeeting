import 'package:flutter/material.dart';
import 'screens/meeting_form_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/api_config_screen.dart';
import 'config/api_config.dart.example';
import 'screens/meeting_list_screen.dart';
import 'screens/new_meeting_screen.dart';

void main() async {
  // 确保 Flutter 绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  // 加载保存的配置
  await APIConfig.loadConfig();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DeepMeeting',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MeetingListScreen(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
      ],
      routes: {
        '/new_meeting': (context) => const NewMeetingScreen(),
        '/meeting_form': (context) => const MeetingFormScreen(),
        '/api_config': (context) => const APIConfigScreen(),
      },
    );
  }
}
