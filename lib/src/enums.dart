/// Strongly-typed enums for the values Sarufi accepts as plain strings.
library;

/// The kind of content carried by a chat message.
enum MessageType {
  text,
  image,
  audio,
  video,
  file;

  /// The wire value expected by the Sarufi API (e.g. `"text"`).
  String get value => name;

  /// Parses a wire value back into a [MessageType], defaulting to [text].
  static MessageType fromValue(String value) => MessageType.values.firstWhere(
        (t) => t.name == value.toLowerCase(),
        orElse: () => MessageType.text,
      );
}

/// The channel a conversation is happening on.
///
/// [whatsapp] routes requests through Sarufi's WhatsApp conversation endpoint.
enum Channel {
  general,
  whatsapp;

  /// The wire value expected by the Sarufi API (e.g. `"general"`).
  String get value => name;

  /// Parses a wire value back into a [Channel], defaulting to [general].
  static Channel fromValue(String value) => Channel.values.firstWhere(
        (c) => c.name == value.toLowerCase(),
        orElse: () => Channel.general,
      );
}
