import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safety_nap/consts.dart';
import 'package:safety_nap/providers/location_provider.dart';
import 'package:safety_nap/widgets/place_prediction_tile.dart';
import '../models/place_details_model.dart';
import '../models/predicted_places_model.dart';
import '../services/request_data.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;

class SearchDestinationFormField extends StatefulWidget {
  const SearchDestinationFormField({
    super.key,
  });

  @override
  State<SearchDestinationFormField> createState() =>
      _SearchDestinationFormFieldState();
}

class _SearchDestinationFormFieldState
    extends State<SearchDestinationFormField> {
  final _controller = TextEditingController();
  late String _countryCode;
  List<PredictedPlaces> placesPredictedList = [];
  String selectedDestination = '';

  @override
  void initState() {
    super.initState();
    getCountryPhoneCode();
    _controller.addListener(() {
      if (_controller.text.length > 3) {
        onChange();
      }
    });
  }

  Future<void> _addDestination(
      {required String identifier,
      required double lat,
      required double lng,
      required double radius,
      bool? notifyOnEntry,
      bool? notifyOnExit}) async {
    bg.BackgroundGeolocation.addGeofence(bg.Geofence(
        identifier: identifier,
        radius: radius,
        latitude: lat,
        longitude: lng,
        notifyOnEntry: notifyOnEntry ?? true,
        notifyOnExit: notifyOnExit ?? false,
        extras: {"route_id": 1234})).then((bool success) {
      Fluttertoast.showToast(
          msg: 'Destination $identifier added Successfully!',
          toastLength: Toast.LENGTH_LONG);
    }).catchError((dynamic error) {
      Fluttertoast.showToast(msg: 'Failure: $error');
    });
  }

  Future<PlaceDetails> getPlaceDetails(String input) async {
    String url =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$input&key=$androidiOSKey";
    var response = await RequestData.get(url);
    final result = PlaceDetails.fromMap(response['result']);
    return result;
  }

  void resetField(
      PredictedPlaces predictedPlace, LocationProvider locProvider) async {
    final result = await getPlaceDetails(predictedPlace.placeId!);
    await _addDestination(
        identifier: result.identifier,
        lat: result.lat,
        lng: result.lng,
        radius: locProvider.sliderValue);
    locProvider.updateSelectedPosition(
        result.lat, result.lng, result.identifier);
    locProvider.locName = result.identifier;
    placesPredictedList.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final locProvider = context.read<LocationProvider>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
                hintText: 'Destination',
                fillColor: Colors.white,
                filled: true,
                hintStyle: TextStyle(color: Colors.black),
                disabledBorder: OutlineInputBorder(),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(),
                contentPadding: EdgeInsets.only(left: 11, top: 8, bottom: 8)),
          ),
        ),
        //search place results
        if (placesPredictedList.isNotEmpty && _controller.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(6.0),
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                border: Border.all(color: Colors.grey),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: placesPredictedList.length,
                physics: const ClampingScrollPhysics(),
                itemBuilder: (context, index) {
                  return PlacePredictionTileDesign(
                    predictedPlaces: placesPredictedList[index],
                    callbackAction: () =>
                        resetField(placesPredictedList[index], locProvider),
                  );
                },
                separatorBuilder: (context, index) => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Divider(
                    height: 1,
                    color: Colors.black,
                    thickness: 1,
                  ),
                ),
              ),
            ),
          )
        else
          const SizedBox.shrink()
      ],
    );
  }

  void onChange() {
    getSuggestion(_controller.text);
  }

  void getSuggestion(String input) async {
    if (input.isNotEmpty) {
      String urlAutoCompleteSearch =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$androidiOSKey&components=country:$_countryCode";
      var response = await RequestData.get(urlAutoCompleteSearch);
      if (response != "Error") {
        if (response["status"] == "OK") {
          var placesPredictions = response["predictions"];
          var placePredictionsList = (placesPredictions as List)
              .map((jsonData) => PredictedPlaces.fromMap(jsonData))
              .toList();
          setState(() {
            placesPredictedList = placePredictionsList;
          });
        }
      }
    }
  }

  Future<void> getCountryPhoneCode() async {
    var response = await http.get(Uri.parse('http://ip-api.com/json'));
    var jsonResponse = json.decode(response.body);
    final isoCode = jsonResponse['countryCode'];
    _countryCode = isoCode;
  }
}
