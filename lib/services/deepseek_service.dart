import 'package:deepseek_api/deepseek_api.dart';
import '../config/api_config.dart';

class DeepseekService {
  late final DeepSeekAPI _api;

  DeepseekService() {
    _api = DeepSeekAPI(
      baseUrl: APIConfig.aiApiEndpoint,
      apiKey: APIConfig.aiApiKey,
    );
  }

  Future<String> generate(String text) async {
    try {
      final completion = await _api.createChatCompletion(
        ChatCompletionRequest(
          model: APIConfig.aiModelName,
          messages: [
            ChatMessage(
              role: 'system',
              content: '扮演一个自身的会议秘书，把用户给你的信息整理成一份格式工整、调理清晰的会议纪要。',
            ),
            ChatMessage(
              role: 'user',
              content: text,
            )
          ],
          // temperature: 0.7,
          // maxTokens: 1000,
        ),
      );

      return completion.choices.first.message.content;
    } catch (e) {
      throw Exception('生成摘要时发生错误: $e');
    }
  }
}
