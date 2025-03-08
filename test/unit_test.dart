import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:deepmeeting_app/services/xf_service.dart';
import 'package:path/path.dart' as path;
import 'package:deepmeeting_app/services/deepseek_service.dart';

void main() {
  const audioPath = 'assests/test.wav';
  test('xf stt upload and get result', () async {
    // 1. 上传文件
    final file = File(audioPath);
    final fileSize = await file.length();

    final orderId = await XFService().uploadFile(audioPath, fileSize);
    print('上传成功，订单ID: $orderId');
    expect(orderId.length, 'DKHJQ20250306115848364gBmb0SVijtpve9Wl'.length);

    // 获取 结果
    final TranscriptionResult res = await XFService().getResult(orderId);
    print(res);
    expect(res.status != -1 && res.status != 0, true);
  });

  test('test entire xf stt', () async {
    final content = await XFService().convertAudioToText(audioPath);
    print('content.length: ${content.length}');
    print('content: ${content}');
    expect(content.length > 10, true);
  });

  test('DeepseekService should generate summary', () async {
    final service = DeepseekService();
    final summary = await service.generate('你好');
    print(summary);
    expect(summary, isNotEmpty);
  }, timeout: const Timeout(Duration(seconds: 120)));
}
