// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

class CameraStreamView extends StatefulWidget {
  final String streamUrl;
  final String snapshotUrl;
  final BoxFit fit;

  const CameraStreamView({
    super.key,
    required this.streamUrl,
    required this.snapshotUrl,
    this.fit = BoxFit.contain,
  });

  @override
  State<CameraStreamView> createState() => _CameraStreamViewState();
}

class _CameraStreamViewState extends State<CameraStreamView> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'sentry-camera-stream-${DateTime.now().microsecondsSinceEpoch}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (_) {
      return html.ImageElement()
        ..src = widget.streamUrl
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = _objectFit(widget.fit)
        ..style.backgroundColor = '#000'
        ..style.display = 'block';
    });
  }

  String _objectFit(BoxFit fit) {
    switch (fit) {
      case BoxFit.cover:
        return 'cover';
      case BoxFit.fill:
        return 'fill';
      case BoxFit.none:
        return 'none';
      case BoxFit.scaleDown:
        return 'scale-down';
      case BoxFit.contain:
      case BoxFit.fitHeight:
      case BoxFit.fitWidth:
        return 'contain';
    }
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
