import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DataTab extends StatelessWidget {
  final dynamic jsonObj;

  const DataTab({super.key, required this.jsonObj});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: SingleChildScrollView(
        child: JsonNode(node: jsonObj, name: 'root', isRoot: true),
      ),
    );
  }
}

class JsonNode extends StatefulWidget {
  final dynamic node;
  final String name;
  final bool isRoot;
  final bool isLast;

  const JsonNode({
    Key? key,
    required this.node,
    required this.name,
    this.isRoot = false,
    this.isLast = true,
  }) : super(key: key);

  @override
  State<JsonNode> createState() => _JsonNodeState();
}

class _JsonNodeState extends State<JsonNode> {
  late bool isExpanded;

  @override
  void initState() {
    super.initState();
    isExpanded = widget.isRoot;
  }

  void _toggleExpanded() {
    setState(() {
      isExpanded = !isExpanded;
    });
  }

  void _copyNodeData(BuildContext context) {
    final String textToCopy;

    if (widget.node is Map || widget.node is List) {
      textToCopy = const JsonEncoder.withIndent('  ').convert(widget.node);
    } else if (widget.node is String) {
      textToCopy = widget.node;
    } else {
      textToCopy = '${widget.node}';
    }

    Clipboard.setData(ClipboardData(text: textToCopy));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied data for "${widget.name}"'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _getValueColor(dynamic value) {
    if (value is String) return Colors.green[700]!;
    if (value is num) return Colors.blue[700]!;
    if (value is bool) return Colors.orange[700]!;
    if (value == null) return Colors.grey;
    return Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    final isComplex = widget.node is Map || widget.node is List;

    if (!isComplex) {
      return Padding(
        padding: const EdgeInsets.only(left: 24.0, top: 4, bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.isRoot)
              Text(
                '"${widget.name}": ',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.purple,
                ),
              ),
            Flexible(
              child: Text(
                widget.node is String ? '"${widget.node}"' : '${widget.node}',
                style: TextStyle(color: _getValueColor(widget.node)),
              ),
            ),
            if (!widget.isLast) const Text(','),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _copyNodeData(context),
              child: const Icon(Icons.copy, size: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final isMap = widget.node is Map;
    final startChar = isMap ? '{' : '[';
    final endChar = isMap ? '}' : ']';
    final childrenCount = isMap
        ? (widget.node as Map).length
        : (widget.node as List).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: childrenCount > 0 ? _toggleExpanded : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (childrenCount > 0)
                    Icon(
                      isExpanded ? Icons.arrow_drop_down : Icons.arrow_right,
                      size: 24,
                      color: Colors.grey[600],
                    )
                  else
                    const SizedBox(width: 24),
                  if (!widget.isRoot)
                    Text(
                      '"${widget.name}": ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.purple,
                      ),
                    ),
                  Text(startChar),
                  if (!isExpanded && childrenCount > 0) ...[
                    const Text(' ... '),
                    Text('$endChar${widget.isLast ? '' : ','}'),
                    Text(
                      ' // $childrenCount items',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (!widget.isRoot)
              InkWell(
                onTap: () => _copyNodeData(context),
                child: const Icon(Icons.copy, size: 14, color: Colors.grey),
              ),
          ],
        ),

        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isMap)
                  ...((widget.node as Map).entries.toList().asMap().entries.map(
                    (entry) {
                      final index = entry.key;
                      final mapEntry = entry.value;
                      return JsonNode(
                        node: mapEntry.value,
                        name: mapEntry.key.toString(),
                        isLast: index == childrenCount - 1,
                      );
                    },
                  ))
                else
                  ...((widget.node as List).asMap().entries.map((entry) {
                    final index = entry.key;
                    final listValue = entry.value;
                    return JsonNode(
                      node: listValue,
                      name: index.toString(),
                      isLast: index == childrenCount - 1,
                    );
                  })),
              ],
            ),
          ),

        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 24.0),
            child: Text('$endChar${widget.isLast ? '' : ','}'),
          ),
      ],
    );
  }
}
