/// A modern, null-safe Dart & Flutter SDK for the
/// [Sarufi](https://sarufi.io) Conversational AI platform.
///
/// Authenticate with an API key, then build, train and chat with bots:
///
/// ```dart
/// import 'package:sarufi/sarufi.dart';
///
/// void main() async {
///   final sarufi = Sarufi('YOUR_API_KEY');
///   final bot = await sarufi.getBot(42);
///   final reply = await bot.respond(message: 'Habari');
///   print(reply.messages);
///   sarufi.close();
/// }
/// ```
///
/// To create or update bots from JSON/YAML files, import
/// `package:sarufi/sarufi_io.dart` (requires `dart:io`, not available on the
/// web).
library;

export 'src/doc.dart' show EndpointDoc, FieldDoc, SarufiDocs;
export 'src/enums.dart';
export 'src/exceptions.dart';
export 'src/models/bot.dart';
export 'src/models/chat_response.dart';
export 'src/models/chat_state.dart';
export 'src/models/intent_prediction.dart';
export 'src/sarufi_base.dart';
