/// Self-documentation for the Sarufi SDK.
///
/// Every operation on [Sarufi] has a matching [EndpointDoc] in [SarufiDocs]
/// describing its HTTP shape, request/response fields and a runnable example.
/// Print one to read it inline - no browser required:
///
/// ```dart
/// print(SarufiDocs.chat);   // one operation
/// print(Sarufi.docs);       // every operation
/// ```
library;

/// One field in a request body, or one query/path parameter.
class FieldDoc {
  const FieldDoc(
    this.name,
    this.type, {
    this.required = false,
    this.description,
    this.values,
  });

  /// Field name as sent on the wire.
  final String name;

  /// JSON type (`string`, `number`, `boolean`, `object`, `array`, ...).
  final String type;

  /// Whether Sarufi requires this field.
  final bool required;

  /// What the field is for.
  final String? description;

  /// Allowed values, for enum-like fields.
  final List<String>? values;

  String _render() {
    final buffer = StringBuffer('  ')
      ..write(name.padRight(24))
      ..write(type.padRight(9))
      ..write(required ? 'required  ' : 'optional  ');
    if (description != null) buffer.write(description);
    if (values != null && values!.isNotEmpty) {
      buffer.write(' [${values!.join(', ')}]');
    }
    return buffer.toString();
  }
}

/// Full, human-readable documentation for a single API operation.
class EndpointDoc {
  const EndpointDoc({
    required this.name,
    required this.method,
    required this.path,
    required this.summary,
    this.description = '',
    this.parameters = const [],
    this.requestBody = const [],
    this.response = const [],
    this.example,
  });

  /// SDK method name, e.g. `chat`.
  final String name;

  /// HTTP method, e.g. `POST`.
  final String method;

  /// Request path, e.g. `conversation`.
  final String path;

  /// One-line summary.
  final String summary;

  /// Longer explanation.
  final String description;

  /// Query/path parameters.
  final List<FieldDoc> parameters;

  /// Request body fields.
  final List<FieldDoc> requestBody;

  /// Notable response fields.
  final List<FieldDoc> response;

  /// A copy-pasteable usage example.
  final String? example;

  /// Renders the documentation as a readable multi-line block.
  String render() {
    final buffer = StringBuffer()
      ..writeln('┌─ $name')
      ..writeln('│  $method $path')
      ..writeln('│  $summary');
    if (description.isNotEmpty) {
      buffer.writeln('│');
      for (final line in description.trim().split('\n')) {
        buffer.writeln('│  ${line.trim()}');
      }
    }
    if (parameters.isNotEmpty) {
      buffer.writeln('│');
      buffer.writeln('│  Parameters:');
      for (final field in parameters) {
        buffer.writeln('│${field._render()}');
      }
    }
    if (requestBody.isNotEmpty) {
      buffer.writeln('│');
      buffer.writeln('│  Request body:');
      for (final field in requestBody) {
        buffer.writeln('│${field._render()}');
      }
    }
    if (response.isNotEmpty) {
      buffer.writeln('│');
      buffer.writeln('│  Response:');
      for (final field in response) {
        buffer.writeln('│${field._render()}');
      }
    }
    if (example != null) {
      buffer.writeln('│');
      buffer.writeln('│  Example:');
      for (final line in example!.trim().split('\n')) {
        buffer.writeln('│    $line');
      }
    }
    buffer.write('└─');
    return buffer.toString();
  }

  @override
  String toString() => render();
}

/// Inline documentation for every Sarufi operation.
///
/// Access one endpoint (`SarufiDocs.chat`) or the whole set (`SarufiDocs.all`):
///
/// ```dart
/// print(SarufiDocs.createBot);
/// for (final doc in SarufiDocs.all) print(doc);
/// ```
abstract final class SarufiDocs {
  /// Create a new chatbot.
  static const EndpointDoc createBot = EndpointDoc(
    name: 'createBot',
    method: 'POST',
    path: 'chatbot',
    summary: 'Create a new chatbot.',
    description:
        'Only `name` is required. Any field left null is omitted from the request.',
    requestBody: [
      FieldDoc('name', 'string', required: true, description: 'Display name.'),
      FieldDoc('description', 'string', description: 'What the bot does.'),
      FieldDoc('industry', 'string', description: 'Industry category.'),
      FieldDoc('intents', 'object',
          description: 'Map of intent name to example utterances.'),
      FieldDoc('flows', 'object',
          description: 'Conversation flow state machine.'),
      FieldDoc('webhook_url', 'string',
          description: 'Called when a trigger intent is fulfilled.'),
      FieldDoc('webhook_trigger_intents', 'array',
          description: 'Intents that fire the webhook.'),
      FieldDoc('visible_on_community', 'boolean',
          description: 'Show the bot on the community page.'),
    ],
    response: [
      FieldDoc('id', 'number', description: 'The new bot id.'),
      FieldDoc('name', 'string'),
    ],
    example: '''
final bot = await sarufi.createBot(
  name: 'Weledi Bot',
  intents: {'salamu': ['habari', 'mambo']},
  flow: {'salamu': {'message': ['Karibu!'], 'next_state': 'end'}},
);''',
  );

  /// Update an existing chatbot.
  static const EndpointDoc updateBot = EndpointDoc(
    name: 'updateBot',
    method: 'PUT',
    path: 'chatbot/{id}',
    summary: 'Update a chatbot; only the fields you pass change.',
    requestBody: [
      FieldDoc('id', 'number', required: true, description: 'Bot to update.'),
      FieldDoc('name', 'string'),
      FieldDoc('description', 'string'),
      FieldDoc('industry', 'string'),
      FieldDoc('intents', 'object'),
      FieldDoc('flows', 'object'),
      FieldDoc('webhook_url', 'string'),
      FieldDoc('webhook_trigger_intents', 'array'),
      FieldDoc('visible_on_community', 'boolean'),
    ],
    example: "await sarufi.updateBot(id: 42, description: 'Updated');",
  );

  /// Fetch a single bot by id.
  static const EndpointDoc getBot = EndpointDoc(
    name: 'getBot',
    method: 'GET',
    path: 'chatbot/{id}',
    summary: 'Fetch a single bot by id.',
    parameters: [
      FieldDoc('id', 'number', required: true, description: 'Bot id.'),
    ],
    example: 'final bot = await sarufi.getBot(42);',
  );

  /// List every bot on the account.
  static const EndpointDoc bots = EndpointDoc(
    name: 'bots',
    method: 'GET',
    path: 'chatbots',
    summary: 'List every bot on the authenticated account.',
    response: [FieldDoc('[]', 'array', description: 'A list of bots.')],
    example: 'final all = await sarufi.bots();',
  );

  /// Delete a bot by id.
  static const EndpointDoc deleteBot = EndpointDoc(
    name: 'deleteBot',
    method: 'DELETE',
    path: 'chatbot/{id}',
    summary: 'Delete a bot by id.',
    parameters: [
      FieldDoc('id', 'number', required: true, description: 'Bot id.'),
    ],
    example: 'await sarufi.deleteBot(42);',
  );

  /// Send a message to a bot and get its reply.
  static const EndpointDoc chat = EndpointDoc(
    name: 'chat',
    method: 'POST',
    path: 'conversation',
    summary: 'Send a message to a bot and get its reply.',
    description:
        'Set channel to whatsapp to route through the conversation/whatsapp '
        'endpoint. Reuse chat_id across turns to keep conversation context.',
    requestBody: [
      FieldDoc('bot_id', 'number', required: true),
      FieldDoc('chat_id', 'string',
          description: 'Conversation session id (auto-generated if omitted).'),
      FieldDoc('message', 'string', required: true),
      FieldDoc('message_type', 'string',
          values: ['text', 'image', 'audio', 'video', 'file']),
    ],
    response: [
      FieldDoc('message', 'array', description: 'The bot\'s replies.'),
      FieldDoc('next_state', 'string', description: 'The state moved to.'),
    ],
    example: '''
final reply = await sarufi.chat(botId: 42, chatId: 'user-1', message: 'Habari');
print(reply.messages);''',
  );

  /// Get the current/next state of a conversation.
  static const EndpointDoc chatStatus = EndpointDoc(
    name: 'chatStatus',
    method: 'POST',
    path: 'conversation/status',
    summary: 'Get the current and next state of a conversation.',
    requestBody: [
      FieldDoc('bot_id', 'number', required: true),
      FieldDoc('chat_id', 'string', required: true),
    ],
    response: [
      FieldDoc('current_state', 'string'),
      FieldDoc('next_state', 'string'),
    ],
    example: "await sarufi.chatStatus(botId: 42, chatId: 'user-1');",
  );

  /// Explicitly move a conversation to a new state.
  static const EndpointDoc updateConversationState = EndpointDoc(
    name: 'updateConversationState',
    method: 'POST',
    path: 'conversation-state',
    summary: 'Explicitly move a conversation to a given state.',
    requestBody: [
      FieldDoc('bot_id', 'number', required: true),
      FieldDoc('chat_id', 'string', required: true),
      FieldDoc('next_state', 'string', required: true),
    ],
    example: '''
await sarufi.updateConversationState(
  botId: 42, chatId: 'user-1', nextState: 'greeting');''',
  );

  /// Classify a message into one of a bot's intents.
  static const EndpointDoc predictIntent = EndpointDoc(
    name: 'predictIntent',
    method: 'POST',
    path: 'predict/intent',
    summary: "Classify a message into one of a bot's intents.",
    requestBody: [
      FieldDoc('bot_id', 'number', required: true),
      FieldDoc('message', 'string', required: true),
    ],
    response: [
      FieldDoc('intent', 'string'),
      FieldDoc('status', 'boolean'),
      FieldDoc('confidence', 'number', description: '0.0 - 1.0'),
    ],
    example: "await sarufi.predictIntent(botId: 42, message: 'nataka kozi');",
  );

  /// Every documented operation, in a sensible reading order.
  static const List<EndpointDoc> all = [
    createBot,
    updateBot,
    getBot,
    bots,
    deleteBot,
    chat,
    chatStatus,
    updateConversationState,
    predictIntent,
  ];

  /// Renders [all] as one readable block.
  static String render() => all.map((doc) => doc.render()).join('\n\n');
}
