import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safety_nap/providers/location_provider.dart';
import 'package:safety_nap/screens/homepage.dart';
import 'package:safety_nap/services/local_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  NotificationService notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestIOSPermissions();
  runApp(const MyApp());
}

final dialogKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  void onClickedNotification(String? payload) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: ((context) => const HomePage())));
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LocationProvider()),
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const HomePage(),
      ),
    );
  }
}
