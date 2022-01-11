// Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
// This product includes software developed at Datadog (https://www.datadoghq.com/).
// Copyright 2019-2021 Datadog, Inc.

import 'package:flutter/material.dart';

import 'ddrum_platform_interface.dart';

/// HTTP method of the resource
enum RumHttpMethod { post, get, head, put, delete, patch }

/// Describes the type of a RUM Action.
enum RumUserActionType { tap, scroll, swipe, custom }

/// Describe the source of a RUM Error.
enum RumErrorSource {
  /// Error originated in the source code.
  source,

  /// Error originated in the network layer.
  network,

  /// Error originated in a webview.
  webview,

  /// Error originated in a web console (used by bridges).
  console,

  /// Custom error source.
  custom,
}

/// Describe the type of resource loaded.
enum RumResourceType {
  document,
  image,
  xhr,
  beacon,
  css,
  fetch,
  font,
  js,
  media,
  other,
  native
}

// ignore: unused_element
const String _ddRumErrorTypeKey = '_dd.error.source_type';

class DdRum {
  static DdRumPlatform get _platform {
    return DdRumPlatform.instance;
  }

  /// Notifies that the View identified by [key] starts being presented to the
  /// user. This view will show as [name] in the RUM explorer, and defaults to
  /// [key] if it is not provided. You can also attach custom [attributes],
  /// who's values must be supported by [StandardMessageCodec].
  ///
  /// The [key] passed here must match the [key] passed to [stopView] later.
  Future<void> startView(String key,
      [String? name, Map<String, dynamic> attributes = const {}]) {
    name ??= key;
    return _platform.startView(key, name, attributes);
  }

  /// Notifies that the View identified by [key] stops being presented to the
  /// user. You can also attach custom [attributes], who's values must be
  /// supported by [StandardMessageCodec].
  ///
  /// The [key] passed here must match the [key] passed to [startView].
  Future<void> stopView(String key,
      [Map<String, dynamic> attributes = const {}]) {
    return _platform.stopView(key, attributes);
  }

  /// Adds a specific timing named [name] in the currently presented View. The
  /// timing duration will be computed as the number of nanoseconds between the
  /// time the View was started and the time the timing was added.
  Future<void> addTiming(String name) {
    return _platform.addTiming(name);
  }

  /// Notifies that the Exception or Error [error] occurred in currently
  /// presented View, with an origin of [source]. You can optionally set
  /// additional [attributes] for this error
  Future<void> addError(Object error, RumErrorSource source,
      {StackTrace? stackTrace, Map<String, dynamic> attributes = const {}}) {
    // TODO: RUMM-1899 / RUMM-1900 - add flutter as an error source_type
    //attributes[_ddRumErrorTypeKey] = 'flutter';
    return _platform.addError(error, source, stackTrace, attributes);
  }

  /// Notifies that an error occurred in currently presented View, with the
  /// supplied [message] and with an origin of [source]. You can optionally
  /// supply a [stackTrace] and send additional [attributes] for this error
  Future<void> addErrorInfo(String message, RumErrorSource source,
      {StackTrace? stackTrace, Map<String, dynamic> attributes = const {}}) {
    // TODO: RUMM-1899 / RUMM-1900 - add flutter as an error source_type
    //attributes[_ddRumErrorTypeKey] = 'flutter';
    return _platform.addErrorInfo(message, source, stackTrace, attributes);
  }

  Future<void> handleFlutterError(FlutterErrorDetails details) {
    return addErrorInfo(
      details.exceptionAsString(),
      RumErrorSource.source,
      stackTrace: details.stack,
      attributes: {'flutter_error_reason': details.context?.toString()},
    );
  }

  /// Notifies that the a Resource identified by [key] started being loaded from
  /// given [url] using the specified [httpMethod]. The supplied custom
  /// [attributes] will be attached to this Resource.
  ///
  /// Note that [key] must be unique among all Resources being currently loaded,
  /// and should be sent to [stopResourceLoading] or
  /// [stopResourceLoadingWithError] / [stopResourceLoadingWithErrorInfo] when
  /// resource loading is complete.
  Future<void> startResourceLoading(
      String key, RumHttpMethod httpMethod, String url,
      [Map<String, dynamic> attributes = const {}]) {
    return _platform.startResourceLoading(key, httpMethod, url, attributes);
  }

  /// Notifies that the Resource identified by [key] stopped being loaded
  /// successfully and supplies additional information about the Resource loaded,
  /// including its [kind], the [statusCode] of the response, the [size] of the
  /// Resource, and any other custom [attributes] to attach to the resource.
  Future<void> stopResourceLoading(
      String key, int? statusCode, RumResourceType kind,
      [int? size, Map<String, dynamic> attributes = const {}]) {
    return _platform.stopResourceLoading(
        key, statusCode, kind, size, attributes);
  }

  /// Notifies that the Resource identified by [key] stopped being loaded with an
  /// Exception specified by [error]. You can optionally supply custom
  /// [attributes] to attach to this Resource.
  Future<void> stopResourceLoadingWithError(String key, Exception error,
      [Map<String, dynamic> attributes = const {}]) {
    return _platform.stopResourceLoadingWithError(key, error, attributes);
  }

  /// Notifies that the Resource identified by [key] stopped being loaded with
  /// the supplied [message]. You can optionally supply custom [attributes] to
  /// attach to this Resource.
  Future<void> stopResourceLoadingWithErrorInfo(String key, String message,
      [Map<String, dynamic> attributes = const {}]) {
    return _platform.stopResourceLoadingWithErrorInfo(key, message, attributes);
  }

  /// Register the occurrence of a User Action.
  ///
  /// This is used to a track discrete User Actions (e.g. "tap") specified by
  /// [type]. The [name] and [attributes] supplied will be associated with this
  /// user action.
  Future<void> addUserAction(RumUserActionType type, String? name,
      [Map<String, dynamic> attributes = const {}]) {
    return _platform.addUserAction(type, name, attributes);
  }
}
