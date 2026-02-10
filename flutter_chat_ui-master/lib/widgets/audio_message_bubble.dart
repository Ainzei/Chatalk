import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioMessageBubble extends StatefulWidget {
  final String url;
  final bool isMe;
  final int? durationMs;

  const AudioMessageBubble({
    Key? key,
    required this.url,
    required this.isMe,
    this.durationMs,
  }) : super(key: key);

  @override
  State<AudioMessageBubble> createState() => _AudioMessageBubbleState();
}

class _AudioMessageBubbleState extends State<AudioMessageBubble> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
      return;
    }
    await _player.play(UrlSource(widget.url));
    setState(() => _isPlaying = true);
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.durationMs != null
        ? Duration(milliseconds: widget.durationMs!)
        : null;
    final timeLabel = duration == null
        ? 'Voice message'
        : '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: widget.isMe ? const Color(0xFFF57C00) : const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
            color: widget.isMe ? Colors.white : Colors.black87,
            onPressed: _toggle,
          ),
          const SizedBox(width: 4),
          Text(
            timeLabel,
            style: TextStyle(
              color: widget.isMe ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
