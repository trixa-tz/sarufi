/// File-based helpers for building bots from JSON/YAML config on disk.
///
/// This library imports `dart:io` and is therefore **not supported on Flutter
/// web**. Import it only where a filesystem is available (mobile, desktop,
/// server, CLI):
///
/// ```dart
/// import 'package:sarufi/sarufi.dart';
/// import 'package:sarufi/sarufi_io.dart';
///
/// final sarufi = Sarufi('YOUR_API_KEY');
/// final bot = await sarufi.createFromFile(
///   intents: 'data/intents.yaml',
///   flow: 'data/flow.yaml',
///   metadata: 'data/metadata.json',
/// );
/// ```
library;

import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

import 'sarufi.dart';

/// Adds `.json` / `.yaml` file loaders to [Sarufi].
extension SarufiFileConfig on Sarufi {
  /// Creates a bot from config files.
  ///
  /// Each argument is a path to a `.json`, `.yaml` or `.yml` file. The
  /// [metadata] file may contain `name`, `description`, `industry`,
  /// `webhook_url`, `webhook_trigger_intents` and `visible_on_community`.
  Future<Bot> createFromFile({
    String? intents,
    String? flow,
    String? metadata,
  }) async {
    final intentsMap = intents == null ? null : await _readConfigFile(intents);
    final flowMap = flow == null ? null : await _readConfigFile(flow);
    final meta =
        metadata == null ? const {} : (await _readConfigFile(metadata) ?? {});

    return createBot(
      name: meta['name'] as String? ?? 'put name here',
      description: meta['description'] as String?,
      industry: meta['industry'] as String?,
      webhookUrl: meta['webhook_url'] as String?,
      webhookTriggerIntents:
          (meta['webhook_trigger_intents'] as List?)?.cast<String>(),
      visibleOnCommunity: meta['visible_on_community'] as bool?,
      intents: intentsMap,
      flow: flowMap,
    );
  }

  /// Updates the bot with the given [id] from config files.
  ///
  /// See [createFromFile] for the accepted file formats and metadata keys.
  Future<Bot> updateFromFile({
    required int id,
    String? intents,
    String? flow,
    String? metadata,
  }) async {
    final intentsMap = intents == null ? null : await _readConfigFile(intents);
    final flowMap = flow == null ? null : await _readConfigFile(flow);
    final meta =
        metadata == null ? const {} : (await _readConfigFile(metadata) ?? {});

    return updateBot(
      id: id,
      name: meta['name'] as String?,
      description: meta['description'] as String?,
      industry: meta['industry'] as String?,
      webhookUrl: meta['webhook_url'] as String?,
      webhookTriggerIntents:
          (meta['webhook_trigger_intents'] as List?)?.cast<String>(),
      visibleOnCommunity: meta['visible_on_community'] as bool?,
      intents: intentsMap,
      flow: flowMap,
    );
  }
}

Future<Map<String, dynamic>?> _readConfigFile(String path) async {
  final file = File(path);
  if (!await file.exists()) {
    throw FileSystemException('Sarufi config file not found', path);
  }

  final content = await file.readAsString();
  final lower = path.toLowerCase();

  if (lower.endsWith('.json')) {
    return (jsonDecode(content) as Map).cast<String, dynamic>();
  }
  if (lower.endsWith('.yaml') || lower.endsWith('.yml')) {
    final parsed = loadYaml(content);
    // Round-trip through JSON to turn YamlMap/YamlList into plain collections.
    return (jsonDecode(jsonEncode(parsed)) as Map).cast<String, dynamic>();
  }

  throw FormatException(
    'Unsupported config file "$path": use .json, .yaml or .yml',
  );
}
