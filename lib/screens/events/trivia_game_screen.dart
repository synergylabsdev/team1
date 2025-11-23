import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/event_model.dart';
import '../../services/trivia_service.dart';
import '../../utils/app_theme.dart';

class TriviaGameScreen extends StatefulWidget {
  final EventModel event;

  const TriviaGameScreen({
    super.key,
    required this.event,
  });

  @override
  State<TriviaGameScreen> createState() => _TriviaGameScreenState();
}

class _TriviaGameScreenState extends State<TriviaGameScreen> {
  List<TriviaQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  int? _selectedAnswer;
  bool _isAnswered = false;
  bool _isCorrect = false;
  int _timeRemaining = 30;
  Timer? _timer;
  int _totalPointsEarned = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final questions = await TriviaService.getEventTrivia(widget.event.id);
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
      if (questions.isNotEmpty) {
        _startTimer();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startTimer() {
    _timeRemaining = _questions[_currentQuestionIndex].timeLimitSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_timeRemaining > 0) {
          _timeRemaining--;
        } else {
          _handleTimeout();
          timer.cancel();
        }
      });
    });
  }

  void _handleTimeout() {
    if (_isAnswered) return;
    
    setState(() {
      _isAnswered = true;
      _isCorrect = false;
    });
    
    _timer?.cancel();
    _showResult(false);
  }

  Future<void> _selectAnswer(int index) async {
    if (_isAnswered) return;
    
    _timer?.cancel();
    setState(() {
      _selectedAnswer = index;
      _isAnswered = true;
    });

    final question = _questions[_currentQuestionIndex];
    final isCorrect = index == question.correctAnswerIndex;
    
    setState(() {
      _isCorrect = isCorrect;
    });

    if (isCorrect) {
      final success = await TriviaService.submitTriviaAnswer(
        questionId: question.id,
        selectedAnswerIndex: index,
        correctAnswerIndex: question.correctAnswerIndex,
        pointsReward: question.pointsReward,
      );
      
      if (success) {
        setState(() {
          _totalPointsEarned += question.pointsReward;
        });
      }
    }

    _showResult(isCorrect);
  }

  void _showResult(bool isCorrect) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(isCorrect ? 'Correct!' : 'Incorrect'),
        content: Text(
          isCorrect
              ? 'You earned ${_questions[_currentQuestionIndex].pointsReward} points!'
              : 'No points earned. Better luck next time!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _nextQuestion();
            },
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
        _isAnswered = false;
        _isCorrect = false;
      });
      _startTimer();
    } else {
      _showCompletion();
    }
  }

  void _showCompletion() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Trivia Complete!'),
        content: Text('You earned $_totalPointsEarned points total!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trivia')),
        body: const Center(
          child: Text('No trivia questions available for this event'),
        ),
      );
    }

    final question = _questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${_currentQuestionIndex + 1}/${_questions.length}'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                '$_timeRemaining',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.warningColor,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _questions.length,
              backgroundColor: AppTheme.borderColor,
            ),
            
            const SizedBox(height: 24),
            
            // Question
            Text(
              question.question,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            
            const SizedBox(height: 32),
            
            // Answer options
            Expanded(
              child: ListView.builder(
                itemCount: question.options.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedAnswer == index;
                  final isCorrectAnswer = index == question.correctAnswerIndex;
                  
                  Color? backgroundColor;
                  if (_isAnswered) {
                    if (isCorrectAnswer) {
                      backgroundColor = AppTheme.successColor.withOpacity(0.2);
                    } else if (isSelected && !_isCorrect) {
                      backgroundColor = AppTheme.errorColor.withOpacity(0.2);
                    }
                  } else if (isSelected) {
                    backgroundColor = AppTheme.primaryColor.withOpacity(0.1);
                  }

                  return Card(
                    color: backgroundColor,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(question.options[index]),
                      trailing: _isAnswered && isCorrectAnswer
                          ? const Icon(Icons.check_circle, color: AppTheme.successColor)
                          : _isAnswered && isSelected && !_isCorrect
                              ? const Icon(Icons.cancel, color: AppTheme.errorColor)
                              : null,
                      onTap: () => _selectAnswer(index),
                      enabled: !_isAnswered,
                    ),
                  );
                },
              ),
            ),
            
            if (_isAnswered && !_isCorrect)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Correct answer: ${question.options[question.correctAnswerIndex]}',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

