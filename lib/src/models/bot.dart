import 'package:uuid/uuid.dart';

import '../enums.dart';
import '../sarufi_base.dart';
import 'chat_response.dart';
import 'chat_state.dart';
import 'intent_prediction.dart';

/// A chatbot returned by the Sarufi API.
///
/// A [Bot] is a convenience wrapper around the raw bot [data] plus the
/// [Sarufi] client that produced it, so you can act on the bot directly:
///
/// ```dart
/// final bot = await sarufi.getBot(42);
/// print(bot.name);
/// final reply = await bot.respond(message: 'Habari');
/// print(reply.messages);
/// ```
///
/// Mutating helpers such as [rename], [addIntent] and [addFlow] call the API
/// and return a fresh [Bot] reflecting the update - the SDK never performs
/// hidden network calls behind a plain property setter.
class Bot {
  Bot({required Sarufi client, required this.data})
      : _client = client,
        chatId = const Uuid().v4();

  final Sarufi _client;

  /// The raw bot payload as returned by the API.
  final Map<String, dynamic> data;

  /// A default chat session id generated for this bot instance, used by
  /// [respond] when no explicit `chatId` is supplied.
  final String chatId;

  /// The bot's unique id.
  int? get id => (data['id'] as num?)?.toInt();

  /// The bot's display name.
  String? get name => data['name'] as String?;

  /// A short description of what the bot does.
  String? get description => data['description'] as String?;

  /// The industry the bot is categorised under.
  String? get industry => data['industry'] as String?;

  /// The bot's intents: a map of intent name to example utterances.
  Map<String, dynamic>? get intents =>
      (data['intents'] as Map?)?.cast<String, dynamic>();

  /// The bot's conversation flow definition.
  Map<String, dynamic>? get flows =>
      (data['flows'] as Map?)?.cast<String, dynamic>();

  /// The webhook URL triggered when a configured intent is fulfilled.
  String? get webhookUrl => data['webhook_url'] as String?;

  /// The intents that trigger [webhookUrl].
  List<String>? get webhookTriggerIntents =>
      (data['webhook_trigger_intents'] as List?)?.cast<String>();

  /// Whether the bot is visible on the Sarufi community page.
  bool? get visibleOnCommunity => data['visible_on_community'] as bool?;

  /// Evaluation metrics for the bot, if any have been computed.
  Map<String, dynamic>? get evaluationMetrics =>
      (data['evaluation_metrics'] as Map?)?.cast<String, dynamic>();

  int get _requireId {
    final value = id;
    if (value == null) {
      throw StateError('This bot has no id and cannot be modified.');
    }
    return value;
  }

  /// Sends [message] to the bot and returns its reply.
  ///
  /// Falls back to this bot's default [chatId] when none is provided.
  Future<ChatResponse> respond({
    required String message,
    MessageType messageType = MessageType.text,
    Channel channel = Channel.general,
    String? chatId,
  }) {
    return _client.chat(
      botId: _requireId,
      chatId: chatId ?? this.chatId,
      message: message,
      messageType: messageType,
      channel: channel,
    );
  }

  /// Predicts which intent [message] belongs to.
  Future<IntentPrediction> predictIntent(String message) =>
      _client.predictIntent(botId: _requireId, message: message);

  /// Fetches the current/next state of the conversation identified by [chatId].
  Future<ChatState> chatStateOf(String chatId) =>
      _client.chatStatus(botId: _requireId, chatId: chatId);

  /// Applies a partial update to this bot and returns the updated [Bot].
  ///
  /// Only the fields you pass are changed; everything else is left as-is.
  Future<Bot> update({
    String? name,
    String? description,
    String? industry,
    Map<String, dynamic>? intents,
    Map<String, dynamic>? flow,
    String? webhookUrl,
    List<String>? webhookTriggerIntents,
    bool? visibleOnCommunity,
  }) {
    return _client.updateBot(
      id: _requireId,
      name: name,
      description: description,
      industry: industry,
      intents: intents,
      flow: flow,
      webhookUrl: webhookUrl,
      webhookTriggerIntents: webhookTriggerIntents,
      visibleOnCommunity: visibleOnCommunity,
    );
  }

  /// Renames the bot and returns the updated [Bot].
  Future<Bot> rename(String name) => update(name: name);

  /// Merges [newIntents] into the bot's existing intents and saves them.
  Future<Bot> addIntent(Map<String, List<String>> newIntents) {
    final merged = {...?intents, ...newIntents};
    return update(intents: merged);
  }

  /// Merges [newFlows] into the bot's existing flow and saves it.
  Future<Bot> addFlow(Map<String, dynamic> newFlows) {
    final merged = {...?flows, ...newFlows};
    return update(flow: merged);
  }

  /// Deletes this bot.
  Future<Map<String, dynamic>> delete() => _client.deleteBot(_requireId);

  @override
  String toString() => 'Bot(id: $id, name: $name)';
}
