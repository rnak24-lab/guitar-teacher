import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/note.dart';
import '../../models/octave_form.dart';
import '../../services/app_localizations.dart';
import 'form_info_dialog.dart';

class OctaveGame extends StatefulWidget {
  final List<int> selectedForms;
  final int seconds;
  final String selectedNote;

  const OctaveGame({
    super.key,
    required this.selectedForms,
    required this.seconds,
    required this.selectedNote,
  });

  @override
  State<OctaveGame> createState() => _OctaveGameState();
}

class _OctaveGameState extends State<OctaveGame> {
  final _random = Random();
  late int _currentFormIndex;
  late String _currentNote;
  Timer? _timer;
  int _timeLeft = 0;

  @override
  void initState() {
    super.initState();
    _nextQuestion();
  }

  void _nextQuestion() {
    _currentFormIndex = widget.selectedForms[_random.nextInt(widget.selectedForms.length)];
    _currentNote = widget.selectedNote == 'random'
        ? Note.allNotes[_random.nextInt(12)]
        : widget.selectedNote;
    _timeLeft = widget.seconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) _nextQuestion();
      });
    });
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final form = OctaveForm.allForms[_currentFormIndex - 1];

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('octave_game_title')),
        leading: IconButton(
          icon: const Icon(Icons.help_outline),
          onPressed: () => showDialog(
            context: context,
            builder: (_) => const FormInfoDialog(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.skip_next),
            onPressed: _nextQuestion,
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: _timeLeft / widget.seconds,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation(Colors.orange),
            minHeight: 8,
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    tr('octave_form_n').replaceAll('{n}', '$_currentFormIndex'),
                    style: const TextStyle(fontSize: 24, color: Colors.grey),
                  ),
                  Text(
                    form.cagedName,
                    style: TextStyle(fontSize: 18, color: Colors.orange[700]),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _currentNote,
                    style: const TextStyle(
                      fontSize: 96,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$_timeLeft초',
                    style: TextStyle(
                      fontSize: 32,
                      color: _timeLeft > 3 ? Colors.grey : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        form.description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 50,
            width: double.infinity,
            color: Colors.grey[200],
            child: const Center(child: Text('AD BANNER', style: TextStyle(color: Colors.grey, fontSize: 11))),
          ),
        ],
      ),
    );
  }
}
