// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class PredictedPlaces {
  String? placeId;
  String? mainText;
  String? secondaryText;
  PredictedPlaces({
    this.placeId,
    this.mainText,
    this.secondaryText,
  });

  PredictedPlaces copyWith({
    String? placeId,
    String? mainText,
    String? secondaryText,
  }) {
    return PredictedPlaces(
      placeId: placeId ?? this.placeId,
      mainText: mainText ?? this.mainText,
      secondaryText: secondaryText ?? this.secondaryText,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'placeId': placeId,
      'mainText': mainText,
      'secondaryText': secondaryText,
    };
  }

  factory PredictedPlaces.fromMap(Map<String, dynamic> map) {
    return PredictedPlaces(
      placeId: map['place_id'] != null ? map['place_id'] as String : null,
      mainText: map["structured_formatting"]['main_text'] != null
          ? map["structured_formatting"]['main_text'] as String
          : null,
      secondaryText: map["structured_formatting"]['secondary_text'] != null
          ? map["structured_formatting"]['secondary_text'] as String
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory PredictedPlaces.fromJson(String source) =>
      PredictedPlaces.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'PredictedPlaces(place_id: $placeId, main_text: $mainText, secondary_text: $secondaryText)';

  @override
  bool operator ==(covariant PredictedPlaces other) {
    if (identical(this, other)) return true;

    return other.placeId == placeId &&
        other.mainText == mainText &&
        other.secondaryText == secondaryText;
  }

  @override
  int get hashCode =>
      placeId.hashCode ^ mainText.hashCode ^ secondaryText.hashCode;
}
