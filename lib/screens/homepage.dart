import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:provider/provider.dart';
import 'package:safety_nap/providers/location_provider.dart';
import 'package:safety_nap/screens/view_geofences.dart';
import 'package:safety_nap/services/local_notifications.dart';
import 'package:safety_nap/widgets/search_destination_form_field.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stack_appodeal_flutter/stack_appodeal_flutter.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SafeArea(child: HomePageBody()));
  }
}

class HomePageBody extends StatefulWidget {
  const HomePageBody({super.key});

  @override
  State<HomePageBody> createState() => _HomePageBodyState();
}

class _HomePageBodyState extends State<HomePageBody> {
  bool repeatSwitch = false;
  LocationProvider? locProvider;
  bool isMetric = true;
  late SharedPreferences prefs;
  bool isReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    locProvider = context.read<LocationProvider>();
  }

  @override
  void dispose() {
    Appodeal.destroy(AppodealAdType.MREC);

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _showMRECAd();
    initSharedPrefs();
    //1.  Listen to events (See docs for all 12 available events).

    //Fired whenever a location is recorded

    bg.BackgroundGeolocation.onLocation((bg.Location location) async {
      if (locProvider != null && locProvider?.selectedPosLat != null) {
        await locProvider!.updateLocationDistance();
      }
    }, (bg.LocationError error) {
      if (kDebugMode) {
        print('[onLocation] ERROR: $error');
      }
    });

    bg.BackgroundGeolocation.onLocation((
      bg.Location location,
    ) async {
      if (locProvider != null && locProvider?.selectedPosLat != null) {
        await locProvider!.updateLocationDistance();
      }
    });

    // Fired whenever the plugin changes motion-state (stationary->moving and vice-versa)
    // bg.BackgroundGeolocation.onMotionChange((bg.Location location) {
    //   print('[motionchange] - $location');
    // });

    // Fired whenever the state of location-services changes.  Always fired at boot
    // bg.BackgroundGeolocation.onProviderChange((bg.ProviderChangeEvent event) {
    //   print('[providerchange] - $event');
    // });

    // Listen for geofence events.
    bg.BackgroundGeolocation.onGeofence((bg.GeofenceEvent event) {
      _showDistanceDialog(event);
      NotificationService().showNotification(
          1,
          'Alert',
          'You are now ${(convertMeter(locProvider!.locDistance!))} from ${event.identifier}',
          'payload');
    });

    ////
    // 2.  Configure the plugin
    //
    bg.BackgroundGeolocation.ready(bg.Config(
            desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
            distanceFilter: 10.0,
            stopOnTerminate: false,
            startOnBoot: true,
            debug: false,
            geofenceModeHighAccuracy: true,
            logLevel: bg.Config.LOG_LEVEL_VERBOSE))
        .then((bg.State state) {
      if (!state.enabled) {
        ////
        // 3.  Start the plugin.
        //
        bg.BackgroundGeolocation.start();
      }
    });
  }

  Future<void> initSharedPrefs() async {
    prefs = await SharedPreferences.getInstance();
    isMetric = prefs.getBool('isMetric') ?? true;
    setState(() {});
  }

  String convertMeter(num value) {
    if (isMetric) {
      return '${(value / 1000).toStringAsFixed(2)} KM';
    } else {
      return '${(value / 1609.344).toStringAsFixed(2)} Miles';
    }
  }

  Future<void> _showDistanceDialog(bg.GeofenceEvent event) async {
    final locationProvider = context.read<LocationProvider>();
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          // title: const Text(''),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    'You are now ${(convertMeter(locationProvider.locDistance!))} from ${event.identifier}'),
                // Text('Would you like to approve of this message?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showMRECAd() async {
    isReady = await Appodeal.isLoaded(AppodealAdType.MREC);
    setState(() {});
    print('isReady: $isReady');
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();

    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 24),
                  child: Text(
                    'SafetyNap',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                ),
              ),
              const Expanded(child: SizedBox()),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const ViewGeofences()));
                    },
                    icon: const Icon(
                      Icons.apps,
                      color: Colors.black,
                    )),
              ),
            ],
          ),

          const SearchDestinationFormField(),
          const SizedBox(height: 18),
          // locProvider!.locName != null
          //     ? Text.rich(
          //         TextSpan(
          //           text: 'Currently Selected: ',
          //           style: const TextStyle(
          //               fontSize: 16, fontWeight: FontWeight.w500),
          //           children: [
          //             TextSpan(
          //                 text: locProvider!.locName,
          //                 style: const TextStyle(
          //                     fontSize: 16, fontWeight: FontWeight.bold)),
          //           ],
          //         ),
          //       )
          //     : const SizedBox.shrink(),
          locationProvider.locDistance != null
              ? Text.rich(
                  TextSpan(
                      text: locationProvider.locName != null
                          ? 'Distance from: '
                          : '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        TextSpan(
                            text: '${locationProvider.locName}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        TextSpan(
                            text:
                                ' ${(convertMeter(locationProvider.locDistance!))}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500))
                      ]),
                )
              : const SizedBox.shrink(),
          const SizedBox(
            height: 12,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
              decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        const Text(
                          'Alarm Distance',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              color: Colors.white),
                        ),
                        const Expanded(child: SizedBox()),
                        Text(
                          '${(convertMeter(locationProvider.sliderValue))} ',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Slider(
                    value: locationProvider.sliderValue,
                    min: 200,
                    activeColor: const Color.fromRGBO(83, 118, 146, 100),
                    onChanged: (val) {
                      setState(() {
                        locationProvider.updateRadiusSlider(val);
                      });
                    },
                    max: 10000,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromRGBO(83, 118, 146, 100)),
                            onPressed: () async {
                              if (isMetric) {
                                await prefs.setBool('isMetric', false);
                                isMetric = false;
                              } else {
                                await prefs.setBool('isMetric', true);
                                isMetric = true;
                              }
                              setState(() {});
                            },
                            child: Text(
                              isMetric ? 'Metric' : 'Imperial',
                              style: const TextStyle(color: Colors.white),
                            )),
                        const SizedBox(width: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          isReady
              ? const AppodealBanner(
                  adSize: AppodealBannerSize.MEDIUM_RECTANGLE,
                  placement: "home_screen")
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}
