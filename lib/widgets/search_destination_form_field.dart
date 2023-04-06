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
  Widget myAnimtedWidget = const ResultMessageWidget();

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
      bool? notifyOnExit,
      required double sliderValue}) async {
    bg.BackgroundGeolocation.addGeofence(bg.Geofence(
        identifier: identifier,
        radius: radius,
        latitude: lat,
        longitude: lng,
        notifyOnEntry: notifyOnEntry ?? true,
        notifyOnExit: notifyOnExit ?? false,
        extras: {"alarm_distance": sliderValue})).then((bool success) {
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

  void resetField(PredictedPlaces predictedPlace, LocationProvider locProvider,
      double sliderValue) async {
    final result = await getPlaceDetails(predictedPlace.placeId!);
    await _addDestination(
        identifier: result.identifier,
        lat: result.lat,
        lng: result.lng,
        radius: locProvider.sliderValue,
        sliderValue: sliderValue);
    locProvider.updateSelectedPosition(
        result.lat, result.lng, result.identifier);
    locProvider.locName = result.identifier;
    placesPredictedList = [];
    myAnimtedWidget = const ResultMessageWidget();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Stack(
            children: [
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(83, 118, 146, 100),
                  borderRadius: BorderRadius.circular(48),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const Text(
                        'Add a Destination',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 24),
                      ),
                      const Text(
                        'Select a location to be notified when you reach the destination',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 18),
                      ),
                      TextField(
                        cursorColor: Colors.grey,
                        style: const TextStyle(color: Colors.black87),
                        controller: _controller,
                        onChanged: (val) {
                          if (val.isEmpty) {
                            setState(() {
                              placesPredictedList = [];
                              myAnimtedWidget = const ResultMessageWidget();
                            });
                          }
                        },
                        decoration: InputDecoration(
                            hintText: 'Destination',
                            fillColor: Colors.white,
                            filled: true,
                            hoverColor: Colors.red,
                            hintStyle: const TextStyle(color: Colors.grey),
                            suffixIcon: const Icon(
                              Icons.search,
                              color: Colors.grey,
                            ),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(width: 0)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(width: 0.3)),
                            contentPadding: const EdgeInsets.only(
                                left: 11, top: 8, bottom: 8)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        //search place results
        AnimatedSwitcher(
            duration: const Duration(seconds: 1), child: myAnimtedWidget),
      ],
    );
  }

  void onChange() {
    getSuggestion(_controller.text);
  }

  void getSuggestion(String input) async {
    final locProvider = context.read<LocationProvider>();

    if (input.isNotEmpty) {
      String urlAutoCompleteSearch =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$androidiOSKey&components=country:$_countryCode";
      var response = await RequestData.get(urlAutoCompleteSearch);
      if (response != "Error") {
        if (response["status"] == "OK") {
          if (_controller.text.isNotEmpty) {
            var placesPredictions = response["predictions"];
            var placePredictionsList = (placesPredictions as List)
                .map((jsonData) => PredictedPlaces.fromMap(jsonData))
                .toList();
            setState(() {
              placesPredictedList = placePredictionsList;
              myAnimtedWidget = placePredictionTile(locProvider);
            });
          } else {
            placesPredictedList = [];
          }
        }
      }
    }
  }

  Padding placePredictionTile(LocationProvider locProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
      ),
      child: Container(
        height: 260,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 0),
        // decoration: const BoxDecoration(
        //   color: Colors.black87,
        //   borderRadius: BorderRadius.all(Radius.circular(12)),
        // ),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: placesPredictedList.length,
          physics: const ClampingScrollPhysics(),
          itemBuilder: (context, index) {
            return PlacePredictionTileDesign(
              predictedPlaces: placesPredictedList[index],
              callbackAction: () => resetField(placesPredictedList[index],
                  locProvider, locProvider.sliderValue),
            );
          },
        ),
      ),
    );
  }

  Future<void> getCountryPhoneCode() async {
    var response = await http.get(Uri.parse('http://ip-api.com/json'));
    var jsonResponse = json.decode(response.body);
    final isoCode = jsonResponse['countryCode'];
    _countryCode = isoCode;
  }
}

class ResultMessageWidget extends StatelessWidget {
  const ResultMessageWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.center,
      child: SizedBox(
        height: 50,
        width: double.infinity,
        child: Text(
          'Your results will show here',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
    );
  }
}
