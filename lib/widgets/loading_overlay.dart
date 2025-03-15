import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingOverlay {
  static OverlayEntry? _overlayEntry;
  static bool _isVisible = false;

  static void show(
    BuildContext context, {
    required String status,
    required double progress,
  }) {
    if (_isVisible) {
      // 更新现有的覆盖层
      _overlayEntry?.remove();
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => LoadingOverlayWidget(
        status: status,
        progress: progress,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _isVisible = true;
  }

  static void hide() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _isVisible = false;
    }
  }
}

class LoadingOverlayWidget extends StatefulWidget {
  final String status;
  final double progress;

  const LoadingOverlayWidget({
    Key? key,
    required this.status,
    required this.progress,
  }) : super(key: key);

  @override
  State<LoadingOverlayWidget> createState() => _LoadingOverlayWidgetState();
}

class _LoadingOverlayWidgetState extends State<LoadingOverlayWidget> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // SizedBox(
                        //   height: 100,
                        //   width: 100,
                        //   child: Lottie.asset(
                        //     'assets/animations/loading.json',
                        //     fit: BoxFit.contain,
                        //   ),
                        // ),
                        // if (widget.progress < 1.0)
                        //   Column(
                        //     children: [
                        //       const SizedBox(height: 8),
                        //       Text(
                        //         '正在努力处理中...',
                        //         style: TextStyle(
                        //           fontSize: 14,
                        //           color: Colors.grey[600],
                        //         ),
                        //       ),
                        //       const SizedBox(height: 16),
                        //     ],
                        //   ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            widget.status,
                            key: ValueKey<String>(widget.status),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: widget.progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
