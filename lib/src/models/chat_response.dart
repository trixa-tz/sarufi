/// The reply returned by the bot after a `chat` / `respond` call.
///
/// Sarufi's conversation payload varies a little by bot configuration, so this
/// model exposes best-effort typed getters while always keeping the [raw] map
/// available for anything not surfaced here.
class ChatResponse {
  const ChatResponse(this.raw);

  factory ChatResponse.fromJson(Map<String, dynamic> json) =>
      ChatResponse(json);

  /// The full, untouched response body.
  final Map<String, dynamic> raw;

  /// The text messages the bot wants to send back, flattened to a list.
  ///
  /// Handles both the `message` and `actions.send_message` response shapes.
  List<String> get messages {
    final direct = raw['message'];
    if (direct is List) return direct.map((e) => e.toString()).toList();
    if (direct is String) return [direct];

    final actions = raw['actions'];
    if (actions is List) {
      return actions.whereType<Map<String, dynamic>>().expand((action) {
        final send = action['send_message'] ?? action['message'];
        if (send is List) return send.map((e) => e.toString());
        if (send is String) return [send];
        return const <String>[];
      }).toList();
    }
    return const [];
  }

  /// The state the conversation moved to, if the bot reported one.
  String? get nextState => raw['next_state'] as String?;

  /// The raw list of actions the bot performed, if present.
  List<dynamic>? get actions => raw['actions'] as List<dynamic>?;

  /// The conversation memory the bot is carrying, if present.
  Map<String, dynamic>? get memory =>
      (raw['memory'] as Map?)?.cast<String, dynamic>();

  /// Convenience accessor for any field in [raw].
  Object? operator [](String key) => raw[key];

  Map<String, dynamic> toJson() => raw;

  @override
  String toString() =>
      'ChatResponse(messages: $messages, nextState: $nextState)';
}
