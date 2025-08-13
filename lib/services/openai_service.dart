import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class OpenAIService {
  static final OpenAIService _instance = OpenAIService._internal();
  late final Dio? _dio;
  static const String apiKey = String.fromEnvironment('OPENAI_API_KEY');

  // Factory constructor to return the singleton instance
  factory OpenAIService() {
    return _instance;
  }

  // Private constructor for singleton pattern
  OpenAIService._internal() {
    _initializeService();
  }

  void _initializeService() {
    try {
      // Load API key from environment variables
      if (apiKey.isEmpty) {
        debugPrint(
            '⚠️ OpenAI API key not configured. Service will use fallback content.');
        _dio = null;
        return;
      }

      // Configure Dio with base URL and headers
      _dio = Dio(
        BaseOptions(
          baseUrl: 'https://api.openai.com/v1',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      // Add interceptors for better error handling and logging
      _dio?.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            debugPrint(
                '🚀 OpenAI API Request: ${options.method} ${options.path}');
            handler.next(options);
          },
          onResponse: (response, handler) {
            debugPrint('✅ OpenAI API Response: ${response.statusCode}');
            handler.next(response);
          },
          onError: (DioException error, handler) {
            debugPrint(
                '❌ OpenAI API Error: ${error.response?.statusCode} - ${error.message}');
            handler.next(error);
          },
        ),
      );

      debugPrint('✅ OpenAI Service initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize OpenAI service: $e');
      _dio = null;
    }
  }

  // Add getter to check if API key is configured
  bool get isApiKeyConfigured => apiKey.isNotEmpty && _dio != null;

  Dio? get dio => _dio;

  /// Generate daily challenge for specific life domain
  Future<Map<String, String>> generateDailyChallenge({
    required String lifeDomain,
    String difficulty = 'medium',
  }) async {
    if (!isApiKeyConfigured) {
      debugPrint('⚠️ Using fallback challenge - API key not configured');
      return _getFallbackChallenge(lifeDomain, difficulty);
    }

    try {
      final difficultyPrompts = {
        'easy': 'un défi simple et accessible',
        'medium': 'un défi modéré qui demande un effort',
        'hard': 'un défi ambitieux et stimulant',
      };

      final prompt = '''
Génère un défi quotidien pour le domaine de vie "${lifeDomain}" avec une difficulté ${difficultyPrompts[difficulty] ?? 'modérée'}.

Format de réponse requis (JSON uniquement, sans texte supplémentaire):
{
  "title": "Titre concis et motivant du défi",
  "description": "Description détaillée du défi avec des étapes concrètes"
}

Le défi doit être:
- Réalisable en une journée
- Spécifique et actionnable
- Adapté au domaine de vie mentionné
- Motivant et positif
- En français
''';

      final messages = [
        Message(
            role: 'system',
            content:
                'Tu es un coach de développement personnel expert qui génère des défis quotidiens personnalisés.'),
        Message(role: 'user', content: prompt),
      ];

      final completion = await createChatCompletion(
        messages: messages,
        model: 'gpt-4o',
        options: {
          'temperature': 0.8,
          'max_tokens': 300,
        },
      );

      // Parse the JSON response
      try {
        final cleanedText = _cleanJsonResponse(completion.text);
        final jsonResponse = jsonDecode(cleanedText);

        final result = {
          'title': (jsonResponse['title'] ?? 'Défi de croissance') as String,
          'description': (jsonResponse['description'] ??
              'Prenez un moment pour réfléchir à votre développement personnel aujourd\'hui.') as String,
        };

        debugPrint('✅ Generated real challenge: ${result['title']}');
        return result;
      } catch (parseError) {
        debugPrint('❌ Error parsing OpenAI JSON response: $parseError');
        debugPrint('Raw response: ${completion.text}');
        return _getFallbackChallenge(lifeDomain, difficulty);
      }
    } catch (e) {
      debugPrint('❌ Error generating daily challenge: $e');
      // Return fallback challenge
      return _getFallbackChallenge(lifeDomain, difficulty);
    }
  }

  /// Clean JSON response from markdown formatting
  String _cleanJsonResponse(String rawResponse) {
    String cleaned = rawResponse.trim();
    
    // Remove markdown code blocks
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.replaceFirst('```json', '').trim();
    }
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceFirst('```', '').trim();
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3).trim();
    }
    
    return cleaned;
  }

  /// Generate personalized motivational message
  Future<String> generatePersonalizedMessage({
    required String userName,
    required int streakCount,
    required String lifeDomain,
    String messageType = 'encouragement',
  }) async {
    if (!isApiKeyConfigured) {
      debugPrint(
          '⚠️ Using fallback motivational message - API key not configured');
      return _getFallbackMotivationalMessage(userName, streakCount);
    }

    try {
      final messageTypePrompts = {
        'encouragement': 'un message d\'encouragement',
        'celebration': 'un message de félicitations',
        'motivation': 'un message motivationnel',
        'support': 'un message de soutien',
      };

      final prompt = '''
Génère ${messageTypePrompts[messageType] ?? 'un message d\'encouragement'} personnalisé pour ${userName} qui a une série de ${streakCount} jours dans le domaine "${lifeDomain}".

Le message doit être:
- Personnel et chaleureux
- Reconnaître l'effort et la progression
- Motivant pour continuer
- En français
- Entre 50 et 100 mots
- Éviter les émojis

Réponds uniquement avec le message, sans guillemets ni formatage supplémentaire.
''';

      final messages = [
        Message(
            role: 'system',
            content:
                'Tu es un coach personnel bienveillant qui motive et encourage les personnes dans leur développement personnel.'),
        Message(role: 'user', content: prompt),
      ];

      final completion = await createChatCompletion(
        messages: messages,
        model: 'gpt-4o',
        options: {
          'temperature': 0.9,
          'max_tokens': 200,
        },
      );

      debugPrint('✅ Generated personalized message for ${userName}');
      return completion.text.trim();
    } catch (e) {
      debugPrint('❌ Error generating personalized message: $e');
      // Return fallback message
      return _getFallbackMotivationalMessage(userName, streakCount);
    }
  }

  /// Generate inspirational quote for specific life domain
  Future<Map<String, String>> generateInspirationalQuote({
    required String lifeDomain,
  }) async {
    if (!isApiKeyConfigured) {
      debugPrint('⚠️ Using fallback quote - API key not configured');
      return _getFallbackQuote(lifeDomain);
    }

    try {
      final prompt = '''
Génère une citation inspirante et motivante pour le domaine de vie "${lifeDomain}".

Format de réponse requis (JSON uniquement, sans texte supplémentaire):
{
  "quote": "La citation inspirante",
  "author": "Nom de l'auteur"
}

La citation doit être:
- Inspirante et motivante
- Pertinente au domaine de vie mentionné
- Authentique (d'un auteur réel connu)
- En français
- Pas trop longue (maximum 2 phrases)

Si aucune citation authentique ne correspond parfaitement au domaine, adapte une citation existante ou utilise un proverbe reconnu.
''';

      final messages = [
        Message(
            role: 'system',
            content:
                'Tu es un expert en citations motivantes et développement personnel. Tu connais de nombreuses citations d\'auteurs célèbres.'),
        Message(role: 'user', content: prompt),
      ];

      final completion = await createChatCompletion(
        messages: messages,
        model: 'gpt-4o',
        options: {
          'temperature': 0.7,
          'max_tokens': 200,
        },
      );

      // Parse the JSON response
      try {
        final cleanedText = _cleanJsonResponse(completion.text);
        final jsonResponse = jsonDecode(cleanedText);

        final result = {
          'quote': (jsonResponse['quote'] ??
              'La croissance commence là où finit votre zone de confort.') as String,
          'author': (jsonResponse['author'] ?? 'Robin Sharma') as String,
        };

        debugPrint('✅ Generated inspirational quote: ${result['quote']}');
        return result;
      } catch (parseError) {
        debugPrint('❌ Error parsing quote JSON response: $parseError');
        return _getFallbackQuote(lifeDomain);
      }
    } catch (e) {
      debugPrint('❌ Error generating inspirational quote: $e');
      // Return fallback quote
      return _getFallbackQuote(lifeDomain);
    }
  }

  /// Generates a text response
  /// Sends a POST request to /chat/completions with messages and model.
  Future<Completion> createChatCompletion({
    required List<Message> messages,
    String model = 'gpt-4o',
    Map<String, dynamic>? options,
  }) async {
    if (!isApiKeyConfigured || _dio == null) {
      throw OpenAIException(
        statusCode: 401,
        message: 'OpenAI API key not configured',
      );
    }

    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': model,
          'messages': messages
              .map((m) => {
                    'role': m.role,
                    'content': m.content,
                  })
              .toList(),
          if (options != null) ...options,
        },
      );

      if (response.data == null ||
          response.data['choices'] == null ||
          response.data['choices'].isEmpty) {
        throw OpenAIException(
          statusCode: response.statusCode ?? 500,
          message: 'Invalid response format from OpenAI API',
        );
      }

      final text = response.data['choices'][0]['message']['content'] ?? '';
      return Completion(text: text);
    } on DioException catch (e) {
      throw OpenAIException(
        statusCode: e.response?.statusCode ?? 500,
        message: e.response?.data?['error']?['message'] ??
            e.message ??
            'Unknown error',
      );
    }
  }

  /// Streams a text response
  /// Uses server-sent events (SSE) from /chat/completions with stream=true.
  Stream<StreamCompletion> streamChatCompletion({
    required List<Message> messages,
    String model = 'gpt-4o',
    Map<String, dynamic>? options,
  }) async* {
    if (!isApiKeyConfigured || _dio == null) {
      throw OpenAIException(
        statusCode: 401,
        message: 'OpenAI API key not configured',
      );
    }

    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': model,
          'messages': messages
              .map((m) => {
                    'role': m.role,
                    'content': m.content,
                  })
              .toList(),
          'stream': true,
          if (options != null) ...options,
        },
        options: Options(responseType: ResponseType.stream),
      );

      final stream = response.data.stream;
      await for (var line
          in LineSplitter().bind(utf8.decoder.bind(stream.stream))) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          if (data == '[DONE]') break;

          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final delta =
                json['choices']?[0]?['delta'] as Map<String, dynamic>? ?? {};
            final content = delta['content'] ?? '';
            final finishReason = json['choices']?[0]?['finish_reason'];
            final systemFingerprint = json['system_fingerprint'];

            yield StreamCompletion(
              content: content,
              finishReason: finishReason,
              systemFingerprint: systemFingerprint,
            );

            // If finish reason is provided, this is the final chunk
            if (finishReason != null) break;
          } catch (parseError) {
            debugPrint('❌ Error parsing streaming response: $parseError');
            continue;
          }
        }
      }
    } on DioException catch (e) {
      throw OpenAIException(
        statusCode: e.response?.statusCode ?? 500,
        message: e.response?.data?['error']?['message'] ??
            e.message ??
            'Unknown streaming error',
      );
    }
  }

  // A more user-friendly wrapper for streaming that just yields content strings
  Stream<String> streamContentOnly({
    required List<Message> messages,
    String model = 'gpt-4o',
    Map<String, dynamic>? options,
  }) async* {
    if (!isApiKeyConfigured) {
      yield 'Service OpenAI non configuré. Utilisation du contenu par défaut.';
      return;
    }

    await for (final chunk in streamChatCompletion(
      messages: messages,
      model: model,
      options: options,
    )) {
      if (chunk.content.isNotEmpty) {
        yield chunk.content;
      }
    }
  }

  /// List of available OpenAI models.
  /// Sends a GET request to /models to fetch model IDs.
  Future<List<String>> listModels() async {
    if (!isApiKeyConfigured || _dio == null) {
      throw OpenAIException(
        statusCode: 401,
        message: 'OpenAI API key not configured',
      );
    }

    try {
      final response = await _dio.get('/models');
      final models = response.data['data'] as List;
      return models.map((m) => m['id'] as String).toList();
    } on DioException catch (e) {
      throw OpenAIException(
        statusCode: e.response?.statusCode ?? 500,
        message: e.response?.data?['error']?['message'] ??
            e.message ??
            'Error fetching models',
      );
    }
  }

  /// Vision API (image analysis)
  /// Supports both imageUrl and local image files (as base64).
  Future<Completion> generateTextFromImage({
    String? imageUrl,
    Uint8List? imageBytes,
    String promptText = 'Describe the scene in this image:',
    String model = 'gpt-4o',
    Map<String, dynamic>? options,
  }) async {
    if (!isApiKeyConfigured || _dio == null) {
      throw OpenAIException(
        statusCode: 401,
        message: 'OpenAI API key not configured',
      );
    }

    try {
      if (imageUrl == null && imageBytes == null) {
        throw ArgumentError('Either imageUrl or imageBytes must be provided');
      }

      final List<Map<String, dynamic>> content = [
        {'type': 'text', 'text': promptText},
      ];

      // Add image content based on what was provided
      if (imageUrl != null) {
        content.add({
          'type': 'image_url',
          'image_url': {'url': imageUrl}
        });
      } else if (imageBytes != null) {
        // Convert image bytes to base64
        final base64Image = base64Encode(imageBytes);
        content.add({
          'type': 'image_url',
          'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}
        });
      }

      final messages = [
        Message(role: 'user', content: content),
      ];

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': model,
          'messages': messages
              .map((m) => {
                    'role': m.role,
                    'content': m.content,
                  })
              .toList(),
          if (options != null) ...options,
        },
      );

      final text = response.data['choices'][0]['message']['content'];
      return Completion(text: text);
    } on DioException catch (e) {
      throw OpenAIException(
        statusCode: e.response?.statusCode ?? 500,
        message: e.response?.data?['error']?['message'] ??
            e.message ??
            'Vision API error',
      );
    }
  }

  /// DALL·E 3 image generation
  /// Returns result based on the specified response_format (url or b64_json).
  Future<ImageGenerationResult> generateImages({
    required String prompt,
    int n = 1,
    String size = '1024x1024',
    String model = 'dall-e-3',
    String responseFormat = 'url',
  }) async {
    if (!isApiKeyConfigured || _dio == null) {
      throw OpenAIException(
        statusCode: 401,
        message: 'OpenAI API key not configured',
      );
    }

    try {
      final response = await _dio.post(
        '/images/generations',
        data: {
          'model': model,
          'prompt': prompt,
          'n': n,
          'size': size,
          'response_format': responseFormat
        },
      );

      // Extract usage information if available
      final usage = response.data['usage'] as Map<String, dynamic>?;

      // Process image data based on response format
      final List data = response.data['data'];
      final List<GeneratedImage> images = [];

      for (var item in data) {
        if (responseFormat == 'url') {
          images.add(GeneratedImage(
            url: item['url'],
            base64Data: null,
          ));
        } else if (responseFormat == 'b64_json') {
          images.add(GeneratedImage(
            url: null,
            base64Data: item['b64_json'],
          ));
        }
      }

      return ImageGenerationResult(
        images: images,
        usage: usage != null ? UsageInfo.fromJson(usage) : null,
      );
    } on DioException catch (e) {
      throw OpenAIException(
        statusCode: e.response?.statusCode ?? 500,
        message: e.response?.data?['error']?['message'] ??
            e.message ??
            'Image generation error',
      );
    }
  }

  // Convenience method to get only URLs from generateImages
  Future<List<String>> generateImageUrls({
    required String prompt,
    int n = 1,
    String size = '1024x1024',
    String model = 'dall-e-3',
  }) async {
    final result = await generateImages(
      prompt: prompt,
      n: n,
      size: size,
      model: model,
      responseFormat: 'url',
    );

    return result.images
        .where((img) => img.url != null)
        .map((img) => img.url!)
        .toList();
  }

  // Convenience method to get base64 data from generateImages
  Future<List<String>> generateImageBase64({
    required String prompt,
    int n = 1,
    String size = '1024x1024',
    String model = 'dall-e-3',
  }) async {
    final result = await generateImages(
      prompt: prompt,
      n: n,
      size: size,
      model: model,
      responseFormat: 'b64_json',
    );

    return result.images
        .where((img) => img.base64Data != null)
        .map((img) => img.base64Data!)
        .toList();
  }

  /// Text-to-Speech (TTS)
  /// Converts text to audio and saves it to a file.
  Future<File> createSpeech({
    required String input,
    String model = 'tts-1',
    String voice = 'alloy',
    String responseFormat = 'mp3',
    double? speed,
  }) async {
    if (!isApiKeyConfigured || _dio == null) {
      throw OpenAIException(
        statusCode: 401,
        message: 'OpenAI API key not configured',
      );
    }

    try {
      final response = await _dio.post(
        '/audio/speech',
        data: {
          'model': model,
          'input': input,
          'voice': voice,
          'response_format': responseFormat,
          if (speed != null) 'speed': speed,
        },
        options: Options(responseType: ResponseType.bytes),
      );

      // Save audio to a temporary file
      final tempDir = await getTemporaryDirectory();
      final fileExtension = responseFormat == 'opus' ? 'ogg' : responseFormat;
      final audioFile = File(
          '${tempDir.path}/speech_${DateTime.now().millisecondsSinceEpoch}.$fileExtension');
      await audioFile.writeAsBytes(response.data);

      return audioFile;
    } on DioException catch (e) {
      throw OpenAIException(
        statusCode: e.response?.statusCode ?? 500,
        message: e.response?.data?['error']?['message'] ??
            e.message ??
            'Text-to-speech error',
      );
    }
  }

  /// Speech-to-Text (STT)
  /// Transcribes audio to text using the Whisper model.
  Future<Transcription> transcribeAudio({
    required File audioFile,
    String model = 'whisper-1',
    String? prompt,
    String responseFormat = 'json',
    String? language,
    double? temperature,
  }) async {
    if (!isApiKeyConfigured || _dio == null) {
      throw OpenAIException(
        statusCode: 401,
        message: 'OpenAI API key not configured',
      );
    }

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          audioFile.path,
          filename: audioFile.path.split('/').last,
        ),
        'model': model,
        if (prompt != null) 'prompt': prompt,
        'response_format': responseFormat,
        if (language != null) 'language': language,
        if (temperature != null) 'temperature': temperature,
      });

      final response = await _dio.post(
        '/audio/transcriptions',
        data: formData,
      );

      if (responseFormat == 'json') {
        return Transcription(text: response.data['text'] ?? '');
      } else {
        return Transcription(text: response.data.toString());
      }
    } on DioException catch (e) {
      throw OpenAIException(
        statusCode: e.response?.statusCode ?? 500,
        message: e.response?.data?['error']?['message'] ??
            e.message ??
            'Speech-to-text error',
      );
    }
  }

  // Helper methods for fallback content
  Map<String, String> _getFallbackChallenge(
      String lifeDomain, String difficulty) {
    final challenges = {
      'sante': {
        'easy': {
          'title': 'Hydratation consciente',
          'description':
              'Buvez un grand verre d\'eau dès votre réveil et observez comment vous vous sentez.',
        },
        'medium': {
          'title': 'Marche méditative',
          'description':
              'Prenez 15 minutes pour une marche en pleine conscience, en portant attention à votre respiration.',
        },
        'hard': {
          'title': 'Défi nutrition',
          'description':
              'Préparez un repas équilibré avec 5 couleurs différentes de légumes et fruits.',
        },
      },
      'relations': {
        'easy': {
          'title': 'Message d\'appréciation',
          'description':
              'Envoyez un message sincère à quelqu\'un pour lui dire ce que vous appréciez chez lui.',
        },
        'medium': {
          'title': 'Écoute active',
          'description':
              'Lors d\'une conversation aujourd\'hui, concentrez-vous uniquement sur l\'écoute sans préparer votre réponse.',
        },
        'hard': {
          'title': 'Résolution de conflit',
          'description':
              'Identifiez un malentendu récent et prenez l\'initiative d\'une conversation pour le résoudre.',
        },
      },
      'carriere': {
        'easy': {
          'title': 'Organisation productive',
          'description':
              'Organisez votre espace de travail et priorisez vos 3 tâches les plus importantes.',
        },
        'medium': {
          'title': 'Apprentissage ciblé',
          'description':
              'Consacrez 30 minutes à apprendre quelque chose de nouveau dans votre domaine professionnel.',
        },
        'hard': {
          'title': 'Réseautage stratégique',
          'description':
              'Contactez un professionnel de votre secteur pour échanger sur les tendances actuelles.',
        },
      },
      'finances': {
        'easy': {
          'title': 'Bilan financier rapide',
          'description':
              'Notez vos dépenses d\'hier et identifiez une économie possible pour aujourd\'hui.',
        },
        'medium': {
          'title': 'Objectif d\'épargne',
          'description':
              'Calculez combien vous pourriez économiser ce mois et définissez un objectif concret.',
        },
        'hard': {
          'title': 'Plan d\'investissement',
          'description':
              'Recherchez et évaluez une nouvelle opportunité d\'investissement pour votre avenir.',
        },
      },
      'developpement': {
        'easy': {
          'title': 'Moment de gratitude',
          'description':
              'Notez trois choses pour lesquelles vous êtes reconnaissant aujourd\'hui.',
        },
        'medium': {
          'title': 'Lecture enrichissante',
          'description':
              'Lisez un chapitre d\'un livre de développement personnel et notez un insight.',
        },
        'hard': {
          'title': 'Sortie de zone de confort',
          'description':
              'Identifiez une peur qui vous limite et posez une action concrète pour la dépasser.',
        },
      },
      'spiritualite': {
        'easy': {
          'title': 'Méditation matinale',
          'description':
              'Consacrez 5 minutes à la méditation ou à la réflexion silencieuse ce matin.',
        },
        'medium': {
          'title': 'Connexion à la nature',
          'description':
              'Passez 20 minutes dans la nature en observant et appréciant ce qui vous entoure.',
        },
        'hard': {
          'title': 'Service aux autres',
          'description':
              'Trouvez une façon d\'aider quelqu\'un aujourd\'hui sans attendre de retour.',
        },
      },
      'loisirs': {
        'easy': {
          'title': 'Activité créative',
          'description':
              'Consacrez 15 minutes à une activité créative qui vous fait plaisir.',
        },
        'medium': {
          'title': 'Nouvelle expérience',
          'description':
              'Essayez une activité de loisir que vous n\'avez jamais pratiquée.',
        },
        'hard': {
          'title': 'Projet passion',
          'description':
              'Avancez significativement sur un projet personnel qui vous tient à cœur.',
        },
      },
      'famille': {
        'easy': {
          'title': 'Appel familial',
          'description':
              'Appelez un membre de votre famille pour prendre de ses nouvelles.',
        },
        'medium': {
          'title': 'Temps de qualité',
          'description':
              'Planifiez et réalisez une activité spéciale avec un proche.',
        },
        'hard': {
          'title': 'Réconciliation',
          'description':
              'Tendez la main à un proche avec qui vous avez eu des tensions récemment.',
        },
      },
    };

    final domainChallenges =
        challenges[lifeDomain] ?? challenges['developpement']!;
    final challenge =
        domainChallenges[difficulty] ?? domainChallenges['medium']!;

    return {
      'title': challenge['title']!,
      'description': challenge['description']!,
    };
  }

  String _getFallbackMotivationalMessage(String userName, int streakCount) {
    if (streakCount == 0) {
      return 'Bonjour ${userName} ! Chaque grand voyage commence par un premier pas. Vous avez tout ce qu\'il faut pour réussir !';
    } else if (streakCount < 7) {
      return 'Bravo ${userName} ! Vous construisez déjà une belle habitude avec ${streakCount} jours consécutifs. Continuez sur cette excellente lancée !';
    } else if (streakCount < 30) {
      return 'Impressionnant ${userName} ! ${streakCount} jours consécutifs témoignent de votre détermination et de votre engagement. Vous inspirez !';
    } else {
      return 'Extraordinaire ${userName} ! ${streakCount} jours de constance, vous êtes un véritable exemple de persévérance et d\'inspiration !';
    }
  }

  Map<String, String> _getFallbackQuote(String lifeDomain) {
    final fallbackQuotes = {
      'sante': {
        'quote':
            'Prendre soin de son corps, c\'est prendre soin de son esprit.',
        'author': 'Proverbe ancien'
      },
      'relations': {
        'quote':
            'Les relations authentiques sont le véritable trésor de la vie.',
        'author': 'Maya Angelou'
      },
      'carriere': {
        'quote':
            'Le succès, c\'est d\'aller d\'échec en échec sans perdre son enthousiasme.',
        'author': 'Winston Churchill'
      },
      'finances': {
        'quote':
            'Ce n\'est pas combien d\'argent vous gagnez, mais combien vous gardez.',
        'author': 'Robert Kiyosaki'
      },
      'developpement': {
        'quote': 'La croissance commence là où finit votre zone de confort.',
        'author': 'Robin Sharma'
      },
      'spiritualite': {
        'quote':
            'La paix vient de l\'intérieur. Ne la cherchez pas à l\'extérieur.',
        'author': 'Bouddha'
      },
      'loisirs': {
        'quote': 'Le jeu est la forme la plus élevée de la recherche.',
        'author': 'Albert Einstein'
      },
      'famille': {
        'quote': 'La famille est le premier lieu où nous apprenons à aimer.',
        'author': 'Anonyme'
      },
    };

    return fallbackQuotes[lifeDomain] ?? fallbackQuotes['developpement']!;
  }
}

/// Support classes
class Message {
  final String role;
  final dynamic content;

  Message({required this.role, required this.content});
}

class Completion {
  final String text;

  Completion({required this.text});
}

class StreamCompletion {
  final String content;
  final String? finishReason;
  final String? systemFingerprint;

  StreamCompletion({
    required this.content,
    this.finishReason,
    this.systemFingerprint,
  });
}

class GeneratedImage {
  final String? url;
  final String? base64Data;

  GeneratedImage({this.url, this.base64Data});

  // Convert base64 data to image bytes
  Uint8List? get imageBytes =>
      base64Data != null ? base64Decode(base64Data!) : null;
}

class UsageInfo {
  final int totalTokens;
  final int inputTokens;
  final int outputTokens;
  final Map<String, dynamic>? inputTokensDetails;

  UsageInfo({
    required this.totalTokens,
    required this.inputTokens,
    required this.outputTokens,
    this.inputTokensDetails,
  });

  factory UsageInfo.fromJson(Map<String, dynamic> json) {
    return UsageInfo(
      totalTokens: json['total_tokens'] ?? 0,
      inputTokens: json['input_tokens'] ?? 0,
      outputTokens: json['output_tokens'] ?? 0,
      inputTokensDetails: json['input_tokens_details'],
    );
  }
}

class ImageGenerationResult {
  final List<GeneratedImage> images;
  final UsageInfo? usage;

  ImageGenerationResult({required this.images, this.usage});
}

class Transcription {
  final String text;

  Transcription({required this.text});
}

class OpenAIException implements Exception {
  final int statusCode;
  final String message;

  OpenAIException({required this.statusCode, required this.message});

  @override
  String toString() => 'OpenAIException: $statusCode - $message';
}