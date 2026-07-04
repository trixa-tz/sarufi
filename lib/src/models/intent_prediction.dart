/// The result of asking a bot to classify a message into one of its intents.
class IntentPrediction {
  const IntentPrediction(this.raw);

  factory IntentPrediction.fromJson(Map<String, dynamic> json) =>
      IntentPrediction(json);

  /// The full, untouched response body.
  final Map<String, dynamic> raw;

  /// The predicted intent name.
  String? get intent => raw['intent'] as String?;

  /// Whether the prediction was made successfully.
  bool? get status => raw['status'] as bool?;

  /// The model's confidence in the prediction, from 0.0 to 1.0.
  double? get confidence => (raw['confidence'] as num?)?.toDouble();

  Map<String, dynamic> toJson() => raw;

  @override
  String toString() =>
      'IntentPrediction(intent: $intent, confidence: $confidence)';
}
