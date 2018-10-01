import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:source_gen/source_gen.dart' as source_gen;

import 'build_metadata.dart';

Builder buildMetadata(BuilderOptions options) {
  return source_gen.LibraryBuilder(
    _BuildMetadataGenerator(),
    generatedExtension: '.g.dart'
  );
}

const _baseTypeChecker = source_gen.TypeChecker.fromRuntime(BuildMetadataBase);

class _BuildMetadataGenerator extends source_gen.Generator {
  @override
  String generate(source_gen.LibraryReader library, BuildStep buildStep) {
    final String libraryName = library.element.librarySource.shortName;

    // Generate classes
    final List<Class> classes = [];

    for (final ClassElement classElement in library.classElements) {
      if (!classElement.isAbstract || classElement.isPrivate || classElement.supertype == null) {
        continue;
      }

      bool implementsBuildMetadata = false;

      for (final InterfaceType interface in classElement.interfaces) {
        if (_baseTypeChecker.isExactlyType(interface)) {
          implementsBuildMetadata = true;
          break;
        }
      }
      
      if (implementsBuildMetadata) {
        classes.add(_generateClass(classElement));
      }
    }

    if (classes.isEmpty) {
      return null;
    }

    // Generate library
    final generatedLibrary = Library((l) => l
      ..directives.add(Directive((d) => d
        ..url = libraryName
        ..type = DirectiveType.import
        ..show.addAll(classes.map((c) => c.extend.symbol))
      ))
      ..body.addAll(classes)
    );

    // Emit code
    final emitter = new DartEmitter(Allocator.simplePrefixing());

    return generatedLibrary.accept(emitter).toString();
  }

  Class _generateClass(ClassElement classElement) {
    return Class((c) => c 
      ..name = '\$${classElement.name}Embedded'
      ..extend = refer(classElement.name)
      ..fields.add(Field((f) => f
        ..name = 'buildTimestamp'
        ..annotations.add(refer('override'))
        ..modifier = FieldModifier.final$
        ..type = refer('DateTime')
        ..assignment = Code(
          'DateTime.fromMillisecondsSinceEpoch(${DateTime.now().millisecondsSinceEpoch})'
        )
      ))
    );
  }
}
