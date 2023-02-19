import 'dart:io';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  final picker = FilePicker.platform;
  File? _selectedVideo;
  FrameData? _frameData;
  String? _apiResponse;
  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(
        'https://www.sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4');
    _initializeVideoPlayerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // _pickVideo() async{
  //   final video = await picker.getVideo(source: ImageSource.gallery);
  //   _video = File(video?.path);
  // }

  Future<void> _selectVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null) {
      setState(() {
        _selectedVideo = File(result.files.single.path!);
        _controller = VideoPlayerController.file(_selectedVideo!);
        _initializeVideoPlayerFuture = _controller.initialize();
      });
    }
  }

  Future<void> pickVideo() async {
    final result = await picker.pickFiles(type: FileType.video);

    if (result != null) {
      setState(() {
        _selectedVideo = File(result.files.single.path!);
        _controller = VideoPlayerController.file(_selectedVideo!);
      });
    }
  }

  Future<void> sendApiRequest() async {
    final response = await http.post(
      Uri.parse('https://example.com/api'),
      body: {'video_path': _selectedVideo?.path},
    );

    if (response.statusCode == 200) {
      setState(() {
        _apiResponse = response.body;
      });
    }
  }

  Future<void> sendVideo() async {
    final request = await HttpClient().postUrl(Uri.parse('https://example.com/upload'));
    request.headers.set('content-type', 'video/mp4');
    request.add(await _selectedVideo!.readAsBytes());
    final response = await request.close();

    if (response.statusCode == 200) {
      // Video was uploaded successfully
      print('Video uploaded!');
    } else {
      // Video upload failed
      print('Video upload failed!');
    }
  }

  Future<void> _sendFrame() async {
    final bytes = await VideoThumbnail.thumbnailData(
      video: [_selectedVideo?.path].toString(),
      imageFormat: ImageFormat.JPEG,
      quality: 50,
    );
    final base64EncodedData = base64Encode(bytes!);
    final response = await http.post(
      Uri.parse('https://example.com/send_frame'),
      body: {
        'frame': base64EncodedData,
      },
    );
    if (response.statusCode == 200) {
      setState(() {
      });
    } else {
      setState(() {
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title.toString()),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FutureBuilder(
                    future: _initializeVideoPlayerFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        );
                      } else {
                        return CircularProgressIndicator();
                      }
                    },
                  ),
                  IconButton(
                    onPressed: () {
                      if (_controller.value.isPlaying) {
                        _controller.pause();
                      } else {
                        _controller.play();
                      }
                    },
                    icon: Icon(_controller.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow),
                  ),
                  IconButton(
                    onPressed: () {
                      _controller.seekTo(Duration.zero);
                    },
                    icon: Icon(Icons.replay),
                  ),
                  IconButton(
                    onPressed: sendVideo,
                    icon: Icon(Icons.send),
                  ),
                  IconButton(
                    onPressed: sendApiRequest,
                    icon: Icon(Icons.send),
                  ),
                ],
              ),
              if (_apiResponse != null) Text(_apiResponse!),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.cyan),
                  overlayColor: MaterialStateProperty.all(Colors.red),
                ),
                onPressed: _selectVideo,
                child: const Text('Select Video'),
              ),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.cyan),
                  overlayColor: MaterialStateProperty.all(Colors.red),
                ),
                onPressed: _sendFrame,
                child: const Text('Send Frame'),
              ),
              const SizedBox(
                height: 20.0,
              ),
              Text(_frameData.toString(), style: TextStyle(fontWeight: FontWeight.bold),),
            ],
          ),
        ),
      ),
    );
  }
}
