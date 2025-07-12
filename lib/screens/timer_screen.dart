import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  int _hours = 0;
  int _minutes = 0;
  int _seconds = 0;
  int _totalMilliseconds = 0; // Temps restant actuel
  int _setTime = 0; // Temps total initialement défini

  bool _isRunning = false;
  Timer? _timer; // Garde une référence au Timer

  final TextEditingController _hoursController = TextEditingController();
  final TextEditingController _minutesController = TextEditingController();
  final TextEditingController _secondsController = TextEditingController();

  @override
  void dispose() {
    _timer?.cancel(); // Annule le timer si le widget est supprimé
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  // Méthode unique pour mettre à jour _setTime et _totalSeconds
  void _updateSetAndTotalSeconds() {
    // Met à jour les heures, minutes et secondes à partir des contrôleurs
    if (_hoursController.text.isNotEmpty) {
      _hours = int.tryParse(_hoursController.text) ?? 0;
      _hoursController.text = _hours.toString().padLeft(2, '0');
    }

    if (_minutesController.text.isNotEmpty) {
      _minutes = int.tryParse(_minutesController.text) ?? 0;
      _minutes = _minutes.clamp(0, 59);
      _minutesController.text = _minutes.toString().padLeft(2, '0');
    }

    if (_secondsController.text.isNotEmpty) {
      _seconds = int.tryParse(_secondsController.text) ?? 0;
      _seconds = _seconds.clamp(0, 59);
      _secondsController.text = _seconds.toString().padLeft(2, '0');
    }

    if (!_isRunning && _hoursController.text.isNotEmpty ||
        _minutesController.text.isNotEmpty ||
        _secondsController.text.isNotEmpty) {
      final int h = int.tryParse(_hoursController.text) ?? 0;
      final int m = int.tryParse(_minutesController.text) ?? 0;
      final int s = int.tryParse(_secondsController.text) ?? 0;

      _setTime = (h * 3600 + m * 60 + s) * 1000;
      _totalMilliseconds = _setTime;
    }
  }

  // Méthode pour construire un TextField d'entrée de temps réutilisable
  Widget _buildTimeInputField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return Flexible(
      child: Focus(
        onFocusChange: (hasFocus) {
          if (!hasFocus) {
            setState(() => _updateSetAndTotalSeconds());
          }
        },
        child: TextField(
          enabled: !_isRunning,
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ),
    );
  }

  void _playSound() async {
    await _audioPlayer.setSource(AssetSource('sounds/birds.wav'));
    await _audioPlayer.resume();
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        _totalMilliseconds > 0 ? _totalMilliseconds / _setTime : 0.0;

    final hue = progress * 120;
    final saturation = .7;
    final lightness = .6;
    final hslColor = HSLColor.fromAHSL(1.0, hue, saturation, lightness);

    return Scaffold(
      appBar: AppBar(title: const Text('Minuteur Visuel')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 30.0,
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.light
                              ? Colors.grey[300]
                              : Colors.grey[700],
                      color: hslColor.toColor(),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '${_hours.toString().padLeft(2, '0')}:'
                    '${_minutes.toString().padLeft(2, '0')}:'
                    '${_seconds.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontFamily: 'Monospace',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _isRunning ? _stopTimer : _startTimer,
              child: Text(
                _isRunning ? 'Arrêter le Minuteur' : 'Démarrer le Minuteur',
              ),
            ),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              child: const Divider(
                color: Colors.black26,
                height: 20,
                thickness: 1,
              ),
            ),
            const SizedBox(height: 20),
            ..._buildTimeInput(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTimeInput() {
    return <Widget>[
      const Text(
        'Set Countdown',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTimeInputField(controller: _hoursController, hintText: 'HH'),
          const SizedBox(width: 10),
          const Flexible(child: Text(':')),
          const SizedBox(width: 10),
          _buildTimeInputField(controller: _minutesController, hintText: 'MM'),
          const SizedBox(width: 10),
          const Flexible(child: Text(':')),
          const SizedBox(width: 10),
          _buildTimeInputField(controller: _secondsController, hintText: 'SS'),
        ],
      ),
    ];
  }

  void _startTimer() {
    _updateSetAndTotalSeconds();

    if (_isRunning || _setTime <= 0) {
      return; // Ne démarre pas si déjà en cours ou temps non défini/zéro
    }

    WakelockPlus.enable();

    _hoursController.clear();
    _minutesController.clear();
    _secondsController.clear();

    setState(() {
      _isRunning = true;
    });

    final timePeriod = 10;

    _timer = Timer.periodic(Duration(milliseconds: timePeriod), (timer) {
      if (_totalMilliseconds > 0) {
        setState(() {
          _totalMilliseconds -= timePeriod;
          _hours = (_totalMilliseconds ~/ 3600000) % 24;
          _minutes = (_totalMilliseconds ~/ 60000) % 60;
          _seconds = (_totalMilliseconds ~/ 1000) % 60;
        });
      } else {
        _playSound();
        _setTime = 0;
        _stopTimer();
      }
    });
  }

  // Ajout de la méthode _stopTimer pour pouvoir arrêter le compte à rebours
  void _stopTimer() {
    WakelockPlus.disable();
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }
}
