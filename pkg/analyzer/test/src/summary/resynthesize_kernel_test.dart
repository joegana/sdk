// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.summary.resynthesize_kernel_test;

import 'dart:async';
import 'dart:typed_data';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/frontend_resolution.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/kernel/resynthesize.dart';
import 'package:front_end/src/api_prototype/byte_store.dart';
import 'package:front_end/src/base/performance_logger.dart';
import 'package:kernel/kernel.dart' as kernel;
import 'package:kernel/text/ast_to_text.dart' as kernel;
import 'package:kernel/type_environment.dart' as kernel;
import 'package:test/src/frontend/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context/mock_sdk.dart';
import 'element_text.dart';
import 'resynthesize_common.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ResynthesizeTest_Kernel);
  });
}

/// Tests marked with this annotation fail because they test features that
/// were implemented in Analyzer, but are intentionally not included into
/// the Dart 2.0 plan, so will not be implemented by Fasta.
const notForDart2 = const Object();

/// Tests marked with this annotations fail because we either have not triaged
/// them, or know that this is an analyzer problem.
const potentialAnalyzerProblem = const Object();

/// Tests marked with this annotation fail because of a Fasta problem.
class FastaProblem {
  const FastaProblem(String issueUri);
}

@reflectiveTest
class ResynthesizeTest_Kernel extends ResynthesizeTest {
  static const DEBUG = false;

  final resourceProvider = new MemoryResourceProvider();

  @override
  bool get isSharedFrontEnd => true;

  @override
  bool get isStrongMode => true;

  @override
  Source addLibrarySource(String path, String content) {
    path = resourceProvider.convertPath(path);
    File file = resourceProvider.newFile(path, content);
    return file.createSource();
  }

  @override
  Source addSource(String path, String content) {
    path = resourceProvider.convertPath(path);
    File file = resourceProvider.newFile(path, content);
    return file.createSource();
  }

  @override
  Future<LibraryElementImpl> checkLibrary(String text,
      {bool allowErrors: false, bool dumpSummaries: false}) async {
    new MockSdk(resourceProvider: resourceProvider);

    String testPath = resourceProvider.convertPath('/test.dart');
    File testFile = resourceProvider.newFile(testPath, text);
    Uri testUri = testFile.toUri();
    String testUriStr = testUri.toString();

    KernelResynthesizer resynthesizer = await _createResynthesizer(testUri);
    return resynthesizer.getLibrary(testUriStr);
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30857')
  test_class_constructor_field_formal_multiple_matching_fields() async {
    await super.test_class_constructor_field_formal_multiple_matching_fields();
  }

  @override
  test_class_setter_invalid_named_parameter() async {
    var library = await checkLibrary('class C { void set x({a}) {} }');
    checkElementText(library, r'''
class C {
  void set x(dynamic #synthetic) {}
}
''');
  }

  @override
  test_class_setter_invalid_no_parameter() async {
    var library = await checkLibrary('class C { void set x() {} }');
    checkElementText(library, r'''
class C {
  void set x(dynamic #synthetic) {}
}
''');
  }

  @override
  test_class_setter_invalid_optional_parameter() async {
    var library = await checkLibrary('class C { void set x([a]) {} }');
    checkElementText(library, r'''
class C {
  void set x(dynamic #synthetic) {}
}
''');
  }

  @override
  test_class_setter_invalid_too_many_parameters() async {
    var library = await checkLibrary('class C { void set x(a, b) {} }');
    checkElementText(library, r'''
class C {
  void set x(dynamic #synthetic) {}
}
''');
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_class_type_parameters_bound() async {
    // https://github.com/dart-lang/sdk/issues/29561
    // Fasta does not provide a flag for explicit vs. implicit Object bound.
    await super.test_class_type_parameters_bound();
  }

  @failingTest // See dartbug.com/32290
  test_const_constructor_inferred_args() =>
      super.test_const_constructor_inferred_args();

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_const_reference_type_functionType() {
    return super.test_const_reference_type_functionType();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_const_topLevel_typedList_typedefArgument() {
    return super.test_const_topLevel_typedList_typedefArgument();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30258')
  test_constructor_redirected_factory_named_generic() async {
    await super.test_constructor_redirected_factory_named_generic();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30258')
  test_constructor_redirected_factory_named_imported_generic() async {
    await super.test_constructor_redirected_factory_named_imported_generic();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30258')
  test_constructor_redirected_factory_named_prefixed_generic() async {
    await super.test_constructor_redirected_factory_named_prefixed_generic();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30258')
  test_constructor_redirected_factory_unnamed_generic() async {
    await super.test_constructor_redirected_factory_unnamed_generic();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30258')
  test_constructor_redirected_factory_unnamed_imported_generic() async {
    await super.test_constructor_redirected_factory_unnamed_imported_generic();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30258')
  test_constructor_redirected_factory_unnamed_prefixed_generic() async {
    await super.test_constructor_redirected_factory_unnamed_prefixed_generic();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_executable_parameter_type_typedef() {
    return super.test_executable_parameter_type_typedef();
  }

  @failingTest
  @notForDart2
  test_export_configurations_useFirst() async {
    await super.test_export_configurations_useFirst();
  }

  @failingTest
  @notForDart2
  test_export_configurations_useSecond() async {
    await super.test_export_configurations_useSecond();
  }

  @failingTest
  @notForDart2
  test_exportImport_configurations_useFirst() async {
    await super.test_exportImport_configurations_useFirst();
  }

  @failingTest
  @override
  test_futureOr() async {
    // TODO(brianwilkerson) Triage this failure.
    fail('Inconsistent results');
  }

  @failingTest
  @override
  test_futureOr_const() async {
    // TODO(brianwilkerson) Triage this failure.
    fail('Inconsistent results');
  }

  @failingTest
  @override
  test_futureOr_inferred() async {
    // TODO(brianwilkerson) Triage this failure.
    fail('Inconsistent results');
  }

  test_getElement_unit() async {
    String text = 'class C {}';
    Source source = addLibrarySource('/test.dart', text);

    new MockSdk(resourceProvider: resourceProvider);
    var resynthesizer = await _createResynthesizer(source.uri);

    CompilationUnitElement unitElement = resynthesizer.getElement(
        new ElementLocationImpl.con3(
            [source.uri.toString(), source.uri.toString()]));
    expect(unitElement.librarySource, source);
    expect(unitElement.source, source);

    // TODO(scheglov) Add some more checks?
    // TODO(scheglov) Add tests for other elements
  }

  @failingTest
  @notForDart2
  test_import_configurations_useFirst() async {
    await super.test_import_configurations_useFirst();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30725')
  test_import_invalidUri_metadata() async {
    await super.test_import_invalidUri_metadata();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_infer_generic_typedef_simple() {
    return super.test_infer_generic_typedef_simple();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_inferred_type_is_typedef() {
    return super.test_inferred_type_is_typedef();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_inferred_type_refers_to_function_typed_param_of_typedef() {
    return super.test_inferred_type_refers_to_function_typed_param_of_typedef();
  }

  @override
  @failingTest
  test_invalid_annotation_prefixed_constructor() {
    return super.test_invalid_annotation_prefixed_constructor();
  }

  @override
  @failingTest
  test_invalid_annotation_unprefixed_constructor() {
    return super.test_invalid_annotation_unprefixed_constructor();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30267')
  test_invalid_nameConflict_imported() async {
    await super.test_invalid_nameConflict_imported();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30267')
  test_invalid_nameConflict_imported_exported() async {
    await super.test_invalid_nameConflict_imported_exported();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30267')
  test_invalid_nameConflict_local() async {
    await super.test_invalid_nameConflict_local();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30725')
  test_invalidUri_part_emptyUri() async {
    await super.test_invalidUri_part_emptyUri();
  }

  @failingTest
  @potentialAnalyzerProblem
  test_invalidUris() async {
    await super.test_invalidUris();
  }

  @failingTest
  @potentialAnalyzerProblem
  test_metadata_enumConstantDeclaration() async {
    await super.test_metadata_enumConstantDeclaration();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/28434')
  test_metadata_fieldFormalParameter() async {
    await super.test_metadata_fieldFormalParameter();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/28434')
  test_metadata_fieldFormalParameter_withDefault() async {
    await super.test_metadata_fieldFormalParameter_withDefault();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/28434')
  test_metadata_functionTypedFormalParameter() async {
    await super.test_metadata_functionTypedFormalParameter();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/28434')
  test_metadata_functionTypedFormalParameter_withDefault() async {
    await super.test_metadata_functionTypedFormalParameter_withDefault();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/28434')
  test_metadata_simpleFormalParameter() async {
    await super.test_metadata_simpleFormalParameter();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/28434')
  test_metadata_simpleFormalParameter_withDefault() async {
    await super.test_metadata_simpleFormalParameter_withDefault();
  }

  @failingTest
  @notForDart2
  test_parameter_checked() async {
    // @checked is deprecated, use `covariant` instead.
    await super.test_parameter_checked();
  }

  @failingTest
  @notForDart2
  test_parameter_checked_inherited() async {
    // @checked is deprecated, use `covariant` instead.
    await super.test_parameter_checked_inherited();
  }

  @failingTest
  @potentialAnalyzerProblem
  test_setter_inferred_type_conflictingInheritance() async {
    await super.test_setter_inferred_type_conflictingInheritance();
  }

  @failingTest
  @potentialAnalyzerProblem
  test_type_inference_based_on_loadLibrary() async {
    await super.test_type_inference_based_on_loadLibrary();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_type_reference_lib_to_lib() {
    return super.test_type_reference_lib_to_lib();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_type_reference_lib_to_part() {
    return super.test_type_reference_lib_to_part();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_type_reference_part_to_lib() {
    return super.test_type_reference_part_to_lib();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_type_reference_part_to_other_part() {
    return super.test_type_reference_part_to_other_part();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_type_reference_part_to_part() {
    return super.test_type_reference_part_to_part();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_type_reference_to_import() {
    return super.test_type_reference_to_import();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_type_reference_to_import_export() {
    return super.test_type_reference_to_import_export();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_type_reference_to_import_export_export() {
    return super.test_type_reference_to_import_export_export();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_type_reference_to_import_export_export_in_subdirs() {
    return super.test_type_reference_to_import_export_export_in_subdirs();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_type_reference_to_import_export_in_subdirs() {
    return super.test_type_reference_to_import_export_in_subdirs();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_type_reference_to_import_part() {
    return super.test_type_reference_to_import_part();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_type_reference_to_import_part_in_subdir() {
    return super.test_type_reference_to_import_part_in_subdir();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_type_reference_to_import_relative() {
    return super.test_type_reference_to_import_relative();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_type_reference_to_typedef() {
    return super.test_type_reference_to_typedef();
  }

  @failingTest
  @potentialAnalyzerProblem
  test_typedef_type_parameters_bound() async {
    // https://github.com/dart-lang/sdk/issues/29561
    await super.test_typedef_type_parameters_bound();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30267')
  test_unresolved_annotation_instanceCreation_argument_super() async {
    await super.test_unresolved_annotation_instanceCreation_argument_super();
  }

  @override
  @failingTest
  test_unresolved_annotation_prefixedIdentifier_badPrefix() {
    return super.test_unresolved_annotation_prefixedIdentifier_badPrefix();
  }

  @override
  @failingTest
  test_unresolved_annotation_prefixedIdentifier_noDeclaration() {
    return super.test_unresolved_annotation_prefixedIdentifier_noDeclaration();
  }

  @override
  @failingTest
  test_unresolved_annotation_simpleIdentifier() {
    return super.test_unresolved_annotation_simpleIdentifier();
  }

  Future<KernelResynthesizer> _createResynthesizer(Uri testUri) async {
    var logger = new PerformanceLog(null);
    var byteStore = new MemoryByteStore();
    var analysisOptions = new AnalysisOptionsImpl()..strongMode = true;

    var fsState = new FileSystemState(
        logger,
        byteStore,
        new FileContentOverlay(),
        resourceProvider,
        sourceFactory,
        analysisOptions,
        new Uint32List(0));

    var compiler = new FrontEndCompiler(
        logger,
        new MemoryByteStore(),
        analysisOptions,
        null,
        sourceFactory,
        fsState,
        resourceProvider.pathContext);

    LibraryOutlineResult libraryResult = await compiler.getOutline(testUri);

    // Remember Kernel libraries produced by the compiler.
    var libraryMap = <String, kernel.Library>{};
    var libraryExistMap = <String, bool>{};
    for (var library in libraryResult.component.libraries) {
      String uriStr = library.importUri.toString();
      libraryMap[uriStr] = library;
      FileState file = fsState.getFileForUri(library.importUri);
      libraryExistMap[uriStr] = file?.exists ?? false;
    }

    if (DEBUG) {
      String testUriStr = testUri.toString();
      var library = libraryMap[testUriStr];
      print(_getLibraryText(library));
    }

    var resynthesizer = new KernelResynthesizer(
        context, libraryResult.types, libraryMap, libraryExistMap);
    return resynthesizer;
  }

  String _getLibraryText(kernel.Library library) {
    StringBuffer buffer = new StringBuffer();
    new kernel.Printer(buffer, syntheticNames: new kernel.NameSystem())
        .writeLibraryFile(library);
    return buffer.toString();
  }
}
