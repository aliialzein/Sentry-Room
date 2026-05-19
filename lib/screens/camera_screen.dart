import 'package:flutter/material.dart';

import '../constants/api_constants.dart';
import '../widgets/camera_stream_view.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  int _streamVersion = 0;

  String get _streamUrl {
    final separator = ApiConstants.cameraStreamUrl.contains('?') ? '&' : '?';
    return '${ApiConstants.cameraStreamUrl}${separator}v=$_streamVersion';
  }

  String get _snapshotUrl {
    final separator = ApiConstants.cameraSnapshotUrl.contains('?') ? '&' : '?';
    return '${ApiConstants.cameraSnapshotUrl}${separator}v=$_streamVersion';
  }

  void _reloadStream() {
    setState(() {
      _streamVersion = DateTime.now().millisecondsSinceEpoch;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Camera'),
        actions: [
          IconButton(
            tooltip: 'Reload camera',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _reloadStream,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _reloadStream(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              clipBehavior: Clip.antiAlias,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: Colors.black,
                  child: CameraStreamView(
                    key: ValueKey(_streamUrl),
                    streamUrl: _streamUrl,
                    snapshotUrl: _snapshotUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Camera Endpoint',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      ApiConstants.cameraStreamUrl,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
