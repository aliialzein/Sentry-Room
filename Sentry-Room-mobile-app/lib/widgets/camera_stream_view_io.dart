import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  final List<int> _buffer = [];
  http.Client? _client;
  Uint8List? _latestFrame;
  bool _isConnecting = true;
  String? _errorMessage;
  int _streamToken = 0;

  @override
  void initState() {
    super.initState();
    _startStream();
  }

  @override
  void didUpdateWidget(covariant CameraStreamView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streamUrl != widget.streamUrl) {
      _startStream();
    }
  }

  @override
  void dispose() {
    _streamToken++;
    _client?.close();
    super.dispose();
  }

  Future<void> _startStream() async {
    final token = ++_streamToken;
    _client?.close();
    _buffer.clear();

    if (mounted) {
      setState(() {
        _isConnecting = true;
        _errorMessage = null;
        _latestFrame = null;
      });
    }

    final client = http.Client();
    _client = client;

    try {
      final request = http.Request('GET', Uri.parse(widget.streamUrl));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Camera stream returned ${response.statusCode}');
      }

      await for (final chunk in response.stream) {
        if (!mounted || token != _streamToken) return;
        _buffer.addAll(chunk);
        _trimOldCompleteFrames();
        _extractFrames();
      }
    } catch (e) {
      if (!mounted || token != _streamToken) return;
      setState(() {
        _isConnecting = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _extractFrames() {
    Uint8List? newestFrame;

    while (true) {
      final start = _indexOfJpegStart(_buffer);
      if (start == -1) {
        if (_buffer.length > 65536) {
          _buffer.removeRange(0, _buffer.length - 4096);
        }
        if (newestFrame != null) {
          _showFrame(newestFrame);
        }
        return;
      }

      if (start > 0) {
        _buffer.removeRange(0, start);
      }

      final end = _indexOfJpegEnd(_buffer, 2);
      if (end == -1) {
        if (newestFrame != null) {
          _showFrame(newestFrame);
        }
        return;
      }

      newestFrame = Uint8List.fromList(_buffer.sublist(0, end + 2));
      _buffer.removeRange(0, end + 2);
    }
  }

  void _trimOldCompleteFrames() {
    while (true) {
      final firstStart = _indexOfJpegStart(_buffer);
      if (firstStart == -1) {
        if (_buffer.length > 65536) {
          _buffer.removeRange(0, _buffer.length - 4096);
        }
        return;
      }

      if (firstStart > 0) {
        _buffer.removeRange(0, firstStart);
      }

      final firstEnd = _indexOfJpegEnd(_buffer, 2);
      if (firstEnd == -1) return;

      final nextStart = _indexOfJpegStartFrom(_buffer, firstEnd + 2);
      if (nextStart == -1) return;

      _buffer.removeRange(0, nextStart);
    }
  }

  void _showFrame(Uint8List frame) {
    if (!mounted) return;
    setState(() {
      _latestFrame = frame;
      _isConnecting = false;
      _errorMessage = null;
    });
  }

  int _indexOfJpegStartFrom(List<int> bytes, int startIndex) {
    for (var index = startIndex; index < bytes.length - 1; index++) {
      if (bytes[index] == 0xFF && bytes[index + 1] == 0xD8) {
        return index;
      }
    }
    return -1;
  }

  int _indexOfJpegStart(List<int> bytes) {
    for (var index = 0; index < bytes.length - 1; index++) {
      if (bytes[index] == 0xFF && bytes[index + 1] == 0xD8) {
        return index;
      }
    }
    return -1;
  }

  int _indexOfJpegEnd(List<int> bytes, int startIndex) {
    for (var index = startIndex; index < bytes.length - 1; index++) {
      if (bytes[index] == 0xFF && bytes[index + 1] == 0xD9) {
        return index;
      }
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    if (_latestFrame != null) {
      return Image.memory(
        _latestFrame!,
        fit: widget.fit,
        gaplessPlayback: true,
        width: double.infinity,
      );
    }

    if (_errorMessage != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            widget.snapshotUrl,
            fit: widget.fit,
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox.shrink(),
          ),
          Container(
            alignment: Alignment.center,
            color: Colors.black.withValues(alpha: 0.65),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam_off_rounded,
                    color: Colors.redAccent, size: 42),
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _startStream,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(
            _isConnecting ? 'Connecting to camera...' : 'Waiting for frames...',
            style: const TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
