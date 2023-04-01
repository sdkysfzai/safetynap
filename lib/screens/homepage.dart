import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:safety_nap/providers/location_provider.dart';
import 'package:safety_nap/screens/view_geofences.dart';
import 'package:safety_nap/services/local_notifications.dart';
import 'package:safety_nap/widgets/search_destination_form_field.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Safety Nap'),
          actions: [
            IconButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const ViewGeofences()));
                },
                icon: const Icon(Icons.more_vert_rounded))
          ],
        ),
        body: const SafeArea(child: HomePageBody()));
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
  NativeAd? nativeAd;
  bool _nativeAdIsLoaded = false;
  final String _adUnitId = 'ca-app-pub-7656590679135144~7936973767';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    locProvider = context.read<LocationProvider>();
  }

  @override
  void dispose() {
    if (nativeAd != null) nativeAd!.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    loadAd();
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

  void loadAd() {
    nativeAd = NativeAd(
        adUnitId: _adUnitId,
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            debugPrint('$NativeAd loaded.');
            setState(() {
              _nativeAdIsLoaded = true;
            });
          },
          onAdFailedToLoad: (ad, error) {
            // Dispose the ad here to free resources.
            debugPrint('$NativeAd failed to load: $error');
            ad.dispose();
          },
        ),
        request: const AdRequest(),
        // Styling
        nativeTemplateStyle: NativeTemplateStyle(
            // Required: Choose a template.
            templateType: TemplateType.medium,
            // Optional: Customize the ad's style.
            mainBackgroundColor: Colors.purple,
            cornerRadius: 10.0,
            callToActionTextStyle: NativeTemplateTextStyle(
                textColor: Colors.cyan,
                backgroundColor: Colors.red,
                style: NativeTemplateFontStyle.monospace,
                size: 16.0),
            primaryTextStyle: NativeTemplateTextStyle(
                textColor: Colors.red,
                backgroundColor: Colors.cyan,
                style: NativeTemplateFontStyle.italic,
                size: 16.0),
            secondaryTextStyle: NativeTemplateTextStyle(
                textColor: Colors.green,
                backgroundColor: Colors.black,
                style: NativeTemplateFontStyle.bold,
                size: 16.0),
            tertiaryTextStyle: NativeTemplateTextStyle(
                textColor: Colors.brown,
                backgroundColor: Colors.amber,
                style: NativeTemplateFontStyle.normal,
                size: 16.0)))
      ..load();
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();

    return SingleChildScrollView(
      child: Column(
        children: [
          const SearchDestinationFormField(),
          const SizedBox(height: 18),
          Text(
            locationProvider.locName != null
                ? 'Distance from: ${locationProvider.locName} ${(convertMeter(locationProvider.locDistance!))}'
                : '',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                ElevatedButton(
                    onPressed: () async {
                      await prefs.setBool('isMetric', true);
                      isMetric = true;
                      setState(() {});
                    },
                    child: const Text('Metric')),
                const SizedBox(width: 6),
                ElevatedButton(
                    onPressed: () async {
                      await prefs.setBool('isMetric', false);
                      isMetric = false;
                      setState(() {});
                    },
                    child: const Text('Imperial'))
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text(
                  'Alarm Distance',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                ),
                const Expanded(child: SizedBox()),
                Text(
                  '${(convertMeter(locationProvider.sliderValue))} ',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Slider(
            value: locationProvider.sliderValue,
            min: 200,
            onChanged: (val) {
              setState(() {
                locationProvider.updateRadiusSlider(val);
              });
            },
            max: 10000,
          ),
          // Padding(
          //   padding: const EdgeInsets.all(16.0),
          //   child: Row(
          //     children: [
          //       const Text(
          //         'Repeat',
          //         style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
          //       ),
          //       const Expanded(child: SizedBox()),
          //       Switch(
          //           value: repeatSwitch,
          //           onChanged: (bool val) {
          //             setState(() {
          //               repeatSwitch = val;
          //             });
          //           })
          //     ],
          //   ),
          // ),
          _nativeAdIsLoaded
              ? ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 320, // minimum recommended width
                    minHeight: 320, // minimum recommended height
                    maxWidth: 400,
                    maxHeight: 400,
                  ),
                  child: AdWidget(ad: nativeAd!),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}
