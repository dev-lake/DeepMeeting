import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class WhisperAsrService {
  Future<String> convertAudioToText(String audioPath) async {
    final File audioFile = File(audioPath);
    if (!await audioFile.exists()) {
      throw Exception("Audio file not found at path: $audioPath");
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${APIConfig.whisperAsrEndpoint}/asr'),
    );

    // Add API Key to headers if it's available
    if (APIConfig.whisperAsrApiKey.isNotEmpty) {
      request.headers['X-API-Key'] = APIConfig.whisperAsrApiKey;
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        'audio_file',
        audioPath,
      ),
    );

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final decodedResponse = jsonDecode(responseBody);
        if (decodedResponse is Map && decodedResponse.containsKey('text')) {
          return decodedResponse['text'] as String;
        } else {
          throw Exception(
              "Failed to parse ASR response: 'text' field not found or invalid format. Response: $responseBody");
        }
      } else {
        final errorBody = await response.stream.bytesToString();
        throw Exception(
            "ASR service request failed with status ${response.statusCode}: $errorBody");
      }
    } on http.ClientException catch (e) {
      throw Exception("Network error during ASR request: $e");
    } catch (e) {
      throw Exception("An unexpected error occurred: $e");
    }
  }
}
