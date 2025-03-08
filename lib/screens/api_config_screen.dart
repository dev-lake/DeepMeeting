import 'package:flutter/material.dart';
import '../config/api_config.dart';

class APIConfigScreen extends StatefulWidget {
  const APIConfigScreen({super.key});

  @override
  State<APIConfigScreen> createState() => _APIConfigScreenState();
}

class _APIConfigScreenState extends State<APIConfigScreen> {
  final _formKey = GlobalKey<FormState>();

  final _xfSTTUrlController = TextEditingController(text: APIConfig.xfSTTUrl);
  final _xfAppIdController = TextEditingController(text: APIConfig.xfAppId);
  final _xfApiSecretController =
      TextEditingController(text: APIConfig.xfApiSecret);
  final _aiApiEndpointController =
      TextEditingController(text: APIConfig.aiApiEndpoint);
  final _aiModelNameController =
      TextEditingController(text: APIConfig.aiModelName);
  final _aiApiKeyController = TextEditingController(text: APIConfig.aiApiKey);

  @override
  void dispose() {
    _xfSTTUrlController.dispose();
    _xfAppIdController.dispose();
    _xfApiSecretController.dispose();
    _aiApiEndpointController.dispose();
    _aiModelNameController.dispose();
    _aiApiKeyController.dispose();
    super.dispose();
  }

  void _saveConfig() async {
    if (_formKey.currentState!.validate()) {
      await APIConfig.updateConfig(
        xfSTTUrl: _xfSTTUrlController.text,
        xfAppId: _xfAppIdController.text,
        xfApiSecret: _xfApiSecretController.text,
        aiApiEndpoint: _aiApiEndpointController.text,
        aiModelName: _aiModelNameController.text,
        aiApiKey: _aiApiKeyController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('配置已保存')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API 配置'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Text('讯飞语音识别配置',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _xfSTTUrlController,
              decoration: const InputDecoration(labelText: 'API URL'),
              validator: (value) =>
                  value?.isEmpty ?? true ? '请输入API URL' : null,
            ),
            TextFormField(
              controller: _xfAppIdController,
              decoration: const InputDecoration(labelText: 'App ID'),
              validator: (value) => value?.isEmpty ?? true ? '请输入App ID' : null,
            ),
            TextFormField(
              controller: _xfApiSecretController,
              decoration: const InputDecoration(labelText: 'API Secret'),
              validator: (value) =>
                  value?.isEmpty ?? true ? '请输入API Secret' : null,
            ),
            const SizedBox(height: 24),
            const Text('AI 模型配置',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _aiApiEndpointController,
              decoration: const InputDecoration(labelText: 'API Endpoint'),
              validator: (value) =>
                  value?.isEmpty ?? true ? '请输入API Endpoint' : null,
            ),
            TextFormField(
              controller: _aiModelNameController,
              decoration: const InputDecoration(labelText: '模型名称'),
              validator: (value) => value?.isEmpty ?? true ? '请输入模型名称' : null,
            ),
            TextFormField(
              controller: _aiApiKeyController,
              decoration: const InputDecoration(labelText: 'API Key'),
              validator: (value) =>
                  value?.isEmpty ?? true ? '请输入API Key' : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveConfig,
              child: const Text('保存配置'),
            ),
          ],
        ),
      ),
    );
  }
}
