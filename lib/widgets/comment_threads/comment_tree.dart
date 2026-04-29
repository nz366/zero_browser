import 'package:flutter/material.dart' show CircleAvatar;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:zero_browser/model/data.dart';

const double padding10 = 20.0;
const double avatarRadius = 20.0;
const double lineWeight = 2;

class CommentTree extends StatefulWidget {
  final Color color;
  final Color activeColor;
  final CommentData comment;

  final Widget Function(CommentData data) buildHeader;
  final Widget Function(CommentData data) buildBody;
  final Widget Function(CommentData parent, VoidCallback onUpdated) buildEnd;

  const CommentTree({
    super.key,
    required this.comment,
    required this.color,
    required this.activeColor,
    required this.buildHeader,
    required this.buildBody,
    required this.buildEnd,
  });

  @override
  State<CommentTree> createState() => _CommentTreeState();
}

class _CommentTreeState extends State<CommentTree> {
  @override
  Widget build(BuildContext context) {
    final lineActive = widget.comment.lineActive;
    return MouseRegion(
      onHover: (event) {
        if (event.localPosition.dx < (padding10 + padding10)) {
          if (!widget.comment.lineActive) {
            setState(() {
              widget.comment.lineActive = true;
            });
          }
        } else {
          if (widget.comment.lineActive) {
            setState(() {
              widget.comment.lineActive = false;
            });
          }
        }
      },
      onExit: (event) {
        setState(() {
          widget.comment.lineActive = false;
        });
      },
      child: GestureDetector(
        onTap: () {
          if (lineActive) {
            widget.comment.collapse();
            setState(() {});
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildHeader(widget.comment),
            Padding(
              padding: EdgeInsetsGeometry.only(left: padding10),
              child: CustomPaint(
                painter: widget.comment.replies.isEmpty
                    ? null
                    : StemPainter(
                        color: lineActive ? widget.activeColor : widget.color,
                      ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: padding10,
                        right: padding10,
                        bottom: padding10,
                        // horizontal: padding10,
                      ),
                      child: buildContent(widget.comment),
                    ),

                    if (widget.comment.replies.isNotEmpty &&
                        !widget.comment.collapsed)
                      Column(
                        children: widget.comment.replies.map((reply) {
                          return buildComment(
                            reply,
                            CommentTree(
                              comment: reply,
                              color: widget.color,
                              activeColor: widget.activeColor,
                              buildHeader: widget.buildHeader,
                              buildBody: widget.buildBody,
                              buildEnd: widget.buildEnd,
                            ),
                            lineActive ? widget.activeColor : widget.color,
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),

            if (widget.comment.replies.isNotEmpty)
              Padding(
                padding: EdgeInsetsGeometry.only(left: padding10),
                child: buildComment(
                  widget.comment,
                  widget.buildEnd(widget.comment, () {
                    setState(() {});
                  }),
                  lineActive ? widget.activeColor : widget.color,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildComment(CommentData reply, Widget child, Color color) {
    final path = BranchPath(avatarRadius: avatarRadius);
    return CustomPaint(
      painter: BranchPainter(path: path, lineColor: color),
      child: Padding(
        padding: EdgeInsetsGeometry.only(left: padding10),
        child: CustomPaint(child: child),
      ),
    );
  }
}

class BranchPath {
  final double avatarRadius;

  BranchPath({required this.avatarRadius});

  Path path() {
    final path = Path();

    path.moveTo(0, avatarRadius - avatarRadius);
    path.quadraticBezierTo(0, avatarRadius, avatarRadius, avatarRadius);
    return path;
  }
}

class BranchPainter extends CustomPainter {
  final Color lineColor;
  final BranchPath path;

  BranchPainter({this.lineColor = Colors.gray, required this.path});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWeight
      ..style = PaintingStyle.stroke;

    final path = this.path.path();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant BranchPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor;
  }
}

class StemPainter extends CustomPainter {
  final Color color;

  StemPainter({super.repaint, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    // Paint to draw the border
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle
          .stroke // Stroke style
      ..strokeWidth = lineWeight; // Border width

    canvas.drawLine(Offset(0, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false; // No need to repaint unless the widget changes.
  }
}

Padding buildEnd(CommentData parent, VoidCallback onUpdated) {
  return Padding(
    padding: EdgeInsetsGeometry.only(bottom: padding10),

    child: TextButton(
      onPressed: () {
        parent.collapse();
        onUpdated();
      },
      child: Text(parent.collapsed ? "More" : "Less"),
    ),
  );
}

Column buildContent(CommentData data) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [Text(data.content, style: const TextStyle(fontSize: 14))],
  );
}

Row buildHeader(CommentData data) {
  return Row(
    children: [
      CircleAvatar(
        radius: padding10,
        backgroundColor: Colors.gray,
        child: Text(
          data.author[0],
          style: const TextStyle(fontSize: 9, color: Colors.white),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        data.author,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Colors.gray,
        ),
      ),
      const SizedBox(width: 4),
      if (data.score != null)
        Text(
          "• ${data.score} pts",
          style: const TextStyle(fontSize: 11, color: Colors.gray),
        ),
      const SizedBox(width: 4),
      if (data.createdAt != null)
        Text(
          "• ${calculateTimeAgo(data.createdAt!)}",
          style: const TextStyle(fontSize: 11, color: Colors.gray),
        ),
    ],
  );
}

String calculateTimeAgo(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);
  if (difference.inMinutes < 60) return "${difference.inMinutes}m";
  if (difference.inHours < 24) return "${difference.inHours}h";
  return "${difference.inDays}d";
}
