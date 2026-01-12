// widgets/simple_audio_player_widget.dart
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class SimpleAudioPlayerWidget extends StatefulWidget {
  final String audioUrl;

  const SimpleAudioPlayerWidget({Key? key, required this.audioUrl}) : super(key: key);

  @override
  _SimpleAudioPlayerWidgetState createState() => _SimpleAudioPlayerWidgetState();
}

class _SimpleAudioPlayerWidgetState extends State<SimpleAudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _testAudioSource();
  }

  Future<void> _testAudioSource() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('Тестирование аудио источника: ${widget.audioUrl}');

      if (widget.audioUrl.startsWith('http')) {
        // Интернет-аудио
        await _audioPlayer.setSourceUrl(widget.audioUrl);
      } else if (widget.audioUrl.startsWith('assets/')) {
        // Локальный asset
        final assetPath = widget.audioUrl.replaceFirst('assets/', '');
        await _audioPlayer.setSource(AssetSource(assetPath));
      }

      // Просто проверяем, что источник установлен
      await _audioPlayer.getDuration();

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      print('Ошибка тестирования аудио: $e');
      setState(() {
        _isLoading = false;
        _error = 'Этот аудиофайл недоступен: ${e.toString().split('\n').first}';
      });
    }
  }

  Future<void> _togglePlay() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        setState(() {
          _isPlaying = false;
        });
      } else {
        await _audioPlayer.resume();
        setState(() {
          _isPlaying = true;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Ошибка воспроизведения: ${e.toString()}';
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.audiotrack, color: Colors.blue, size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Аудио файл',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    Text(
                      widget.audioUrl,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          if (_isLoading) ...[
            Center(child: CircularProgressIndicator()),
          ] else if (_error != null) ...[
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.orange[800], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    size: 40,
                    color: Colors.blue,
                  ),
                  onPressed: _togglePlay,
                ),
                SizedBox(width: 16),
                Text(
                  _isPlaying ? 'Воспроизведение...' : 'Нажмите для воспроизведения',
                  style: TextStyle(color: Colors.blue[700]),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}