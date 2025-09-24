import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dailygrowth/services/auth_service.dart';

// Generate mocks with: flutter packages pub run build_runner build
@GenerateMocks([SupabaseClient, GoTrueClient, User])
import 'auth_service_test.mocks.dart';

void main() {
  group('AuthService Tests', () {
    late AuthService authService;
    late MockSupabaseClient mockSupabaseClient;
    late MockGoTrueClient mockGoTrueClient;
    late MockUser mockUser;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockGoTrueClient = MockGoTrueClient();
      mockUser = MockUser();
      authService = AuthService();
      
      // Setup default mocks
      when(mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
    });

    group('Authentication Flow', () {
      test('should sign in user with valid credentials', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';
        final authResponse = AuthResponse(
          user: mockUser,
          session: null,
        );
        
        when(mockGoTrueClient.signInWithPassword(
          email: email,
          password: password,
        )).thenAnswer((_) async => authResponse);

        // Act & Assert
        expect(() async => await authService.signInWithEmailAndPassword(email, password), 
               returnsNormally);
      });

      test('should throw exception with invalid credentials', () async {
        // Arrange
        const email = 'invalid@example.com';
        const password = 'wrongpassword';
        
        when(mockGoTrueClient.signInWithPassword(
          email: email,
          password: password,
        )).thenThrow(AuthException('Invalid credentials'));

        // Act & Assert
        expect(() async => await authService.signInWithEmailAndPassword(email, password),
               throwsA(isA<AuthException>()));
      });

      test('should sign up user with valid data', () async {
        // Arrange
        const email = 'newuser@example.com';
        const password = 'password123';
        const fullName = 'New User';
        
        final authResponse = AuthResponse(
          user: mockUser,
          session: null,
        );
        
        when(mockGoTrueClient.signUp(
          email: email,
          password: password,
          data: {'full_name': fullName},
        )).thenAnswer((_) async => authResponse);

        // Act & Assert
        expect(() async => await authService.signUpWithEmailAndPassword(
          email, password, fullName), returnsNormally);
      });
    });

    group('User State Management', () {
      test('should return current user when authenticated', () {
        // Arrange
        when(mockGoTrueClient.currentUser).thenReturn(mockUser);
        when(mockUser.id).thenReturn('user123');

        // Act
        final user = authService.getCurrentUser();

        // Assert
        expect(user, isNotNull);
        expect(user?.id, equals('user123'));
      });

      test('should return null when not authenticated', () {
        // Arrange
        when(mockGoTrueClient.currentUser).thenReturn(null);

        // Act
        final user = authService.getCurrentUser();

        // Assert
        expect(user, isNull);
      });
    });

    group('Password Reset', () {
      test('should send password reset email', () async {
        // Arrange
        const email = 'user@example.com';
        
        when(mockGoTrueClient.resetPasswordForEmail(email))
            .thenAnswer((_) async => {});

        // Act & Assert
        expect(() async => await authService.resetPassword(email), 
               returnsNormally);
      });
    });

    group('Sign Out', () {
      test('should sign out user successfully', () async {
        // Arrange
        when(mockGoTrueClient.signOut()).thenAnswer((_) async => {});

        // Act & Assert
        expect(() async => await authService.signOut(), returnsNormally);
      });
    });
  });
}
