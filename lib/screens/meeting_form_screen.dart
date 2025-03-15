import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/xf_service.dart';
import '../services/deepseek_service.dart';
import '../models/meeting.dart';
import 'meeting_summary_screen.dart';
import '../widgets/loading_overlay.dart';

class MeetingFormScreen extends StatefulWidget {
  final String? audioPath;
  final Meeting? initialMeeting;

  const MeetingFormScreen({
    super.key,
    this.audioPath,
    this.initialMeeting,
  });

  @override
  State<MeetingFormScreen> createState() => _MeetingFormScreenState();
}

class _MeetingFormScreenState extends State<MeetingFormScreen> {
  final pageTitle = 'DeepMeeting';
  final _formKey = GlobalKey<FormState>();
  late Meeting _meeting;
  String? _audioPath;
  final TextEditingController _attendeeController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final List<String> _attendees = [];
  DateTime _selectedDateTime = DateTime.now();
  int _durationInMinutes = 60; // 默认时长1小时
  bool _hasProcessedContent = false;

  @override
  void initState() {
    super.initState();
    _meeting = widget.initialMeeting ?? Meeting();

    if (widget.audioPath != null) {
      _audioPath = widget.audioPath;
    }

    _hasProcessedContent = widget.initialMeeting?.content.isNotEmpty ?? false;

    _timeController.text = _formatDateTime(_selectedDateTime);
    _durationController.text = '1小时';
    _updateEndTime();
  }

  @override
  void dispose() {
    _attendeeController.dispose();
    _timeController.dispose();
    _durationController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}年${dateTime.month}月${dateTime.day}日 ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _updateEndTime() {
    final endTime =
        _selectedDateTime.add(Duration(minutes: _durationInMinutes));
    _endTimeController.text = _formatDateTime(endTime);
    _meeting.meetingEndTime = _endTimeController.text;
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('zh'),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (pickedTime != null && mounted) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _timeController.text = _formatDateTime(_selectedDateTime);
          _meeting.meetingTime = _timeController.text;
        });
      }
    }
  }

  Future<void> _selectDuration() async {
    final List<String> durations = [
      '30分钟',
      '1小时',
      '1.5小时',
      '2小时',
      '2.5小时',
      '3小时'
    ];
    final Map<String, int> durationValues = {
      '30分钟': 30,
      '1小时': 60,
      '1.5小时': 90,
      '2小时': 120,
      '2.5小时': 150,
      '3小时': 180,
    };

    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('选择会议时长'),
          children: durations.map((String duration) {
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, duration);
              },
              child: Text(duration),
            );
          }).toList(),
        );
      },
    );

    if (result != null) {
      setState(() {
        _durationController.text = result;
        _durationInMinutes = durationValues[result]!;
        _updateEndTime();
      });
    }
  }

  void _addAttendee(String attendee) {
    if (attendee.trim().isNotEmpty && !_attendees.contains(attendee.trim())) {
      setState(() {
        _attendees.add(attendee.trim());
        _attendeeController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('填写会议信息'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '会议基本信息',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _attendeeController,
                              decoration: const InputDecoration(
                                labelText: '参会人员',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.people),
                                hintText: '输入姓名后点击添加',
                              ),
                              onFieldSubmitted: _addAttendee,
                              validator: (value) =>
                                  _attendees.isEmpty ? '请至少添加一位参会人员' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              if (_attendeeController.text.isNotEmpty) {
                                _addAttendee(_attendeeController.text);
                              }
                            },
                            icon: const Icon(Icons.add_circle),
                            color: Theme.of(context).primaryColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_attendees.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _attendees.map((attendee) {
                              return Chip(
                                label: Text(attendee),
                                deleteIcon: const Icon(Icons.cancel, size: 18),
                                onDeleted: () {
                                  setState(() {
                                    _attendees.remove(attendee);
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _timeController,
                          decoration: const InputDecoration(
                            labelText: '开始时间',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.access_time),
                            suffixIcon: Icon(Icons.arrow_drop_down),
                          ),
                          readOnly: true,
                          onTap: _selectDateTime,
                          validator: (value) =>
                              value?.isEmpty ?? true ? '请选择开始时间' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _durationController,
                          decoration: const InputDecoration(
                            labelText: '会议时长',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.timer),
                            suffixIcon: Icon(Icons.arrow_drop_down),
                          ),
                          readOnly: true,
                          onTap: _selectDuration,
                          validator: (value) =>
                              value?.isEmpty ?? true ? '请选择会议时长' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _endTimeController,
                    decoration: const InputDecoration(
                      labelText: '结束时间',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.access_time_filled),
                    ),
                    readOnly: true,
                    enabled: false,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: '记录人',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.edit),
                    ),
                    onSaved: (value) => _meeting.recorder = value ?? '',
                    validator: (value) =>
                        value?.isEmpty ?? true ? '请输入记录人' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: '审核人',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.verified_user),
                    ),
                    onSaved: (value) => _meeting.reviewer = value ?? '',
                    validator: (value) =>
                        value?.isEmpty ?? true ? '请输入审核人' : null,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '会议录音',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _audioPath ?? '未选择文件',
                            style: TextStyle(
                              color: _audioPath != null
                                  ? Colors.black
                                  : Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _pickAudioFile,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('选择文件'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _processMeeting,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('生成会议纪要'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAudioFile() async {
    try {
      print('开始选择文件...'); // 调试信息
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac'], // 指定允许的音频格式
        allowMultiple: false,
        withData: false, // 不加载文件数据到内存
        withReadStream: false, // 不使用读取流
      );

      print('选择结果: ${result?.files.length ?? 0} 个文件'); // 调试信息

      if (result != null && mounted) {
        final path = result.files.single.path;
        print('选中文件路径: $path'); // 调试信息

        setState(() {
          _audioPath = path;
        });
      } else {
        print('未选择文件或选择被取消'); // 调试信息
      }
    } catch (e, stackTrace) {
      print('文件选择错误: $e'); // 调试信息
      print('错误堆栈: $stackTrace'); // 添加堆栈跟踪
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择文件失败: $e')),
        );
      }
    }
  }

  Future<void> _processMeeting() async {
    if (!_formKey.currentState!.validate() || _audioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写所有必填项并选择录音文件')),
      );
      return;
    }

    try {
      _formKey.currentState!.save();
      _meeting.attendees = _attendees.join('、');
      _meeting.meetingTime = _timeController.text;
      _meeting.duration = _durationController.text;

      // 显示准备状态
      LoadingOverlay.show(
        context,
        status: '准备处理音频文件...',
        progress: 0.0,
      );

      // 更新状态为开始语音转写
      LoadingOverlay.show(
        context,
        status: '正在提炼内容...',
        progress: 0.3,
      );

      // 调用讯飞语音转写API
      final text = await XFService().convertAudioToText(_audioPath!);

      // 保存转录原文
      _meeting.transcription = text;

      // 更新状态为开始生成会议纪要
      LoadingOverlay.show(
        context,
        status: '正在生成会议纪要...',
        progress: 0.6,
      );

      // 构建提示词
      final prompt = _buildPrompt(text);

      // 调用DeepSeek API生成摘要并处理返回内容
      var summary = await DeepseekService().generate(prompt);

      // 移除<think></think>标签及其内容
      summary = _removeThinkTags(summary);

      _meeting.content = summary;

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

      // 导航到预览页面
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MeetingSummaryScreen(
              meeting: _meeting,
              audioPath: _audioPath,
            ),
          ),
        );
      }
    } catch (e) {
      LoadingOverlay.show(
        context,
        status: '处理失败',
        progress: 0.0,
      );

      await Future.delayed(const Duration(seconds: 1));
      LoadingOverlay.hide();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('处理失败: $e')),
        );
      }
    }
  }

  String _buildPrompt(String transcription) {
    final StringBuffer prompt = StringBuffer();

    // 添加系统指令
    prompt.writeln('你是一个专业的会议纪要整理助手。请根据以下会议信息和会议内容，生成一份结构化的会议纪要。');
    prompt.writeln('\n会议基本信息：');
    prompt.writeln('- 参会人员：${_meeting.attendees}');
    prompt.writeln('- 开始时间：${_meeting.meetingTime}');
    prompt.writeln('- 会议时长：${_meeting.duration}');
    prompt.writeln('- 结束时间：${_meeting.meetingEndTime}');
    prompt.writeln('- 记录人：${_meeting.recorder}');
    prompt.writeln('- 审核人：${_meeting.reviewer}');

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
    prompt.writeln('- 如果发现会议内容中有重要的时间节点、数字或关键决策，请特别标注');

    return prompt.toString();
  }

  String _removeThinkTags(String content) {
    // 使用正则表达式移除<think>标签及其内容
    final regex = RegExp(r'<think>.*?</think>', dotAll: true);
    return content.replaceAll(regex, '').trim();
  }
}
