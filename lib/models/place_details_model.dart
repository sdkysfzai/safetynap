// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class PlaceDetails {
  final double lat;
  final double lng;
  final String identifier;
  PlaceDetails(
      {required this.lat, required this.lng, required this.identifier});

  PlaceDetails copyWith({
    double? lat,
    double? lng,
    String? identifier,
  }) {
    return PlaceDetails(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      identifier: identifier ?? this.identifier,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'lat': lat,
      'lng': lng,
      'identifier': identifier,
    };
  }

  factory PlaceDetails.fromMap(Map<String, dynamic> map) {
    return PlaceDetails(
      lat: map['geometry']['location']['lat'] as double,
      lng: map['geometry']['location']['lng'] as double,
      identifier: map['address_components'][0]['long_name'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory PlaceDetails.fromJson(String source) =>
      PlaceDetails.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'PlaceDetails(lat: $lat, lng: $lng, identifier: $identifier)';

  @override
  bool operator ==(covariant PlaceDetails other) {
    if (identical(this, other)) return true;

    return other.lat == lat &&
        other.lng == lng &&
        other.identifier == identifier;
  }

  @override
  int get hashCode => lat.hashCode ^ lng.hashCode ^ identifier.hashCode;
}
