import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_utils.dart';
import '../../data/models/quiz_model.dart';
import '../../services/quiz_service.dart';

class QuizPlayScreen extends StatefulWidget {
  final QuizSession session;

  const QuizPlayScreen({
    super.key,
    required this.session,
  });

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  final QuizService _quizService = QuizService();
  late QuizSession _currentSession;
  int _currentQuestionIndex = 0;
  String _userAnswer = '';
  bool _showResult = false;
  bool _isAnswered = false;

  @override
  void initState() {
    super.initState();
    _currentSession = widget.session;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentSession.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Quiz'),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('No questions available'),
        ),
      );
    }

    final currentQuestion = _currentSession.questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _currentSession.questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz ${_currentQuestionIndex + 1}/${_currentSession.questions.length}'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question ${_currentQuestionIndex + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentQuestion.question,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (currentQuestion.hint != null && !_isAnswered)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.warningColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.lightbulb, 
                                   color: AppColors.warningColor, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Hint: ${currentQuestion.hint}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.warningColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Answer Options
            Expanded(
              child: _buildAnswerSection(currentQuestion),
            ),

            // Action Buttons
            Row(
              children: [
                if (_currentQuestionIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousQuestion,
                      child: const Text('Previous'),
                    ),
                  ),
                if (_currentQuestionIndex > 0) const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isAnswered ? _nextQuestion : _submitAnswer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isAnswered 
                          ? AppColors.primaryColor 
                          : AppColors.successColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_isAnswered 
                        ? (_currentQuestionIndex < _currentSession.questions.length - 1 
                           ? 'Next' : 'Finish')
                        : 'Submit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerSection(QuizQuestion question) {
    if (question.type == QuizType.multipleChoice) {
      return _buildMultipleChoice(question);
    } else {
      return _buildTextInput(question);
    }
  }

  Widget _buildMultipleChoice(QuizQuestion question) {
    return ListView.builder(
      itemCount: question.options.length,
      itemBuilder: (context, index) {
        final option = question.options[index];
        final isSelected = _userAnswer == option;
        final isCorrect = option == question.correctAnswer;
        
        Color? backgroundColor;
        Color? textColor;
        
        if (_showResult) {
          if (isCorrect) {
            backgroundColor = AppColors.successColor.withOpacity(0.2);
            textColor = AppColors.successColor;
          } else if (isSelected && !isCorrect) {
            backgroundColor = AppColors.errorColor.withOpacity(0.2);
            textColor = AppColors.errorColor;
          }
        } else if (isSelected) {
          backgroundColor = AppColors.primaryColor.withOpacity(0.2);
          textColor = AppColors.primaryColor;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: _isAnswered ? null : () => _selectAnswer(option),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border.all(
                  color: textColor ?? Colors.grey.withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: textColor?.withOpacity(0.2),
                      border: Border.all(
                        color: textColor ?? Colors.grey,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + index), // A, B, C, D
                        style: TextStyle(
                          color: textColor ?? Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: isSelected ? FontWeight.bold : null,
                      ),
                    ),
                  ),
                  if (_showResult && isCorrect)
                    Icon(Icons.check_circle, color: AppColors.successColor),
                  if (_showResult && isSelected && !isCorrect)
                    Icon(Icons.cancel, color: AppColors.errorColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextInput(QuizQuestion question) {
    return Column(
      children: [
        TextField(
          enabled: !_isAnswered,
          onChanged: (value) => _userAnswer = value,
          decoration: InputDecoration(
            labelText: 'Your answer',
            border: const OutlineInputBorder(),
            suffixIcon: _showResult
                ? Icon(
                    _userAnswer.toLowerCase().trim() == 
                    question.correctAnswer.toLowerCase().trim()
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: _userAnswer.toLowerCase().trim() == 
                           question.correctAnswer.toLowerCase().trim()
                        ? AppColors.successColor
                        : AppColors.errorColor,
                  )
                : null,
          ),
        ),
        if (_showResult) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb, color: AppColors.successColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Correct answer: ${question.correctAnswer}',
                    style: TextStyle(
                      color: AppColors.successColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _selectAnswer(String answer) {
    if (!_isAnswered) {
      setState(() {
        _userAnswer = answer;
      });
    }
  }

  void _submitAnswer() {
    if (_userAnswer.isEmpty) {
      AppUtils.showSnackBar(context, 'Please select an answer', isError: true);
      return;
    }

    setState(() {
      _isAnswered = true;
      _showResult = true;
    });

    // Simulate saving result
    final result = QuizResult(
      questionId: _currentSession.questions[_currentQuestionIndex].id,
      userAnswer: _userAnswer,
      correctAnswer: _currentSession.questions[_currentQuestionIndex].correctAnswer,
      isCorrect: _checkAnswer(),
      timeSpent: 30, // Placeholder
      answeredAt: DateTime.now(),
    );

    // Update session (simplified)
    _currentSession = QuizSession(
      id: _currentSession.id,
      questions: _currentSession.questions,
      results: [..._currentSession.results, result],
      startTime: _currentSession.startTime,
      endTime: _currentSession.endTime,
      mode: _currentSession.mode,
      difficulty: _currentSession.difficulty,
      totalQuestions: _currentSession.totalQuestions,
      correctAnswers: _currentSession.correctAnswers + (result.isCorrect ? 1 : 0),
      totalTimeSpent: _currentSession.totalTimeSpent + result.timeSpent,
      accuracy: (_currentSession.correctAnswers + (result.isCorrect ? 1 : 0)) / 
                (_currentSession.results.length + 1),
    );
  }

  bool _checkAnswer() {
    final currentQuestion = _currentSession.questions[_currentQuestionIndex];
    final correctAnswer = currentQuestion.correctAnswer.toLowerCase().trim();
    final userAnswerLower = _userAnswer.toLowerCase().trim();
    
    return correctAnswer == userAnswerLower || 
           correctAnswer.contains(userAnswerLower) ||
           userAnswerLower.contains(correctAnswer);
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _currentSession.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _userAnswer = '';
        _showResult = false;
        _isAnswered = false;
      });
    } else {
      _finishQuiz();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _userAnswer = '';
        _showResult = false;
        _isAnswered = false;
      });
    }
  }

  void _finishQuiz() {
    // Save quiz session
    _quizService.saveQuizSession(_currentSession);
    
    // Show results
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Quiz Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Score: ${_currentSession.correctAnswers}/${_currentSession.totalQuestions}'),
            Text('Accuracy: ${(_currentSession.accuracy * 100).toStringAsFixed(1)}%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to quiz screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
