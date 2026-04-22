import 'package:flutter/foundation.dart';
import '../models/question.dart';
import '../models/subject.dart';
import '../database/question_dao.dart';

class PracticeService extends ChangeNotifier {
  final QuestionDao _dao = QuestionDao();

  List<Question> _currentQuestions = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _sessionActive = false;

  List<Question> get currentQuestions => _currentQuestions;
  int get currentIndex => _currentIndex;
  int get score => _score;
  bool get sessionActive => _sessionActive;
  Question? get currentQuestion =>
      _currentIndex < _currentQuestions.length ? _currentQuestions[_currentIndex] : null;

  Future<void> startSession({
    required Subject subject,
    required int grade,
    String? chapter,
    Difficulty? difficulty,
    int count = 10,
  }) async {
    _currentQuestions = await _dao.getRandom(
      subject: subject,
      grade: grade,
      chapter: chapter,
      difficulty: difficulty,
      limit: count,
    );
    _currentIndex = 0;
    _score = 0;
    _sessionActive = true;
    notifyListeners();
  }

  Future<bool> submitAnswer(String answer) async {
    final q = currentQuestion;
    if (q == null) return false;
    final correct = answer.trim().toLowerCase() == q.answer.trim().toLowerCase();
    if (correct) _score++;
    await _dao.insertRecord(PracticeRecord(
      questionId: q.id!,
      userAnswer: answer,
      isCorrect: correct,
      practicedAt: DateTime.now(),
    ));
    notifyListeners();
    return correct;
  }

  void nextQuestion() {
    if (_currentIndex < _currentQuestions.length - 1) {
      _currentIndex++;
      notifyListeners();
    } else {
      _sessionActive = false;
      notifyListeners();
    }
  }

  Future<void> startWrongQuestionSession(int count) async {
    _currentQuestions = await _dao.getWrongQuestions(count);
    _currentIndex = 0;
    _score = 0;
    _sessionActive = true;
    notifyListeners();
  }
}
