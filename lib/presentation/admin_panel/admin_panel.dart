import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import './widgets/admin_stats_widget.dart';
import './widgets/content_validation_card.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({Key? key}) : super(key: key);

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late TabController _tabController;

  List<Map<String, dynamic>> _pendingChallenges = [];
  List<Map<String, dynamic>> _pendingQuotes = [];
  Map<String, dynamic>? _adminStats;

  final AuthService _authService = AuthService();
  final AdminService _adminService = AdminService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeServices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    try {
      await _authService.initialize();
      await _adminService.initialize();
      await _loadAdminData();
    } catch (e) {
      if (mounted) {
        _showBeautifulErrorMessage('Erreur lors de l\'initialisation: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAdminData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        Navigator.pushReplacementNamed(context, '/login-screen');
        return;
      }

      // Check if user is admin
      final isAdmin = await _adminService.isUserAdmin(currentUser.id);
      if (!isAdmin) {
        Navigator.pop(context);
        _showBeautifulErrorMessage('Accès non autorisé');
        return;
      }

      // Load pending content
      final challenges = await _adminService.getPendingChallenges();
      final quotes = await _adminService.getPendingQuotes();
      final stats = await _adminService.getAdminStats();

      if (mounted) {
        setState(() {
          _pendingChallenges = challenges;
          _pendingQuotes = quotes;
          _adminStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showBeautifulErrorMessage('Erreur lors du chargement des données: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Panneau Admin',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 6.w,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadAdminData,
            icon: CustomIconWidget(
              iconName: 'refresh',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 6.w,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.lightTheme.colorScheme.primary,
          labelColor: AppTheme.lightTheme.colorScheme.primary,
          unselectedLabelColor:
              AppTheme.lightTheme.colorScheme.onSurface.withAlpha(153),
          tabs: [
            Tab(text: 'Défis (${_pendingChallenges.length})'),
            Tab(text: 'Citations (${_pendingQuotes.length})'),
            Tab(text: 'Statistiques'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // Pending Challenges Tab
                _buildChallengesTab(),
                // Pending Quotes Tab
                _buildQuotesTab(),
                // Admin Stats Tab
                _buildStatsTab(),
              ],
            ),
    );
  }

  Widget _buildChallengesTab() {
    if (_pendingChallenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'task_alt',
              color: AppTheme.lightTheme.colorScheme.primary.withAlpha(128),
              size: 12.w,
            ),
            SizedBox(height: 2.h),
            Text(
              'Aucun défi en attente',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface.withAlpha(153),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Tous les défis ont été validés',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface.withAlpha(102),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _pendingChallenges.length,
      itemBuilder: (context, index) {
        final challenge = _pendingChallenges[index];
        return ContentValidationCard(
          id: challenge['id'],
          type: 'challenge',
          title: challenge['title'],
          content: challenge['description'],
          lifeDomain: challenge['life_domain'],
          createdAt: challenge['created_at'],
          onApprove: () =>
              _validateContent('challenge', challenge['id'], 'approved'),
          onReject: () => _showRejectDialog('challenge', challenge['id']),
        );
      },
    );
  }

  Widget _buildQuotesTab() {
    if (_pendingQuotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'format_quote',
              color: AppTheme.lightTheme.colorScheme.primary.withAlpha(128),
              size: 12.w,
            ),
            SizedBox(height: 2.h),
            Text(
              'Aucune citation en attente',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface.withAlpha(153),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Toutes les citations ont été validées',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface.withAlpha(102),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _pendingQuotes.length,
      itemBuilder: (context, index) {
        final quote = _pendingQuotes[index];
        return ContentValidationCard(
          id: quote['id'],
          type: 'quote',
          title: quote['author'],
          content: quote['quote_text'],
          lifeDomain: quote['life_domain'],
          createdAt: quote['created_at'],
          onApprove: () => _validateContent('quote', quote['id'], 'approved'),
          onReject: () => _showRejectDialog('quote', quote['id']),
        );
      },
    );
  }

  Widget _buildStatsTab() {
    if (_adminStats == null) {
      return Center(
        child: CircularProgressIndicator(
          color: AppTheme.lightTheme.colorScheme.primary,
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          AdminStatsWidget(
            title: 'Contenu en attente',
            stats: {
              'Défis': _adminStats!['pending_challenges'] ?? 0,
              'Citations': _adminStats!['pending_quotes'] ?? 0,
            },
          ),
          SizedBox(height: 3.h),
          AdminStatsWidget(
            title: 'Contenu validé',
            stats: {
              'Défis approuvés': _adminStats!['approved_challenges'] ?? 0,
              'Citations approuvées': _adminStats!['approved_quotes'] ?? 0,
              'Défis rejetés': _adminStats!['rejected_challenges'] ?? 0,
              'Citations rejetées': _adminStats!['rejected_quotes'] ?? 0,
            },
          ),
          SizedBox(height: 3.h),
          AdminStatsWidget(
            title: 'Activité générale',
            stats: {
              'Utilisateurs actifs': _adminStats!['active_users'] ?? 0,
              'Total défis': _adminStats!['total_challenges'] ?? 0,
              'Total citations': _adminStats!['total_quotes'] ?? 0,
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      crossAxisSpacing: 4.w,
      mainAxisSpacing: 2.h,
      children: [
        // Remove _buildQuickActionCard calls since method is not defined
        // ... existing code ...
      ],
    );
  }

  Future<void> _validateContent(
      String type, String contentId, String status) async {
    try {
      await _adminService.validateContent(type, contentId, status);
      await _loadAdminData(); // Reload data
      _showBeautifulSuccessMessage(
          'Contenu ${status == 'approved' ? 'approuvé' : 'rejeté'} avec succès');
    } catch (e) {
      _showBeautifulErrorMessage('Erreur lors de la validation: $e');
    }
  }

  void _showRejectDialog(String type, String contentId) {
    final TextEditingController feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rejeter le contenu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pourquoi rejetez-vous ce contenu ?'),
            SizedBox(height: 2.h),
            TextField(
              controller: feedbackController,
              decoration: InputDecoration(
                labelText: 'Commentaires (optionnel)',
                hintText: 'Raison du rejet...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _adminService.validateContent(
                  type,
                  contentId,
                  'rejected',
                  feedback: feedbackController.text.isNotEmpty
                      ? feedbackController.text
                      : null,
                );
                Navigator.pop(context);
                await _loadAdminData();
                _showBeautifulSuccessMessage('Contenu rejeté avec succès');
              } catch (e) {
                Navigator.pop(context);
                _showBeautifulErrorMessage('Erreur lors du rejet: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.error,
            ),
            child: Text('Rejeter'),
          ),
        ],
      ),
    );
  }

  void _showBeautifulSuccessMessage(String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Icon
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 8.w,
                  ),
                ),
                SizedBox(height: 3.h),
                // Title
                Text(
                  'Succès',
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                // Message
                Text(
                  message,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface.withAlpha(204),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4.h),
                // OK Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                      foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'OK',
                      style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBeautifulErrorMessage(String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Error Icon
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error,
                    color: Colors.red,
                    size: 8.w,
                  ),
                ),
                SizedBox(height: 3.h),
                // Title
                Text(
                  'Erreur',
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                // Message
                Text(
                  message,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface.withAlpha(204),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4.h),
                // OK Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.lightTheme.colorScheme.error,
                      foregroundColor: AppTheme.lightTheme.colorScheme.onError,
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'OK',
                      style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.lightTheme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}