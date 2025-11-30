import 'dart:typed_data';

import 'package:fjs/fjs.dart';
import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

/// Screen to test all JsValue types and conversions
class ValueApiScreen extends StatefulWidget {
  const ValueApiScreen({super.key});

  @override
  State<ValueApiScreen> createState() => _ValueApiScreenState();
}

class _ValueApiScreenState extends State<ValueApiScreen> {
  final Map<String, _TestResult> _testResults = {};

  Future<void> _runTest(String testId, dynamic Function() test) async {
    setState(() {
      _testResults[testId] = _TestResult(isLoading: true);
    });
    try {
      final result = test();
      setState(() {
        _testResults[testId] = _TestResult(
          isSuccess: true,
          result: result,
        );
      });
    } catch (e) {
      setState(() {
        _testResults[testId] = _TestResult(
          isSuccess: false,
          error: e.toString(),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JsValue API Tests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () => setState(() => _testResults.clear()),
            tooltip: 'Clear Results',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Primitive Types
            const ApiTestSection(
              title: 'Primitive Types',
              description: 'Test basic JavaScript value types',
              icon: Icons.code,
            ),
            _buildPrimitiveTests(),

            // Collection Types
            const ApiTestSection(
              title: 'Collection Types',
              description: 'Test array and object types',
              icon: Icons.folder,
            ),
            _buildCollectionTests(),

            // Special Types
            const ApiTestSection(
              title: 'Special Types',
              description: 'Test Date, Symbol, Function types',
              icon: Icons.star,
            ),
            _buildSpecialTests(),

            // Type Checking
            const ApiTestSection(
              title: 'Type Checking Methods',
              description: 'Test type checking APIs',
              icon: Icons.check_circle,
            ),
            _buildTypeCheckTests(),

            // Value Conversion
            const ApiTestSection(
              title: 'Value Conversion',
              description: 'Test Dart to JsValue conversion',
              icon: Icons.swap_horiz,
            ),
            _buildConversionTests(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimitiveTests() {
    return Column(
      children: [
        ApiTestCard(
          title: 'JsValue.none()',
          subtitle: 'Represents null/undefined',
          icon: Icons.block,
          isSuccess: _testResults['none']?.isSuccess,
          isLoading: _testResults['none']?.isLoading ?? false,
          result: _testResults['none']?.result,
          error: _testResults['none']?.error,
          onRun: () => _runTest('none', () {
            const value = JsValue.none();
            return {
              'value': value.value,
              'isNone': value.isNone(),
              'isPrimitive': value.isPrimitive(),
              'typeName': value.typeName(),
            };
          }),
        ),
        ApiTestCard(
          title: 'JsValue.boolean()',
          subtitle: 'Boolean value (true/false)',
          icon: Icons.toggle_on,
          isSuccess: _testResults['boolean']?.isSuccess,
          isLoading: _testResults['boolean']?.isLoading ?? false,
          result: _testResults['boolean']?.result,
          error: _testResults['boolean']?.error,
          onRun: () => _runTest('boolean', () {
            const valueTrue = JsValue.boolean(true);
            const valueFalse = JsValue.boolean(false);
            return {
              'true': {
                'value': valueTrue.value,
                'isBoolean': valueTrue.isBoolean(),
                'asBoolean': valueTrue.asBoolean,
                'typeName': valueTrue.typeName(),
              },
              'false': {
                'value': valueFalse.value,
                'isBoolean': valueFalse.isBoolean(),
                'asBoolean': valueFalse.asBoolean,
                'typeName': valueFalse.typeName(),
              },
            };
          }),
        ),
        ApiTestCard(
          title: 'JsValue.integer()',
          subtitle: '64-bit integer value',
          icon: Icons.numbers,
          isSuccess: _testResults['integer']?.isSuccess,
          isLoading: _testResults['integer']?.isLoading ?? false,
          result: _testResults['integer']?.result,
          error: _testResults['integer']?.error,
          onRun: () => _runTest('integer', () {
            const value = JsValue.integer(42);
            const negative = JsValue.integer(-100);
            const large = JsValue.integer(9007199254740991); // Max safe integer
            return {
              'positive': {
                'value': value.value,
                'asInteger': value.asInteger,
                'asNum': value.asNum,
                'isNumber': value.isNumber(),
                'typeName': value.typeName(),
              },
              'negative': {
                'value': negative.value,
                'asInteger': negative.asInteger,
              },
              'maxSafeInteger': {
                'value': large.value,
                'asInteger': large.asInteger,
              },
            };
          }),
        ),
        ApiTestCard(
          title: 'JsValue.float()',
          subtitle: 'Floating-point number',
          icon: Icons.percent,
          isSuccess: _testResults['float']?.isSuccess,
          isLoading: _testResults['float']?.isLoading ?? false,
          result: _testResults['float']?.result,
          error: _testResults['float']?.error,
          onRun: () => _runTest('float', () {
            const value = JsValue.float(3.14159);
            const negative = JsValue.float(-2.5);
            const infinity = JsValue.float(double.infinity);
            return {
              'pi': {
                'value': value.value,
                'asFloat': value.asFloat,
                'asNum': value.asNum,
                'isNumber': value.isNumber(),
                'typeName': value.typeName(),
              },
              'negative': {
                'value': negative.value,
                'asFloat': negative.asFloat,
              },
              'infinity': {
                'value': infinity.value,
                'asFloat': infinity.asFloat,
              },
            };
          }),
        ),
        ApiTestCard(
          title: 'JsValue.bigint()',
          subtitle: 'BigInt value (stored as string)',
          icon: Icons.blur_linear,
          isSuccess: _testResults['bigint']?.isSuccess,
          isLoading: _testResults['bigint']?.isLoading ?? false,
          result: _testResults['bigint']?.result,
          error: _testResults['bigint']?.error,
          onRun: () => _runTest('bigint', () {
            const value = JsValue.bigint('9007199254740992'); // Beyond max safe
            final dartBigInt = BigInt.parse('123456789012345678901234567890');
            return {
              'beyondMaxSafe': {
                'value': value.value.toString(),
                'asBigint': value.asBigint,
                'isNumber': value.isNumber(),
                'typeName': value.typeName(),
              },
              'largeBigInt': dartBigInt.toString(),
            };
          }),
        ),
        ApiTestCard(
          title: 'JsValue.string()',
          subtitle: 'String value',
          icon: Icons.text_fields,
          isSuccess: _testResults['string']?.isSuccess,
          isLoading: _testResults['string']?.isLoading ?? false,
          result: _testResults['string']?.result,
          error: _testResults['string']?.error,
          onRun: () => _runTest('string', () {
            const value = JsValue.string('Hello, FJS!');
            const empty = JsValue.string('');
            const unicode = JsValue.string('你好世界 🌍');
            return {
              'normal': {
                'value': value.value,
                'asString': value.asString,
                'isString': value.isString(),
                'typeName': value.typeName(),
              },
              'empty': {
                'value': empty.value,
                'asString': empty.asString,
              },
              'unicode': {
                'value': unicode.value,
                'asString': unicode.asString,
              },
            };
          }),
        ),
        ApiTestCard(
          title: 'JsValue.bytes()',
          subtitle: 'Binary data (Uint8List)',
          icon: Icons.data_array,
          isSuccess: _testResults['bytes']?.isSuccess,
          isLoading: _testResults['bytes']?.isLoading ?? false,
          result: _testResults['bytes']?.result,
          error: _testResults['bytes']?.error,
          onRun: () => _runTest('bytes', () {
            final data = Uint8List.fromList([0, 1, 2, 255, 128, 64]);
            final value = JsValue.bytes(data);
            return {
              'value': value.asBytes?.toList(),
              'isBytes': value.isBytes(),
              'typeName': value.typeName(),
              'length': value.asBytes?.length,
            };
          }),
        ),
      ],
    );
  }

  Widget _buildCollectionTests() {
    return Column(
      children: [
        ApiTestCard(
          title: 'JsValue.array()',
          subtitle: 'JavaScript array',
          icon: Icons.list,
          isSuccess: _testResults['array']?.isSuccess,
          isLoading: _testResults['array']?.isLoading ?? false,
          result: _testResults['array']?.result,
          error: _testResults['array']?.error,
          onRun: () => _runTest('array', () {
            const value = JsValue.array([
              JsValue.integer(1),
              JsValue.string('two'),
              JsValue.boolean(true),
              JsValue.float(4.0),
            ]);
            const nested = JsValue.array([
              JsValue.array([
                JsValue.integer(1),
                JsValue.integer(2),
              ]),
              JsValue.array([
                JsValue.integer(3),
                JsValue.integer(4),
              ]),
            ]);
            return {
              'simple': {
                'value': value.value,
                'isArray': value.isArray(),
                'typeName': value.typeName(),
              },
              'nested': {
                'value': nested.value,
                'isArray': nested.isArray(),
              },
            };
          }),
        ),
        ApiTestCard(
          title: 'JsValue.object()',
          subtitle: 'JavaScript object',
          icon: Icons.data_object,
          isSuccess: _testResults['object']?.isSuccess,
          isLoading: _testResults['object']?.isLoading ?? false,
          result: _testResults['object']?.result,
          error: _testResults['object']?.error,
          onRun: () => _runTest('object', () {
            const value = JsValue.object({
              'name': JsValue.string('John'),
              'age': JsValue.integer(30),
              'active': JsValue.boolean(true),
            });
            const nested = JsValue.object({
              'user': JsValue.object({
                'name': JsValue.string('Jane'),
                'email': JsValue.string('jane@example.com'),
              }),
              'scores': JsValue.array([
                JsValue.integer(85),
                JsValue.integer(92),
                JsValue.integer(78),
              ]),
            });
            return {
              'simple': {
                'value': value.value,
                'isObject': value.isObject(),
                'typeName': value.typeName(),
              },
              'nested': {
                'value': nested.value,
                'isObject': nested.isObject(),
              },
            };
          }),
        ),
      ],
    );
  }

  Widget _buildSpecialTests() {
    return Column(
      children: [
        ApiTestCard(
          title: 'JsValue.date()',
          subtitle: 'JavaScript Date object',
          icon: Icons.calendar_today,
          isSuccess: _testResults['date']?.isSuccess,
          isLoading: _testResults['date']?.isLoading ?? false,
          result: _testResults['date']?.result,
          error: _testResults['date']?.error,
          onRun: () => _runTest('date', () {
            final now = DateTime.now();
            final value = JsValue.date(now.millisecondsSinceEpoch);
            final epoch = const JsValue.date(0);
            return {
              'now': {
                'value': value.value.toString(),
                'isDate': value.isDate(),
                'typeName': value.typeName(),
              },
              'epoch': {
                'value': epoch.value.toString(),
                'isDate': epoch.isDate(),
              },
            };
          }),
        ),
        ApiTestCard(
          title: 'JsValue.symbol()',
          subtitle: 'JavaScript Symbol',
          icon: Icons.tag,
          isSuccess: _testResults['symbol']?.isSuccess,
          isLoading: _testResults['symbol']?.isLoading ?? false,
          result: _testResults['symbol']?.result,
          error: _testResults['symbol']?.error,
          onRun: () => _runTest('symbol', () {
            const value = JsValue.symbol('mySymbol');
            return {
              'value': value.value,
              'typeName': value.typeName(),
            };
          }),
        ),
        ApiTestCard(
          title: 'JsValue.function()',
          subtitle: 'JavaScript Function reference',
          icon: Icons.functions,
          isSuccess: _testResults['function']?.isSuccess,
          isLoading: _testResults['function']?.isLoading ?? false,
          result: _testResults['function']?.result,
          error: _testResults['function']?.error,
          onRun: () => _runTest('function', () {
            const value = JsValue.function('myFunction');
            return {
              'value': value.value,
              'typeName': value.typeName(),
            };
          }),
        ),
      ],
    );
  }

  Widget _buildTypeCheckTests() {
    return Column(
      children: [
        ApiTestCard(
          title: 'Type Checking Methods',
          subtitle: 'Test all is*() methods',
          icon: Icons.check_box,
          isSuccess: _testResults['type_checks']?.isSuccess,
          isLoading: _testResults['type_checks']?.isLoading ?? false,
          result: _testResults['type_checks']?.result,
          error: _testResults['type_checks']?.error,
          onRun: () => _runTest('type_checks', () {
            const values = {
              'none': JsValue.none(),
              'boolean': JsValue.boolean(true),
              'integer': JsValue.integer(42),
              'float': JsValue.float(3.14),
              'bigint': JsValue.bigint('12345'),
              'string': JsValue.string('hello'),
              'array': JsValue.array([JsValue.integer(1)]),
              'object': JsValue.object({'key': JsValue.string('value')}),
            };

            final results = <String, Map<String, dynamic>>{};
            for (final entry in values.entries) {
              final v = entry.value;
              results[entry.key] = {
                'isNone': v.isNone(),
                'isBoolean': v.isBoolean(),
                'isNumber': v.isNumber(),
                'isString': v.isString(),
                'isBytes': v.isBytes(),
                'isArray': v.isArray(),
                'isObject': v.isObject(),
                'isDate': v.isDate(),
                'isPrimitive': v.isPrimitive(),
                'typeName': v.typeName(),
              };
            }
            return results;
          }),
        ),
      ],
    );
  }

  Widget _buildConversionTests() {
    return Column(
      children: [
        ApiTestCard(
          title: 'JsValue.from()',
          subtitle: 'Convert Dart values to JsValue',
          icon: Icons.transform,
          isSuccess: _testResults['from_dart']?.isSuccess,
          isLoading: _testResults['from_dart']?.isLoading ?? false,
          result: _testResults['from_dart']?.result,
          error: _testResults['from_dart']?.error,
          onRun: () => _runTest('from_dart', () {
            final testCases = {
              'null': null,
              'bool': true,
              'int': 42,
              'double': 3.14,
              'String': 'hello',
              'List': [1, 2, 3],
              'Map': {'a': 1, 'b': 2},
              'Uint8List': Uint8List.fromList([1, 2, 3]),
              'BigInt': BigInt.parse('12345678901234567890'),
            };

            final results = <String, dynamic>{};
            for (final entry in testCases.entries) {
              final jsValue = JsValue.from(entry.value);
              results[entry.key] = {
                'input': entry.value.toString(),
                'jsValue': jsValue.toString(),
                'typeName': jsValue.typeName(),
                'outputValue': jsValue.value?.toString(),
              };
            }
            return results;
          }),
        ),
        ApiTestCard(
          title: 'Safe Casting Methods',
          subtitle: 'Test as* getters',
          icon: Icons.cast,
          isSuccess: _testResults['safe_cast']?.isSuccess,
          isLoading: _testResults['safe_cast']?.isLoading ?? false,
          result: _testResults['safe_cast']?.result,
          error: _testResults['safe_cast']?.error,
          onRun: () => _runTest('safe_cast', () {
            const intValue = JsValue.integer(42);
            const strValue = JsValue.string('hello');
            return {
              'intValue': {
                'asBoolean': intValue.asBoolean,
                'asInteger': intValue.asInteger,
                'asFloat': intValue.asFloat,
                'asString': intValue.asString,
                'asNum': intValue.asNum,
              },
              'strValue': {
                'asBoolean': strValue.asBoolean,
                'asInteger': strValue.asInteger,
                'asFloat': strValue.asFloat,
                'asString': strValue.asString,
                'asNum': strValue.asNum,
              },
            };
          }),
        ),
      ],
    );
  }
}

class _TestResult {
  final bool isLoading;
  final bool? isSuccess;
  final dynamic result;
  final String? error;

  _TestResult({
    this.isLoading = false,
    this.isSuccess,
    this.result,
    this.error,
  });
}
