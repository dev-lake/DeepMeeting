import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'meeting_form_screen.dart';
import 'dart:async';
import '../widgets/loading_overlay.dart';
import '../services/xf_service.dart';
import '../services/deepseek_service.dart';
import '../models/meeting.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  late String _recordingPath;
  Duration _recordingDuration = Duration.zero;
  late Timer _timer;
  bool _isPaused = false;
  double? _amplitude;
  Timer? _amplitudeTimer;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    if (_isRecording) {
      _timer.cancel();
    }
    _amplitudeTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    if (!await _audioRecorder.hasPermission()) {
      // 显示权限说明对话框
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('需要录音权限'),
            content: const Text('为了记录会议内容，应用需要使用麦克风权限'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // 可以添加打开系统设置的逻辑
                },
                child: const Text('去设置'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        _recordingPath = '${directory.path}/recording_$timestamp.m4a';

        await _audioRecorder.start(
          const RecordConfig(),
          path: _recordingPath,
        );

        setState(() {
          _isRecording = true;
          _isPaused = false;
          _recordingDuration = Duration.zero;
        });

        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordingDuration += const Duration(seconds: 1);
          });
        });

        _amplitudeTimer =
            Timer.periodic(const Duration(milliseconds: 200), (_) async {
          final amplitude = await _audioRecorder.getAmplitude();
          setState(() {
            _amplitude = amplitude.current;
          });
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('开始录音失败: $e')),
        );
      }
    }
  }

  Future<void> _pauseRecording() async {
    try {
      await _audioRecorder.pause();
      setState(() {
        _isPaused = true;
      });
      _timer.cancel();
      _amplitudeTimer?.cancel();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('暂停录音失败: $e')),
        );
      }
    }
  }

  Future<void> _resumeRecording() async {
    try {
      await _audioRecorder.resume();
      setState(() {
        _isPaused = false;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration += const Duration(seconds: 1);
        });
      });
      _amplitudeTimer =
          Timer.periodic(const Duration(milliseconds: 200), (_) async {
        final amplitude = await _audioRecorder.getAmplitude();
        setState(() {
          _amplitude = amplitude.current;
        });
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('恢复录音失败: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      _timer.cancel();
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });

      if (path != null && mounted) {
        await _processRecording(path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('停止录音失败: $e')),
        );
      }
    }
  }

  Future<void> _processRecording(String audioPath) async {
    try {
      // 显示加载状态
      LoadingOverlay.show(
        context,
        status: '准备处理录音...',
        progress: 0.0,
      );

      // 更新状态为开始语音转写
      LoadingOverlay.show(
        context,
        status: '正在转写录音内容...',
        progress: 0.3,
      );

      // 调用讯飞语音转写API
      final text = await XFService().convertAudioToText(audioPath);

      // 创建会议对象并保存转录原文
      final meeting = Meeting();
      meeting.transcription = text;

      // 更新状态为开始生成会议纪要
      LoadingOverlay.show(
        context,
        status: '正在生成会议纪要...',
        progress: 0.6,
      );

      // 构建提示词
      final prompt = _buildPrompt(text);

      // 调用DeepSeek API生成摘要
      var summary = await DeepseekService().generate(prompt);

      // 移除<think></think>标签及其内容
      summary = _removeThinkTags(summary);

      meeting.content = summary;

      // 更新状态为完成
      LoadingOverlay.show(
        context,
        status: '处理完成！',
        progress: 1.0,
      );

      // 短暂延迟以显示完成状态
      await Future.delayed(const Duration(milliseconds: 500));

      // 隐藏加载动画
      LoadingOverlay.hide();

      // 导航到会议表单页面
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MeetingFormScreen(
              audioPath: audioPath,
              initialMeeting: meeting, // 传递包含转录原文的会议对象
            ),
          ),
        );
      }
    } catch (e) {
      // 错误处理...
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  String _buildPrompt(String transcription) {
    final StringBuffer prompt = StringBuffer();

    // 添加系统指令
    prompt.writeln('你是一个专业的会议纪要整理助手。请根据以下会议内容，生成一份结构化的会议纪要。');

    prompt.writeln('\n会议内容：');
    prompt.writeln(transcription);

    prompt.writeln('\n请按照以下格式生成会议纪要：');
    prompt.writeln('1. 会议主题（根据内容提炼）');
    prompt.writeln('2. 会议要点（列出3-5个重要讨论要点）');
    prompt.writeln('3. 具体讨论内容（按照时间顺序或主题逻辑组织）');
    prompt.writeln('4. 会议结论和后续行动项（如果有）');

    prompt.writeln('\n要求：');
    prompt.writeln('- 保持客观准确，使用正式的语言风格');
    prompt.writeln('- 突出重要信息，去除冗余内容');
    prompt.writeln('- 保持条理清晰，结构完整');

    return prompt.toString();
  }

  String _removeThinkTags(String content) {
    // 使用正则表达式移除<think>标签及其内容
    final regex = RegExp(r'<think>.*?</think>', dotAll: true);
    return content.replaceAll(regex, '').trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('录制会议'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatDuration(_recordingDuration),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            if (_isRecording && _amplitude != null)
              Container(
                width: 200,
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: Colors.grey[300],
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (_amplitude! + 160) / 160,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isRecording)
                  IconButton(
                    iconSize: 64,
                    icon: Icon(
                        _isPaused ? Icons.play_circle : Icons.pause_circle),
                    onPressed: _isPaused ? _resumeRecording : _pauseRecording,
                  ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: _isRecording ? _stopRecording : _startRecording,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording
                          ? Colors.red
                          : Theme.of(context).primaryColor,
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _isRecording ? (_isPaused ? '已暂停' : '正在录音...') : '点击开始录音',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
