import 'package:flutter/material.dart';
import 'package:lat_hdr_transcoder/lat_hdr_transcoder.dart';

import '../transcoder.dart';
import 'video_view.dart';

class SelectedVideo extends StatefulWidget {
  const SelectedVideo({
    super.key,
    required this.path,
    required this.onClear,
  });

  final String path;
  final void Function() onClear;

  @override
  State<SelectedVideo> createState() => _SelectedVideoState();
}

class _SelectedVideoState extends State<SelectedVideo> {
  bool? isHdr;
  String? convertedPath;
  bool converting = false;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    print('origin path: ${widget.path}');
  }

  Future<void> _converting() async {
    converting = true;
    setState(() {});

    final coder = TranscoderLatHdr(path: widget.path);
    // final coder = TranscoderLightCompresor(path: widget.path);

    convertedPath = await coder.transcoding();
    converting = false;
    setState(() {});
    print('converted path: $convertedPath');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('origin path:\n${widget.path}'),
        const SizedBox(height: 8),
        if (convertedPath != null) Text('converted path:\n$convertedPath'),
        if (isHdr != null) Text('HDR: $isHdr'),
        _buildCheckHdrButton(),
        _buildConvertButton(),
        _buildVideo(),
        _buildClearButton(),
      ],
    );
  }

  Widget _buildCheckHdrButton() {
    return ElevatedButton(
      onPressed: () async {
        isHdr = await LatHdrTranscoder().isHDR(widget.path);
        setState(() {});
      },
      child: const Text('1. check HDR'),
    );
  }

  Widget _buildConvertButton() {
    if (converting) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: CircularProgressIndicator.adaptive(),
      );
    }

    return ElevatedButton(
      onPressed: isHdr == true ? _converting : null,
      child: const Text('2. Convert'),
    );
  }

  Widget _buildClearButton() {
    return ElevatedButton(
      onPressed: widget.onClear,
      child: const Text('Clear'),
    );
  }

  Widget _buildVideo() {
    final path = convertedPath ?? widget.path;

    return Container(
      color: Colors.grey,
      width: 300,
      height: 300,
      alignment: Alignment.center,
      child: VideoView(path: path),
    );
  }
}
