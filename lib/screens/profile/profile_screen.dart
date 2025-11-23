import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';
import '../../services/achievements_service.dart';
import 'profile_edit_screen.dart';
import '../achievements/achievements_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, int> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final user = SupabaseService.currentUser;
    if (user != null) {
      final stats = await AchievementsService.getUserStats(user.id);
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openBrandAmbassadorForm() async {
    const url = 'https://forms.example.com/brand-ambassador'; // Replace with actual URL
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open form. Please check the URL.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final authUser = SupabaseService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileEditScreen(),
                ),
              ).then((_) => _loadStats());
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Profile Picture & Username
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    backgroundImage: user?.profilePicture != null
                        ? NetworkImage(user!.profilePicture!)
                        : null,
                    child: user?.profilePicture == null
                        ? Icon(
                            Icons.person,
                            size: 60,
                            color: AppTheme.primaryColor,
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Username
                  Text(
                    '@${user?.username ?? authUser?.email?.split('@')[0] ?? 'user'}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.workspace_premium,
                          label: 'Points',
                          value: '${user?.points ?? 0}',
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.check_circle,
                          label: 'Check-ins',
                          value: '${_stats['checkIns'] ?? 0}',
                          color: AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.rate_review,
                          label: 'Reviews',
                          value: '${_stats['reviews'] ?? 0}',
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.emoji_events,
                          label: 'Achievements',
                          value: '${_stats['achievements'] ?? 0}',
                          color: AppTheme.warningColor,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Tier Status Card
                  Card(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.stars,
                            color: AppTheme.primaryColor,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tier Status',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                ),
                                Text(
                                  user?.tierStatus.value ?? 'Bronze',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Progress Tracker
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Progress to Next Tier',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          _buildTierProgress(user?.points ?? 0, user?.tierStatus ?? TierStatus.bronze),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Achievements Section
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.emoji_events, color: AppTheme.warningColor),
                      title: const Text('Achievements'),
                      subtitle: Text('${_stats['achievements'] ?? 0} unlocked'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AchievementsScreen(),
                          ),
                        ).then((_) => _loadStats());
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Brand Ambassador
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.business_center, color: AppTheme.primaryColor),
                      title: const Text('Apply as Brand Ambassador'),
                      subtitle: const Text('Join our ambassador program'),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: _openBrandAmbassadorForm,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // User Info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            context,
                            Icons.email,
                            'Email',
                            user?.email ?? authUser?.email ?? 'Not set',
                          ),
                          if (user?.phone != null) ...[
                            const Divider(),
                            _buildInfoRow(
                              context,
                              Icons.phone,
                              'Phone',
                              user!.phone!,
                            ),
                          ],
                          if (user?.dob != null) ...[
                            const Divider(),
                            _buildInfoRow(
                              context,
                              Icons.calendar_today,
                              'Date of Birth',
                              _formatDate(user!.dob!),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Edit Profile Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileEditScreen(),
                          ),
                        ).then((_) => _loadStats());
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Profile'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTierProgress(int points, TierStatus currentTier) {
    int nextTierPoints;
    String nextTierName;
    
    switch (currentTier) {
      case TierStatus.bronze:
        nextTierPoints = 100;
        nextTierName = 'Silver';
        break;
      case TierStatus.silver:
        nextTierPoints = 500;
        nextTierName = 'Gold';
        break;
      case TierStatus.gold:
        nextTierPoints = 1000;
        nextTierName = 'Platinum';
        break;
      case TierStatus.platinum:
        return const Text('You\'ve reached the highest tier!');
    }
    
    final progress = (points / nextTierPoints).clamp(0.0, 1.0);
    final pointsNeeded = nextTierPoints - points;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$points / $nextTierPoints points'),
            Text(
              '$pointsNeeded to $nextTierName',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppTheme.borderColor,
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
