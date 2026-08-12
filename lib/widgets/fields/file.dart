import 'dart:io';
import 'dart:math';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:zero_browser/model/data.dart' as forms;
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';

class FileUploadWidget extends StatefulWidget {
  final forms.FileField field;

  const FileUploadWidget({super.key, required this.field});

  @override
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget> {
  bool _isDragging = false;
  bool _isHovering = false;

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  String? _getFileSizeText(String? path) {
    if (path == null || path.isEmpty) return null;
    try {
      final file = File(path);
      if (file.existsSync()) {
        return _formatFileSize(file.lengthSync());
      }
    } catch (_) {}
    return null;
  }

  void _updateValue(String? newValue) {
    setState(() {
      widget.field.value = newValue;
    });
    final formFieldState = context
        .findAncestorStateOfType<FormFieldState<String>>();
    formFieldState?.didChange(newValue);
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles();
      if (result != null && result.files.single.path != null) {
        _updateValue(result.files.single.path);
      }
    } catch (e) {
      debugPrint("Error picking file: $e");
    }
  }

  void _clearFile() {
    _updateValue(null);
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.field.value;
    final hasFile = path != null && path.isNotEmpty;
    final fileName = hasFile ? path.split(Platform.pathSeparator).last : null;
    final fileSize = hasFile ? _getFileSizeText(path) : null;
    final theme = Theme.of(context);
    final isHighlighted = _isDragging || _isHovering;

    return DropTarget(
      onDragEntered: (details) => setState(() => _isDragging = true),
      onDragExited: (details) => setState(() => _isDragging = false),
      onDragDone: (details) async {
        setState(() => _isDragging = false);
        if (details.files.isNotEmpty) {
          final file = details.files.first;
          _updateValue(file.path);
        }
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _pickFile,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? theme.colorScheme.primary.withOpacity(0.05)
                  : theme.colorScheme.muted.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isHighlighted
                    ? theme.colorScheme.primary
                    : theme.colorScheme.border,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                if (!hasFile) ...[
                  Icon(
                    LucideIcons.upload,
                    size: 32,
                    color: isHighlighted
                        ? theme.colorScheme.primary
                        : theme.colorScheme.mutedForeground,
                  ),
                  Text(
                    "Drag & drop your file here",
                    style: theme.typography.medium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    "or click to browse",
                    style: theme.typography.medium.copyWith(
                      color: theme.colorScheme.mutedForeground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  Row(
                    children: [
                      Icon(
                        LucideIcons.file,
                        size: 24,
                        color: theme.colorScheme.primary,
                      ),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              fileName!,
                              style: theme.typography.base.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (fileSize != null) ...[
                              const Gap(2),
                              Text(
                                fileSize,
                                style: theme.typography.small.copyWith(
                                  color: theme.colorScheme.mutedForeground,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Gap(8),
                      IconButton.ghost(
                        icon: const Icon(LucideIcons.x, size: 16),
                        onPressed: _clearFile,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FileDownloadWidget extends StatelessWidget {
  final forms.MediaSection section;

  final void Function(forms.FileDataAbstract) onDownload;
  const FileDownloadWidget({
    super.key,
    required this.section,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final isHighlighted = false;
    final theme = Theme.of(context);

    final decoration = BoxDecoration(
      color: isHighlighted
          ? theme.colorScheme.primary.withOpacity(.05)
          : theme.colorScheme.muted.withOpacity(.2),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: isHighlighted
            ? theme.colorScheme.primary
            : theme.colorScheme.border,
      ),
    );
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      padding: EdgeInsets.all(20),
      decoration: decoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("Downloads", style: theme.typography.h3),
              Spacer(),
              SizedBox(
                width: 50,
                height: 50,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    IconButton.ghost(
                      icon: Icon(LucideIcons.download, size: 20),
                    ),
                    CircularProgressIndicator(value: 0, strokeWidth: 3),
                  ],
                ),
              ),
            ],
          ),

          Gap(20),

          Container(
            padding: EdgeInsets.all(20),
            constraints: BoxConstraints(minHeight: 50, maxHeight: 300),
            decoration: decoration,
            child: ListView.separated(
              shrinkWrap: true,
              separatorBuilder: (_, _) => Divider(),
              itemCount: section.items.length,
              itemBuilder: (context, index) {
                final item = section.items[index];

                return Row(
                  children: [
                    Icon(LucideIcons.file),
                    Text(item.name),
                    Spacer(),

                    IconButton.ghost(
                      icon: Icon(LucideIcons.download),
                      onPressed: () {
                        onDownload(item);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
