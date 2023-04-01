import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationProvider with ChangeNotifier {
  Position? currentPosition;
  double? selectedPosLat;
  double? selectedPosLng;
  double? locDistance;
  String? locName;
  double sliderValue = 1000;

  void updateSelectedPosition(double newSelecedPosLat, double newSelectedPosLng,
      String newLocName) async {
    selectedPosLat = newSelecedPosLat;
    selectedPosLng = newSelectedPosLng;
    locName = newLocName;
    await updateLocationDistance();
    notifyListeners();
  }

  Future<void> updateLocationDistance() async {
    currentPosition = await Geolocator.getCurrentPosition();

    locDistance = Geolocator.distanceBetween(currentPosition!.latitude,
        currentPosition!.longitude, selectedPosLat!, selectedPosLng!);
    notifyListeners();
  }

  void updateRadiusSlider(double newVal) {
    sliderValue = newVal;
    notifyListeners();
  }
}
