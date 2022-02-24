// Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
// This product includes software developed at Datadog (https://www.datadoghq.com/).
// Copyright 2019-2021 Datadog, Inc.

import 'package:datadog_sdk/src/traces/ddtraces.dart';
import 'package:datadog_sdk/src/traces/ddtraces_method_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DdTracesMethodChannel ddTracesPlatform;
  final List<MethodCall> log = [];

  setUp(() {
    ddTracesPlatform = DdTracesMethodChannel();
    ddTracesPlatform.methodChannel.setMockMethodCallHandler((call) async {
      log.add(call);
      switch (call.method) {
        case 'startRootSpan':
          return 1;
        case 'startSpan':
          return 8;
        case 'getTracePropagationHeaders':
          return {'header-1': 'value-1', 'header-2': 'value-2'};
      }
      return null;
    });
  });

  tearDown(() {
    log.clear();
  });

  test('all calls with bad span do not call platform', () async {
    var badSpan = DdSpan(ddTracesPlatform, 0);
    await badSpan.setActive();
    await badSpan.setTag('Test Key', 'Test value');
    await badSpan.setBaggageItem('Baggage Key', 'Baggage value');
    await badSpan.setError(Exception());
    await badSpan.setErrorInfo('Kind', 'Message', null);
    await badSpan.finish();

    expect(log.length, 0);
  });

  test('start root span calls to platform', () async {
    var span = await ddTracesPlatform.startRootSpan(
        'Root Operation', null, {'testTag': 'testValue'}, null);

    expect(span, isNotNull);
    expect(span!.handle, 1);
    expect(log, <Matcher>[
      isMethodCall('startRootSpan', arguments: {
        'operationName': 'Root Operation',
        'resourceName': null,
        'tags': {'testTag': 'testValue'},
        'startTime': null
      })
    ]);
  });

  test('start span calls to platform', () async {
    var span = await ddTracesPlatform.startSpan(
        'Operation', null, null, {'testTag': 'testValue'}, null);

    expect(span, isNotNull);
    expect(span!.handle, 8);
    expect(log, <Matcher>[
      isMethodCall('startSpan', arguments: {
        'operationName': 'Operation',
        'parentSpan': null,
        'resourceName': null,
        'tags': {'testTag': 'testValue'},
        'startTime': null
      })
    ]);
  });

  test('start span passes parent handle', () async {
    var rootSpan = await ddTracesPlatform.startRootSpan(
        'Root operation', null, {'tag': 'value'}, null);
    var childSpan = await ddTracesPlatform.startSpan(
        'Child operation', rootSpan, null, null, null);

    expect(childSpan, isNotNull);
    expect(log, <Matcher>[
      isMethodCall('startRootSpan', arguments: {
        'operationName': 'Root operation',
        'resourceName': null,
        'tags': {'tag': 'value'},
        'startTime': null,
      }),
      isMethodCall('startSpan', arguments: {
        'operationName': 'Child operation',
        'resourceName': null,
        'parentSpan': 1,
        'tags': null,
        'startTime': null,
      }),
    ]);
  });

  test('start span converts milliseconds since epoch', () async {
    var startTime = DateTime.now().toUtc();
    await ddTracesPlatform.startSpan('Operation', null, null, null, startTime);

    expect(log, [
      isMethodCall('startSpan', arguments: {
        'operationName': 'Operation',
        'parentSpan': null,
        'resourceName': null,
        'tags': null,
        'startTime': startTime.millisecondsSinceEpoch,
      })
    ]);
  });

  test('start span converts to utc date string', () async {
    var startTime = DateTime.now();
    await ddTracesPlatform.startSpan('Operation', null, null, null, startTime);

    expect(log, [
      isMethodCall('startSpan', arguments: {
        'operationName': 'Operation',
        'parentSpan': null,
        'resourceName': null,
        'tags': null,
        'startTime': startTime.toUtc().millisecondsSinceEpoch,
      })
    ]);
  });

  test('start span passes resource name', () async {
    var startTime = DateTime.now();
    await ddTracesPlatform.startSpan(
        'Operation', null, 'mock resource name', null, startTime);

    expect(log, [
      isMethodCall('startSpan', arguments: {
        'operationName': 'Operation',
        'parentSpan': null,
        'resourceName': 'mock resource name',
        'tags': null,
        'startTime': startTime.toUtc().millisecondsSinceEpoch,
      })
    ]);
  });

  test('getTracePropagationHeaders calls platform', () async {
    final span =
        await ddTracesPlatform.startRootSpan('Operation', null, null, null);
    final headers = await ddTracesPlatform.getTracePropagationHeaders(span!);
    expect(
        log[1],
        isMethodCall('getTracePropagationHeaders', arguments: {
          'spanHandle': span.handle,
        }));
    expect(headers, {'header-1': 'value-1', 'header-2': 'value-2'});
  });

  test('finish span calls platform', () async {
    final span =
        await ddTracesPlatform.startRootSpan('Operation', null, null, null);
    var spanHandle = span!.handle;
    await span.finish();

    expect(log[1],
        isMethodCall('span.finish', arguments: {'spanHandle': spanHandle}));
  });

  test('finish span invalidates handle', () async {
    final span =
        await ddTracesPlatform.startRootSpan('Operation', null, null, null);
    await span!.finish();

    expect(span.handle, lessThanOrEqualTo(0));
  });

  test('setTag on span calls to platform', () async {
    final span =
        await ddTracesPlatform.startRootSpan('Operation', null, null, null);
    await span!.setTag('my tag', 'tag value');

    expect(
        log[1],
        isMethodCall('span.setTag', arguments: {
          'spanHandle': span.handle,
          'key': 'my tag',
          'value': 'tag value',
        }));
  });

  test('setBaggageItem calls to platform', () async {
    final span =
        await ddTracesPlatform.startRootSpan('Operation', null, null, null);
    await span!.setBaggageItem('my key', 'my value');

    expect(
        log[1],
        isMethodCall('span.setBaggageItem', arguments: {
          'spanHandle': span.handle,
          'key': 'my key',
          'value': 'my value'
        }));
  });

  test('setTag calls to platform', () async {
    final span =
        await ddTracesPlatform.startRootSpan('Operation', null, null, null);
    await span!.setTag('my key', 'my value');

    expect(
        log[1],
        isMethodCall('span.setTag', arguments: {
          'spanHandle': span.handle,
          'key': 'my key',
          'value': 'my value'
        }));
  });

  test('setError on span calls to platform', () async {
    final span =
        await ddTracesPlatform.startRootSpan('Operation', null, null, null);
    StackTrace? caughtStackTrace;
    Exception? caughtException;

    try {
      throw Exception('Test Throw Exception');
    } on Exception catch (e, s) {
      caughtException = e;
      caughtStackTrace = s;
      await span!.setError(e, s);
    }

    expect(
        log[1],
        isMethodCall('span.setError', arguments: {
          'spanHandle': span.handle,
          'kind': caughtException.runtimeType.toString(),
          'message': caughtException.toString(),
          'stackTrace': caughtStackTrace.toString(),
        }));
  });

  test('setErrorInfo on span calls to platform', () async {
    final span =
        await ddTracesPlatform.startRootSpan('Operation', null, null, null);

    await span!.setErrorInfo('Generic Error', 'This was my fault', null);

    var spanCall = log[1];

    expect(spanCall.method, 'span.setError');
    expect(spanCall.arguments['spanHandle'], span.handle);
    expect(spanCall.arguments['kind'], 'Generic Error');
    expect(spanCall.arguments['message'], 'This was my fault');
    expect(spanCall.arguments['stackTrace'], isNotNull);
  });

  test('setErrorInfo on span calls to platform', () async {
    final span =
        await ddTracesPlatform.startRootSpan('Operation', null, null, null);

    await span!.log({
      'message': 'my message',
      'value': 0.24,
    });

    expect(
        log[1],
        isMethodCall('span.log', arguments: {
          'spanHandle': span.handle,
          'fields': {'message': 'my message', 'value': 0.24}
        }));
  });
}
