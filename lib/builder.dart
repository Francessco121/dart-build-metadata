import 'dart:async';

import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';
import 'package:code_builder/code_builder.dart';

Builder buildMetadata(BuilderOptions options) {
  return _BuildMetadataBuilder();
}

class _BuildMetadataBuilder implements Builder {
  @override
  final buildExtensions = const {
    r'$lib$': ['src/build_metadata.dart']
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    // Get the build timestamp
    final int msSinceEpoch = DateTime.now().millisecondsSinceEpoch;

    // Generate library
    final generatedLibrary = Library((l) => l
      ..body.add(Field((f) => f
        ..modifier = FieldModifier.final$
        ..type = refer('DateTime')
        ..name = 'timestamp'
        ..assignment = Code(
          'DateTime.fromMillisecondsSinceEpoch($msSinceEpoch)'
        )
        ..docs = ListBuilder<String>(const [
          '/// The date and time of when this package was built.'
        ])
      ))
    );

    // Emit code
    final emitter = new DartEmitter(Allocator.simplePrefixing());
    final String fileContents = generatedLibrary.accept(emitter).toString();

    // Write file
    final assetId = new AssetId(buildStep.inputId.package, 'lib/src/build_metadata.dart');

    await buildStep.writeAsString(assetId, fileContents);
  }
}
