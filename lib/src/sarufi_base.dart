import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

import 'api_client.dart';
import 'doc.dart';
import 'enums.dart';
import 'exceptions.dart';
import 'models/bot.dart';
import 'models/chat_response.dart';
import 'models/chat_state.dart';
import 'models/intent_prediction.dart';

/// Entry point to the Sarufi Conversational AI platform.
///
/// Authenticate with an API key from your Sarufi dashboard, then create, train
/// and chat with bots:
///
/// ```dart
/// final sarufi = Sarufi('YOUR_API_KEY');
///
/// final bot = await sarufi.createBot(name: 'Maria');
/// final reply = await bot.respond(message: 'Habari');
/// print(reply.messages);
///
/// sarufi.close(); // release the underlying HTTP client when done
/// ```
///
/// Every method throws a [SarufiException] on failure rather than returning an
/// error map, so wrap calls in `try`/`catch` (see [SarufiException] for the
/// full hierarchy).
class Sarufi {
  /// Creates a client authenticated with [apiKey].
  ///
  /// - [baseUrl] overrides the API root (useful for staging or tests).
  /// - [httpClient] injects a custom [http.Client]; if omitted, one is created
  ///   and owned by this instance (release it with [close]).
  /// - [timeout] caps how long each request may take.
  Sarufi(
    String apiKey, {
    String baseUrl = defaultBaseUrl,
    http.Client? httpClient,
    Duration timeout = const Duration(seconds: 120),
  }) : _api = ApiClient(
          apiKey: apiKey,
          baseUrl: baseUrl,
          httpClient: httpClient,
          timeout: timeout,
          logger: logger,
        );

  /// The default Sarufi API root.
  static const String defaultBaseUrl = 'https://developers.sarufi.io/';

  /// The logger used across the SDK. Attach a handler (or call
  /// [enableConsoleLogging]) to see diagnostic output - nothing is printed by
  /// default.
  static final Logger logger = Logger('Sarufi');

  static bool _consoleLoggingAttached = false;

  /// Routes [logger] output to `print` at [level] and above. Call once during
  /// development; a no-op if already enabled.
  static void enableConsoleLogging([Level level = Level.INFO]) {
    Logger.root.level = level;
    if (_consoleLoggingAttached) return;
    _consoleLoggingAttached = true;
    Logger.root.onRecord.listen((record) {
      // ignore: avoid_print
      print('${record.level.name}: ${record.loggerName}: ${record.message}');
    });
  }

  final ApiClient _api;
  final Uuid _uuid = const Uuid();

  /// The API key this client authenticates with.
  String get apiKey => _api.apiKey;

  /// The API root this client talks to.
  String get baseUrl => _api.baseUrl;

  /// Inline, printable documentation for every operation.
  ///
  /// ```dart
  /// print(Sarufi.docs);      // every operation
  /// print(SarufiDocs.chat);  // just one
  /// ```
  static String get docs => SarufiDocs.render();

  // ---------------------------------------------------------------------------
  // Bot management
  // ---------------------------------------------------------------------------

  /// Creates a new chatbot.
  ///
  /// Only [name] is required; every other field is optional and omitted from
  /// the request when null.
  Future<Bot> createBot({
    required String name,
    String? description,
    String? industry,
    Map<String, dynamic>? flow,
    Map<String, dynamic>? intents,
    String? webhookUrl,
    List<String>? webhookTriggerIntents,
    bool? visibleOnCommunity,
  }) async {
    logger.info('Creating bot "$name"');
    final body = _stripNulls({
      'name': name,
      'description': description,
      'intents': intents,
      'flows': flow,
      'industry': industry,
      'webhook_url': webhookUrl,
      'webhook_trigger_intents': webhookTriggerIntents,
      'visible_on_community': visibleOnCommunity,
    });
    final json = await _api.post('chatbot', body);
    return Bot(client: this, data: _asMap(json));
  }

  /// Updates the bot with the given [id], returning the updated [Bot].
  ///
  /// Only the fields you pass are changed.
  Future<Bot> updateBot({
    required int id,
    String? name,
    String? description,
    String? industry,
    Map<String, dynamic>? intents,
    Map<String, dynamic>? flow,
    String? webhookUrl,
    List<String>? webhookTriggerIntents,
    bool? visibleOnCommunity,
  }) async {
    logger.info('Updating bot $id');
    final body = _stripNulls({
      'name': name,
      'description': description,
      'intents': intents,
      'flows': flow,
      'industry': industry,
      'webhook_url': webhookUrl,
      'webhook_trigger_intents': webhookTriggerIntents,
      'visible_on_community': visibleOnCommunity,
    });
    final json = await _api.put('chatbot/$id', body);
    return Bot(client: this, data: _asMap(json));
  }

  /// Fetches a single bot by [id].
  Future<Bot> getBot(int id) async {
    logger.info('Getting bot $id');
    final json = await _api.get('chatbot/$id');
    return Bot(client: this, data: _asMap(json));
  }

  /// Lists every bot on the authenticated account.
  Future<List<Bot>> bots() async {
    logger.info('Getting bots');
    final json = await _api.get('chatbots');
    if (json is List) {
      return json.map((e) => Bot(client: this, data: _asMap(e))).toList();
    }
    throw SarufiApiException('Expected a list of bots but got: $json');
  }

  /// Deletes the bot with the given [id], returning the API's response.
  Future<Map<String, dynamic>> deleteBot(int id) async {
    logger.info('Deleting bot $id');
    final json = await _api.delete('chatbot/$id');
    return _asMap(json);
  }

  // ---------------------------------------------------------------------------
  // Conversations
  // ---------------------------------------------------------------------------

  /// Sends [message] to bot [botId] and returns its reply.
  ///
  /// [chatId] identifies a conversation session; when omitted a fresh one is
  /// generated so each call starts a new conversation. Reuse a [chatId] to keep
  /// context across turns.
  Future<ChatResponse> chat({
    required int botId,
    String? chatId,
    String message = 'Hello',
    MessageType messageType = MessageType.text,
    Channel channel = Channel.general,
  }) async {
    logger.info('Chatting with bot $botId');
    final path =
        channel == Channel.whatsapp ? 'conversation/whatsapp' : 'conversation';
    final json = await _api.post(path, {
      'chat_id': chatId ?? _uuid.v4(),
      'bot_id': botId,
      'message': message,
      'message_type': messageType.value,
    });
    return ChatResponse.fromJson(_asMap(json));
  }

  /// Fetches the current and next state of a conversation [chatId] on [botId].
  Future<ChatState> chatStatus({
    required int botId,
    required String chatId,
  }) async {
    final json = await _api.post('conversation/status', {
      'chat_id': chatId,
      'bot_id': botId.toString(),
    });
    return ChatState.fromJson(_asMap(json));
  }

  /// Explicitly moves conversation [chatId] on [botId] to [nextState].
  ///
  /// Returns the resulting state machine payload.
  Future<Map<String, dynamic>> updateConversationState({
    required int botId,
    required String chatId,
    required String nextState,
  }) async {
    final json = await _api.post('conversation-state', {
      'chat_id': chatId,
      'bot_id': botId.toString(),
      'next_state': nextState,
    });
    return _asMap(json);
  }

  /// Predicts which intent [message] belongs to for bot [botId].
  Future<IntentPrediction> predictIntent({
    required int botId,
    required String message,
  }) async {
    final json = await _api.post('predict/intent', {
      'bot_id': botId,
      'message': message,
    });
    return IntentPrediction.fromJson(_asMap(json));
  }

  /// Releases the underlying HTTP client (only if this instance created it).
  void close() => _api.close();

  @override
  String toString() => 'Sarufi(baseUrl: $baseUrl)';

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static Map<String, dynamic> _stripNulls(Map<String, dynamic> map) => {
        for (final entry in map.entries)
          if (entry.value != null) entry.key: entry.value,
      };

  static Map<String, dynamic> _asMap(Object? json) {
    if (json is Map<String, dynamic>) return json;
    if (json is Map) return json.cast<String, dynamic>();
    throw SarufiApiException('Expected a JSON object but got: $json');
  }
}
