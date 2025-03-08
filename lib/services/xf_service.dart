import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../config/api_config.dart';

class XFService {
  // 配置讯飞API参数
  final String _appId = APIConfig.xfAppId;
  final String _apiSecret = APIConfig.xfApiSecret;
  final String _host = APIConfig.xfSTTUrl;

  Future<String> convertAudioToText(String audioPath) async {
    try {
      final file = File(audioPath);
      final fileSize = await file.length();
      final fileName = path.basename(audioPath);

      // 检查文件格式
      final extension = path.extension(fileName).toLowerCase();
      final validFormats = [
        '.mp3',
        '.wav',
        '.pcm',
        '.aac',
        '.opus',
        '.flac',
        '.ogg',
        '.m4a',
        '.amr'
      ];
      if (!validFormats.contains(extension)) {
        throw Exception('不支持的音频格式: $extension');
      }

      final orderId = await uploadFile(audioPath, fileSize);
      print('上传成功，订单ID: $orderId');

      // 优化轮询逻辑
      String text = '';
      bool isCompleted = false;
      int retryCount = 0;
      const maxRetries = 100; // 最大重试次数

      while (!isCompleted && retryCount < maxRetries) {
        // 根据音频时长动态调整轮询间隔
        final pollInterval =
            fileSize > 10 * 1024 * 1024 ? 10 : 5; // 大文件10秒,小文件5秒
        await Future.delayed(Duration(seconds: pollInterval));

        final result = await getResult(orderId);
        print(result);

        if (result.status == 4) {
          text = _parseResult(result.orderResult);
          print('_parseResult ${text}');
          isCompleted = true;
        } else if (result.status == -1) {
          if (result.failType == 11) {
            print('11：upload接口创建任务时，未开启质检或者翻译能力；');
            text = _parseResult(result.orderResult);
            break;
          } else {
            throw Exception('转写失败,错误类型: ${result.failType}');
          }
        }

        retryCount++;
        if (retryCount >= maxRetries) {
          throw Exception('转写超时,请检查音频文件');
        }
      }

      return text;
    } catch (e) {
      throw Exception('语音转写失败: $e');
    }
  }

  Future<String> uploadFile(String filePath, int fileSize) async {
    final fileName = path.basename(filePath);

    // 添加音频文件大小检查
    if (fileSize > 500 * 1024 * 1024) {
      throw Exception('音频文件大小不能超过500MB');
    }

    final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000.0;
    final signa = _generateSigna(ts.toString());

    // 构建查询参数
    final queryParams = {
      'appId': _appId,
      'signa': signa,
      'ts': ts.toString(),
      'fileSize': fileSize.toString(),
      'fileName': fileName,
      'duration': '200',
    };

    // 构建URL
    final uri = Uri.parse('$_host/upload').replace(
      queryParameters: queryParams,
    );

    // 读取文件内容
    final file = File(filePath);
    final bytes = await file.readAsBytes();

    // 发送请求
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: bytes,
    );

    final json = jsonDecode(response.body);

    if (json['code'] != '000000') {
      throw Exception('上传失败: ${json['descInfo']}');
    }

    return json['content']['orderId'];
  }

  Future<TranscriptionResult> getResult(String orderId) async {
    final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000.0;
    final signa = _generateSigna(ts.toString());

    // 构建查询参数
    final queryParams = {
      'appId': _appId,
      'signa': signa,
      'ts': ts.toString(),
      'orderId': orderId,
      'resultType': 'transfer,predict',
    };

    final uri = Uri.parse('$_host/getResult').replace(
      queryParameters: queryParams,
    );

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    final json = jsonDecode(response.body);

    if (json['code'] != '000000') {
      throw Exception('获取结果失败: ${json['descInfo']}');
    }

    return TranscriptionResult.fromJson(json['content']);
  }

  String _generateSigna(String ts) {
    // 生成md5
    final md5Hash = md5.convert(utf8.encode(_appId + ts)).toString();

    // 使用hmac-sha1加密
    final hmacSha1 = Hmac(sha1, utf8.encode(_apiSecret));
    final signature = hmacSha1.convert(utf8.encode(md5Hash));

    // base64编码
    return base64.encode(signature.bytes);
  }

  String _parseResult(String orderResult) {
    final json = jsonDecode(orderResult);
    final StringBuffer text = StringBuffer();

    // 从 lattice 或 lattice2 中提取文本
    final latticeList = json['lattice2'] ?? json['lattice'] ?? [];

    for (var item in latticeList) {
      var json1best = item['json_1best'];
      if (json1best is String) {
        json1best = jsonDecode(json1best);
      }

      if (json1best.containsKey('st')) {
        for (var rt in json1best['st']['rt']) {
          for (var ws in rt['ws']) {
            for (var cw in ws['cw']) {
              final word = cw['w'];
              if (word != null && word.isNotEmpty) {
                text.write(word);
              }
            }
          }
        }
      }
    }

    return text.toString();
  }
}

class TranscriptionResult {
  final int status;
  final int failType;
  final String orderResult;

  TranscriptionResult({
    required this.status,
    required this.failType,
    required this.orderResult,
  });

  factory TranscriptionResult.fromJson(Map<String, dynamic> json) {
    return TranscriptionResult(
      status: json['orderInfo']['status'],
      failType: json['orderInfo']['failType'],
      orderResult: json['orderResult'] ?? '',
    );
  }

  @override
  String toString() {
    return '''TranscriptionResult {
  status: $status,
  failType: $failType,
  orderResult: $orderResult
}''';
  }
}
