import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/widgets/generate_button.dart';
import 'package:image/widgets/prompt_input_card.dart';
import 'package:image/widgets/results_panel.dart';
import 'package:image/services/api_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _promptController = TextEditingController();
  bool _isGenerating = false;
  String result = "";
  bool _isSaving = false;
  late AnimationController _controller;
  late Animation<int> _dotCount;
  @override
  void dispose() {
    _promptController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onGenerate() async {
    final String prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description.')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isGenerating = true);
    try {
      final response = await ApiClient.postText(text: prompt);
      if (!mounted) return;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request submitted successfully.')),
        );
        final dynamic res = jsonDecode(response.body);
        if (res is Map<String, dynamic>) {
          if (res['error'] != null) {
            debugPrint('API error: ${res['error']}');
          } else {
            debugPrint('Response data: ${res['output']}');
            setState(() {
              result = res['output'];
            });
          }
        } else {
          debugPrint('Unexpected response: ${response.body}');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request failed: ${response.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Network error: $e')));
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<bool> _ensureSavePermission() async {
    try {
      if (Platform.isIOS) {
        final status = await Permission.photosAddOnly.request();
        return status.isGranted;
      }
      // Android: storage permission for SDK < 33; for >=33 saving via MediaStore generally works without permission
      final status = await Permission.storage.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  Future<void> _onSaveImage() async {
    if (result.isEmpty || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      final hasPermission = await _ensureSavePermission();
      if (!hasPermission && Platform.isIOS) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo permission is required to save.'),
            ),
          );
        }
        return;
      }

      final uri = Uri.tryParse(result);
      if (uri == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Invalid image URL.')));
        }
        return;
      }

      final http.Response resp = await http.get(uri);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final Uint8List bytes = resp.bodyBytes;
        final String name = 'ai_image_${DateTime.now().millisecondsSinceEpoch}';
        final dynamic saveResult = await ImageGallerySaverPlus.saveImage(
          bytes,
          name: name,
        );
        bool success = false;
        if (saveResult is Map) {
          success =
              saveResult['isSuccess'] == true || saveResult['isSuccess'] == 1;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success ? 'Saved to gallery.' : 'Failed to save image.',
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Download failed: ${resp.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String getDots(int count) => '.' * count;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    )..repeat();
    _dotCount = IntTween(begin: 0, end: 3).animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "AI Image Creator",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1F1147),
                    Color(0xFF4B2FB5),
                    Color(0xFF00B3FF),
                    Color(0xFF0090FF),
                  ],
                  stops: [0.0, 0.5, 0.82, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (result.isEmpty) ...[
                    PromptInputCard(
                      controller: _promptController,
                      actionButton: GenerateButton(
                        isGenerating: _isGenerating,
                        onPressed: _onGenerate,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_isGenerating) ...[
                    const SizedBox(height: 25.0),
                    Center(
                      child: AnimatedBuilder(
                        animation: _dotCount,
                        builder: (context, child) {
                          return Text(
                            'Your image is processing\n Please wait${getDots(_dotCount.value)}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  if (result.isNotEmpty) ...[
                    Text(
                      'AI Generated Image:',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ResultsPanel(
                      child: Image.network(result, fit: BoxFit.contain),
                    ),
                    const SizedBox(height: 25.0),
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color.fromARGB(255, 127, 94, 219),
                              Color(0xFF4B2FB5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(5),
                          border: BoxBorder.all(color: Colors.white),
                        ),
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _onSaveImage,
                          style: ElevatedButton.styleFrom(
                            // padding: const EdgeInsets.all(5),
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            surfaceTintColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            elevation: 5,
                          ),
                          child: Text(
                            _isSaving ? "Saving..." : "Save this Image",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30.0),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            result = "";
                            _promptController.text = "";
                          });
                        },

                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                            Colors.redAccent,
                          ),
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                        child: const Text(
                          "Go Back",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
