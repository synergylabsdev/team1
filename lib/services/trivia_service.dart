import 'supabase_service.dart';

class TriviaQuestion {
  final String id;
  final String eventId;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final int pointsReward;
  final int timeLimitSeconds;

  TriviaQuestion({
    required this.id,
    required this.eventId,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    this.pointsReward = 5,
    this.timeLimitSeconds = 30,
  });

  factory TriviaQuestion.fromJson(Map<String, dynamic> json) {
    return TriviaQuestion(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      correctAnswerIndex: json['correct_answer_index'] as int,
      pointsReward: json['points_reward'] as int? ?? 5,
      timeLimitSeconds: json['time_limit_seconds'] as int? ?? 30,
    );
  }
}

class TriviaService {
  // Get trivia questions for an event
  static Future<List<TriviaQuestion>> getEventTrivia(String eventId) async {
    try {
      // For now, return mock data. In production, fetch from Supabase
      // You would create a 'trivia_questions' table
      return [
        TriviaQuestion(
          id: '1',
          eventId: eventId,
          question: 'What is the main ingredient in this product?',
          options: ['Option A', 'Option B', 'Option C', 'Option D'],
          correctAnswerIndex: 0,
          pointsReward: 5,
        ),
      ];
    } catch (e) {
      print('Error fetching trivia: $e');
      return [];
    }
  }

  // Submit trivia answer and award points
  static Future<bool> submitTriviaAnswer({
    required String questionId,
    required int selectedAnswerIndex,
    required int correctAnswerIndex,
    required int pointsReward,
  }) async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final isCorrect = selectedAnswerIndex == correctAnswerIndex;
      
      if (isCorrect) {
        // Award points
        final currentUser = await SupabaseService.getUserProfile(user.id);
        if (currentUser != null) {
          final newPoints = currentUser.points + pointsReward;
          await SupabaseService.client
              .from('users')
              .update({'points': newPoints})
              .eq('id', user.id);
        }
      }

      return isCorrect;
    } catch (e) {
      print('Error submitting trivia answer: $e');
      return false;
    }
  }
}

