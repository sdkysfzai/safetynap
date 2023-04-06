import 'package:flutter/material.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ViewGeofences extends StatefulWidget {
  const ViewGeofences({super.key});

  @override
  State<ViewGeofences> createState() => _ViewGeofencesState();
}

class _ViewGeofencesState extends State<ViewGeofences> {
  Future<List<bg.Geofence>> _getGeofences() async {
    List<bg.Geofence> geofences = await bg.BackgroundGeolocation.geofences;
    return geofences;
  }

  Future<void> _removeGeofence(String identifier) async {
    bg.BackgroundGeolocation.removeGeofence(identifier).then((bool success) {
      if (success) {
        setState(() {});
        Fluttertoast.showToast(
            msg: 'Destination $identifier removed successfully!',
            toastLength: Toast.LENGTH_LONG);
      }
    });
  }

  Future<void> _removeAllGeofences() async {
    bg.BackgroundGeolocation.removeGeofences().then((bool success) {
      if (success) {
        setState(() {});
        Fluttertoast.showToast(
            msg: 'All destinations have been removed!',
            toastLength: Toast.LENGTH_LONG);
      }
    });
  }

  Future<String> convertMeter(num value) async {
    final prefs = await SharedPreferences.getInstance();
    final isMetric = prefs.getBool("isMetric") ?? true;
    if (isMetric) {
      return '${(value / 1000).toStringAsFixed(2)} KM';
    } else {
      return '${(value / 1609.344).toStringAsFixed(2)} Miles';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back_ios_new)),
            ),
            Row(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 24),
                    child: Text(
                      'Added Destinations',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                    ),
                  ),
                ),
                const Expanded(child: SizedBox()),
                GestureDetector(
                    onTap: () {
                      _removeAllGeofences();
                    },
                    child: const Text(
                      'Remove All',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    )),
                IconButton(
                    onPressed: _removeAllGeofences,
                    icon: const Icon(Icons.delete_forever))
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder(
                  future: _getGeofences(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return ListView.builder(
                          itemCount: snapshot.data!.length,
                          itemBuilder: ((context, index) {
                            final geoFence = snapshot.data![index];
                            return ListTile(
                              title: FutureBuilder(
                                  future: convertMeter(
                                      geoFence.extras!["alarm_distance"]),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      final data = snapshot.data;
                                      return Container(
                                        height: 50,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 30),
                                        decoration: BoxDecoration(
                                            color: Colors.black87,
                                            borderRadius:
                                                BorderRadius.circular(16)),
                                        child: Row(
                                          children: [
                                            Text(
                                              geoFence.identifier,
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              data.toString(),
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue),
                                            ),
                                            const Expanded(child: SizedBox()),
                                            IconButton(
                                                onPressed: () {
                                                  _removeGeofence(
                                                      geoFence.identifier);
                                                },
                                                icon: const Icon(
                                                  Icons.delete,
                                                  color: Colors.white,
                                                )),
                                          ],
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  }),
                            );
                          }));
                    }
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }),
            ),
          ],
        ),
      ),
    );
  }
}
