import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safety_nap/providers/location_provider.dart';
import 'package:safety_nap/screens/homepage.dart';
import 'package:safety_nap/services/local_notifications.dart';
import 'package:stack_appodeal_flutter/stack_appodeal_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  NotificationService notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestIOSPermissions();

// Set testing mode
  Appodeal.setTesting(true);

  if (Platform.isAndroid) {
    // Appodeal.initialize(
    //     // appKey: "d41b54fc8c817267b638ae61267f86957bb5b57ecb9d7464",
    //     appKey: "04b75e28c60c4eb7ac54cde3b8c90dbaa5c3167fdeb6bb5d",
    //     adTypes: [
    //       AppodealAdType.Interstitial,
    //       AppodealAdType.RewardedVideo,
    //       AppodealAdType.Banner,
    //       AppodealAdType.MREC
    //     ],
    //     onInitializationFinished: (errors) => {});
  } else if (Platform.isIOS) {
    Appodeal.initialize(
      appKey: "04b75e28c60c4eb7ac54cde3b8c90dbaa5c3167fdeb6bb5d",
      adTypes: [
        // AppodealAdType.Interstitial,
        // AppodealAdType.RewardedVideo,
        // AppodealAdType.Banner,
        AppodealAdType.MREC
      ],
    );
    // onInitializationFinished: (errors) =>
    //     {debugPrint('Appodeal error: $errors')});
  }

  Appodeal.setMrecCallbacks(
      onMrecLoaded: (isPrecache) => {
            debugPrint('onMRECLoaded: $isPrecache'),
          },
      onMrecFailedToLoad: (err) => {debugPrint('onMRECToLoad: $err')},
      onMrecShown: (msg) => {debugPrint('onMRECShown: $msg')},
      onMrecShowFailed: (err) => {('onMRECShowFailed: $err')},
      onMrecClicked: () => {},
      onMrecExpired: (exp) => {debugPrint('onMRECExpired: $exp')});

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
        title: 'SafetyNap',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const HomePage(),
      ),
    );
  }
}
