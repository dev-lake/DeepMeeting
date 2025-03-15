import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/meeting.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/meeting_record.dart';
import '../services/database_helper.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';

class MeetingSummaryScreen extends StatefulWidget {
  final Meeting meeting;
  final String? audioPath;
  final bool isReadOnly;

  const MeetingSummaryScreen({
    super.key,
    required this.meeting,
    this.audioPath,
    this.isReadOnly = false,
  });

  @override
  State<MeetingSummaryScreen> createState() => _MeetingSummaryScreenState();
}

class _MeetingSummaryScreenState extends State<MeetingSummaryScreen> {
  final _audioPlayer = AudioPlayer();
  bool _isLoading = true;
  String? _errorMessage;
  bool _showTranscription = false;

  void _copyToClipboard(BuildContext context, {bool transcription = false}) {
    final textToCopy =
        transcription ? widget.meeting.transcription : widget.meeting.content;

    Clipboard.setData(ClipboardData(text: textToCopy)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(transcription ? '转录原文已复制到剪贴板' : '内容已复制到剪贴板'),
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }

  Future<void> _saveMeeting() async {
    if (widget.audioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法保存：缺少音频文件')),
      );
      return;
    }

    final meetingRecord = MeetingRecord(
      title: '会议记录 ${widget.meeting.meetingTime}',
      attendees: widget.meeting.attendees,
      meetingTime: widget.meeting.meetingTime,
      duration: widget.meeting.duration,
      meetingEndTime: widget.meeting.meetingEndTime,
      recorder: widget.meeting.recorder,
      reviewer: widget.meeting.reviewer,
      audioPath: widget.audioPath!,
      content: widget.meeting.content,
      transcription: widget.meeting.transcription,
    );

    try {
      await DatabaseHelper.instance.insertMeeting(meetingRecord);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('会议记录已保存')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  Future<void> _initAudioPlayer() async {
    if (widget.audioPath == null) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      debugPrint('尝试加载音频文件: ${widget.audioPath}');

      // 检查文件是否存在
      final file = File(widget.audioPath!);
      if (!await file.exists()) {
        throw '音频文件不存在';
      }

      debugPrint('文件存在，大小: ${await file.length()} 字节');

      await _audioPlayer.setFilePath(widget.audioPath!);
      final duration = await _audioPlayer.duration;

      debugPrint('音频加载成功，时长: $duration');

      setState(() {
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('音频加载错误: $e');
      debugPrint('错误堆栈: $stackTrace');
      setState(() {
        _isLoading = false;
        _errorMessage = '音频加载失败: $e';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showTranscription ? '会议转录原文' : '会议纪要预览'),
        actions: [
          IconButton(
            icon: Icon(_showTranscription ? Icons.summarize : Icons.subject),
            tooltip: _showTranscription ? '查看摘要' : '查看转录原文',
            onPressed: () {
              setState(() {
                _showTranscription = !_showTranscription;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: '复制内容',
            onPressed: () =>
                _copyToClipboard(context, transcription: _showTranscription),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveMeeting,
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.audioPath != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: _buildAudioPlayer(),
                    ),
                  SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight - 32.0,
                    child: _showTranscription
                        ? SingleChildScrollView(
                            child: SelectableText(
                              widget.meeting.transcription,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          )
                        : Markdown(
                            data: widget.meeting.content,
                            selectable: true,
                            styleSheet: MarkdownStyleSheet(
                              h1: Theme.of(context).textTheme.headlineMedium,
                              h2: Theme.of(context).textTheme.titleLarge,
                              h3: Theme.of(context).textTheme.titleMedium,
                              p: Theme.of(context).textTheme.bodyLarge,
                              listBullet: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAudioPlayer() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Text(_errorMessage!, style: const TextStyle(color: Colors.red));
    }

    return Row(
      children: [
        StreamBuilder<PlayerState>(
          stream: _audioPlayer.playerStateStream,
          builder: (context, snapshot) {
            final playing = snapshot.data?.playing ?? false;
            return IconButton(
              icon: Icon(playing ? Icons.pause : Icons.play_arrow),
              onPressed: () {
                if (playing) {
                  _audioPlayer.pause();
                } else {
                  _audioPlayer.play();
                }
              },
            );
          },
        ),
        Expanded(
          child: StreamBuilder<Duration>(
            stream: _audioPlayer.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final duration = _audioPlayer.duration ?? Duration.zero;
              return Slider(
                value: position.inMilliseconds.toDouble(),
                max: duration.inMilliseconds.toDouble(),
                onChanged: (value) {
                  _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                },
              );
            },
          ),
        ),
        StreamBuilder<Duration>(
          stream: _audioPlayer.positionStream,
          builder: (context, snapshot) {
            final position = snapshot.data ?? Duration.zero;
            final duration = _audioPlayer.duration ?? Duration.zero;
            return Text(
              '${position.toString().split('.').first} / ${duration.toString().split('.').first}',
              style: Theme.of(context).textTheme.bodySmall,
            );
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _audioPlayer.stop().then((_) {
      _audioPlayer.dispose();
    });
    super.dispose();
  }
}
