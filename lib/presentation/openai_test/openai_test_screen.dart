import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter/services.dart';

import '../../core/app_export.dart';
import '../../services/openai_service.dart';

class OpenAITestScreen extends StatefulWidget {
  const OpenAITestScreen({Key? key}) : super(key: key);

  @override
  State<OpenAITestScreen> createState() => _OpenAITestScreenState();
}

class _OpenAITestScreenState extends State<OpenAITestScreen> {
  final OpenAIService _openAIService = OpenAIService();

  // Test states
  bool _isTestingApiKey = false;
  bool _isTestingChatCompletion = false;
  bool _isTestingListModels = false;
  bool _isTestingChallengeGeneration = false;

  // Test results
  ApiTestResult? _apiKeyResult;
  ApiTestResult? _chatCompletionResult;
  ApiTestResult? _listModelsResult;
  ApiTestResult? _challengeGenerationResult;

  // Controllers
  final TextEditingController _testPromptController = TextEditingController(
      text:
          'Hello, please respond with a simple greeting to test the API connection.');

  @override
  void initState() {
    super.initState();
    _performBasicApiKeyTest();
  }

  @override
  void dispose() {
    _testPromptController.dispose();
    super.dispose();
  }

  // Perform basic API key validation test
  Future<void> _performBasicApiKeyTest() async {
    setState(() {
      _isTestingApiKey = true;
      _apiKeyResult = null;
    });

    try {
      if (!_openAIService.isApiKeyConfigured) {
        setState(() {
          _apiKeyResult = ApiTestResult(
            success: false,
            message:
                'Clé API OpenAI non configurée. Ajoutez OPENAI_API_KEY dans les variables d\'environnement.',
            details:
                'Utilisez --dart-define=OPENAI_API_KEY=your-key lors du lancement de l\'application.',
          );
        });
        return;
      }

      // Test basic connectivity by listing models
      final models = await _openAIService.listModels();

      setState(() {
        _apiKeyResult = ApiTestResult(
          success: true,
          message: 'Clé API OpenAI valide et fonctionnelle!',
          details: 'Connexion établie. ${models.length} modèles disponibles.',
        );
      });
    } catch (e) {
      setState(() {
        _apiKeyResult = ApiTestResult(
          success: false,
          message: 'Erreur de validation de la clé API',
          details: _getErrorDetails(e),
        );
      });
    } finally {
      setState(() {
        _isTestingApiKey = false;
      });
    }
  }

  // Test chat completion functionality
  Future<void> _testChatCompletion() async {
    if (_testPromptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un message de test')),
      );
      return;
    }

    setState(() {
      _isTestingChatCompletion = true;
      _chatCompletionResult = null;
    });

    try {
      final messages = [
        Message(role: 'user', content: _testPromptController.text.trim()),
      ];

      final completion = await _openAIService.createChatCompletion(
        messages: messages,
        model: 'gpt-4o',
        options: {'temperature': 0.7, 'max_tokens': 150},
      );

      setState(() {
        _chatCompletionResult = ApiTestResult(
          success: true,
          message: 'Chat completion réussi!',
          details: 'Réponse: ${completion.text}',
        );
      });
    } catch (e) {
      setState(() {
        _chatCompletionResult = ApiTestResult(
          success: false,
          message: 'Erreur de chat completion',
          details: _getErrorDetails(e),
        );
      });
    } finally {
      setState(() {
        _isTestingChatCompletion = false;
      });
    }
  }

  // Test model listing functionality
  Future<void> _testListModels() async {
    setState(() {
      _isTestingListModels = true;
      _listModelsResult = null;
    });

    try {
      final models = await _openAIService.listModels();
      final availableModels = models
          .where((model) =>
              model.contains('gpt-4') ||
              model.contains('gpt-3.5') ||
              model.contains('dall-e'))
          .take(5)
          .toList();

      setState(() {
        _listModelsResult = ApiTestResult(
          success: true,
          message: 'Liste des modèles récupérée avec succès!',
          details:
              'Modèles principaux disponibles: ${availableModels.join(", ")}',
        );
      });
    } catch (e) {
      setState(() {
        _listModelsResult = ApiTestResult(
          success: false,
          message: 'Erreur lors de la récupération des modèles',
          details: _getErrorDetails(e),
        );
      });
    } finally {
      setState(() {
        _isTestingListModels = false;
      });
    }
  }

  // Test challenge generation (actual app functionality)
  Future<void> _testChallengeGeneration() async {
    setState(() {
      _isTestingChallengeGeneration = true;
      _challengeGenerationResult = null;
    });

    try {
      final challenge = await _openAIService.generateDailyChallenge(
        lifeDomain: 'sante',
        difficulty: 'medium',
      );

      setState(() {
        _challengeGenerationResult = ApiTestResult(
          success: true,
          message: 'Génération de défi réussie!',
          details:
              'Titre: ${challenge['title']}\n\nDescription: ${challenge['description']}',
        );
      });
    } catch (e) {
      setState(() {
        _challengeGenerationResult = ApiTestResult(
          success: false,
          message: 'Erreur lors de la génération du défi',
          details: _getErrorDetails(e),
        );
      });
    } finally {
      setState(() {
        _isTestingChallengeGeneration = false;
      });
    }
  }

  String _getErrorDetails(dynamic error) {
    if (error is OpenAIException) {
      switch (error.statusCode) {
        case 401:
          return 'Clé API invalide ou expirée (HTTP 401)';
        case 403:
          return 'Accès refusé - vérifiez les permissions de votre clé API (HTTP 403)';
        case 429:
          return 'Limite de taux dépassée - trop de requêtes (HTTP 429)';
        case 500:
          return 'Erreur serveur OpenAI (HTTP 500)';
        default:
          return 'Erreur API: ${error.statusCode} - ${error.message}';
      }
    }
    return error.toString();
  }

  void _copyApiKeyInstructions() {
    const instructions = '''
Pour configurer votre clé API OpenAI:

1. Obtenez votre clé API sur https://platform.openai.com/api-keys

2. Lancez l'application avec la variable d'environnement:
   flutter run --dart-define=OPENAI_API_KEY=your-api-key-here

3. Pour le build de production:
   flutter build apk --dart-define=OPENAI_API_KEY=your-api-key-here

Remplacez "your-api-key-here" par votre vraie clé API OpenAI.
''';

    Clipboard.setData(const ClipboardData(text: instructions));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Instructions copiées dans le presse-papiers')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Test OpenAI API',
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const CustomIconWidget(
                iconName: 'help_outline', color: Colors.white),
            onPressed: _copyApiKeyInstructions,
            tooltip: 'Instructions de configuration',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildApiKeyStatusCard(),
            SizedBox(height: 3.h),
            _buildTestPromptSection(),
            SizedBox(height: 3.h),
            _buildTestSection(
              'Test de Chat Completion',
              'Teste la fonctionnalité de génération de texte',
              _chatCompletionResult,
              _isTestingChatCompletion,
              _testChatCompletion,
            ),
            SizedBox(height: 2.h),
            _buildTestSection(
              'Test Liste des Modèles',
              'Vérifie l\'accès aux modèles OpenAI disponibles',
              _listModelsResult,
              _isTestingListModels,
              _testListModels,
            ),
            SizedBox(height: 2.h),
            _buildTestSection(
              'Test Génération de Défi',
              'Teste la fonctionnalité spécifique de l\'application',
              _challengeGenerationResult,
              _isTestingChallengeGeneration,
              _testChallengeGeneration,
            ),
            SizedBox(height: 4.h),
            _buildApiKeyInstructionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildApiKeyStatusCard() {
    final bool isConfigured = _openAIService.isApiKeyConfigured;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isConfigured ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(
          color: isConfigured ? Colors.green.shade200 : Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: isConfigured ? 'check_circle' : 'error',
                color: isConfigured ? Colors.green : Colors.red,
                size: 6.w,
              ),
              SizedBox(width: 3.w),
              Text(
                isConfigured ? 'Clé API Configurée' : 'Clé API Non Configurée',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: isConfigured
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          if (_apiKeyResult != null) ...[
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: _apiKeyResult!.success
                    ? Colors.green.shade100
                    : Colors.red.shade100,
                borderRadius: BorderRadius.circular(2.w),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _apiKeyResult!.message,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: _apiKeyResult!.success
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                    ),
                  ),
                  if (_apiKeyResult!.details.isNotEmpty) ...[
                    SizedBox(height: 1.h),
                    Text(
                      _apiKeyResult!.details,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: _apiKeyResult!.success
                            ? Colors.green.shade600
                            : Colors.red.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (_isTestingApiKey) ...[
            SizedBox(height: 2.h),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  Widget _buildTestPromptSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3.w),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Message de Test',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          TextField(
            controller: _testPromptController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Entrez votre message de test ici...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(2.w),
              ),
              contentPadding: EdgeInsets.all(3.w),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestSection(
    String title,
    String description,
    ApiTestResult? result,
    bool isLoading,
    VoidCallback onTest,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3.w),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: isLoading ? null : onTest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: isLoading
                    ? SizedBox(
                        width: 4.w,
                        height: 4.w,
                        child: const CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Tester'),
              ),
            ],
          ),
          if (result != null) ...[
            SizedBox(height: 3.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color:
                    result.success ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(2.w),
                border: Border.all(
                  color: result.success
                      ? Colors.green.shade200
                      : Colors.red.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: result.success ? 'check_circle' : 'error',
                        color: result.success ? Colors.green : Colors.red,
                        size: 5.w,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        result.message,
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: result.success
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  if (result.details.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      result.details,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: result.success
                            ? Colors.green.shade600
                            : Colors.red.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildApiKeyInstructionsCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(
          color: Colors.blue.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CustomIconWidget(
                iconName: 'info',
                color: Colors.blue,
              ),
              SizedBox(width: 3.w),
              Text(
                'Instructions de Configuration',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            '1. Obtenez votre clé API sur https://platform.openai.com/api-keys\n'
            '2. Lancez l\'app avec: flutter run --dart-define=OPENAI_API_KEY=votre-clé\n'
            '3. Pour le build: flutter build apk --dart-define=OPENAI_API_KEY=votre-clé',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: Colors.blue.shade600,
              height: 1.4,
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _copyApiKeyInstructions,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Copier les Instructions'),
            ),
          ),
        ],
      ),
    );
  }
}

class ApiTestResult {
  final bool success;
  final String message;
  final String details;

  ApiTestResult({
    required this.success,
    required this.message,
    this.details = '',
  });
}
