import 'package:flutter/material.dart';
import '../../models/achievement_model.dart';
import '../../models/user_achievement_model.dart';
import '../../services/achievements_service.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  List<AchievementModel> _allAchievements = [];
  List<UserAchievementModel> _userAchievements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return;

      final all = await AchievementsService.getAllAchievements();
      final userAchievements = await AchievementsService.getUserAchievements(user.id);
      
      setState(() {
        _allAchievements = all;
        _userAchievements = userAchievements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isUnlocked(String achievementId) {
    return _userAchievements.any((ua) => ua.achievementId == achievementId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _allAchievements.length,
              itemBuilder: (context, index) {
                final achievement = _allAchievements[index];
                final isUnlocked = _isUnlocked(achievement.id);
                
                return Card(
                  color: isUnlocked
                      ? AppTheme.successColor.withOpacity(0.1)
                      : AppTheme.borderColor.withOpacity(0.3),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isUnlocked
                          ? AppTheme.successColor
                          : AppTheme.textTertiary,
                      child: Icon(
                        isUnlocked ? Icons.emoji_events : Icons.lock,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      achievement.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isUnlocked
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (achievement.description != null)
                          Text(achievement.description!),
                        if (achievement.criteria != null)
                          Text(
                            'Criteria: ${achievement.criteria}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (achievement.pointsReward != null)
                          Text(
                            'Reward: ${achievement.pointsReward} points',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.primaryColor,
                                ),
                          ),
                      ],
                    ),
                    trailing: isUnlocked
                        ? const Icon(Icons.check_circle, color: AppTheme.successColor)
                        : const Icon(Icons.lock, color: AppTheme.textTertiary),
                  ),
                );
              },
            ),
    );
  }
}

