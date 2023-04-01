import 'package:flutter/material.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:fluttertoast/fluttertoast.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Added Destinations'),
        actions: [
          GestureDetector(
              onTap: () {
                _removeAllGeofences();
              },
              child: const Text('Remove All')),
          const SizedBox(
            width: 8,
          ),
        ],
      ),
      body: FutureBuilder(
          future: _getGeofences(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: ((context, index) {
                    final geoFence = snapshot.data![index];
                    return ListTile(
                      title: Text(geoFence.identifier),
                      leading: IconButton(
                          onPressed: () {
                            _removeGeofence(geoFence.identifier);
                          },
                          icon: const Icon(Icons.delete)),
                    );
                  }));
            }
            return const Center(
              child: CircularProgressIndicator(),
            );
          }),
    );
  }
}
