/// The position of a conversation within a bot's flow state machine.
class ChatState {
  const ChatState(this.raw);

  factory ChatState.fromJson(Map<String, dynamic> json) => ChatState(json);

  /// The full, untouched response body.
  final Map<String, dynamic> raw;

  /// The state the conversation is currently in.
  String? get currentState => raw['current_state'] as String?;

  /// The state the conversation will move to next.
  String? get nextState => raw['next_state'] as String?;

  Map<String, dynamic> toJson() => raw;

  @override
  String toString() => 'ChatState(current: $currentState, next: $nextState)';
}
