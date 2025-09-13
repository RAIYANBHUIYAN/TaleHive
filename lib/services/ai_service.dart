import 'package:http/http.dart' as http;
import 'dart:convert';

class AIService {
  // Your Gemini API key
  static const String _apiKey = 'AIzaSyBt0ZlI2P91w0931rKmuC67xPL3VKeGpAA';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  Future<String?> getChatResponse({
    required String message,
    String? bookContext,
    String? clubContext,
    int maxRetries = 2,
  }) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        // Build the prompt with context
        String prompt = _buildPrompt(message, bookContext, clubContext);

        final response = await http.post(
          Uri.parse('$_baseUrl?key=$_apiKey'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'contents': [{
              'parts': [{
                'text': prompt
              }]
            }],
            'generationConfig': {
              'temperature': 0.7,
              'topK': 40,
              'topP': 0.95,
              'maxOutputTokens': 1024,
            }
          }),
        ).timeout(Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final candidates = data['candidates'] as List?;
          
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'];
            final parts = content['parts'] as List;
            
            if (parts.isNotEmpty) {
              return parts[0]['text'] as String;
            }
          }
        } else if (response.statusCode == 503 && attempt < maxRetries) {
          // Service unavailable - retry after delay
          print('Gemini API overloaded (attempt ${attempt + 1}/${maxRetries + 1}), retrying in ${(attempt + 1) * 2} seconds...');
          await Future.delayed(Duration(seconds: (attempt + 1) * 2));
          continue;
        } else {
          print('Gemini API error: ${response.statusCode}');
          print('Response body: ${response.body}');
          
          // Return user-friendly error messages based on status code
          if (response.statusCode == 503) {
            return 'I\'m currently experiencing high demand. Please try again in a few moments. 🤖';
          } else if (response.statusCode == 429) {
            return 'I\'m receiving too many requests. Please wait a moment before asking again. ⏳';
          } else if (response.statusCode >= 500) {
            return 'I\'m temporarily unavailable due to server issues. Please try again later. 🔧';
          } else {
            return 'I encountered an issue processing your request. Please try rephrasing your question. 💭';
          }
        }
      } catch (e) {
        print('Error getting AI response (attempt ${attempt + 1}): $e');
        if (attempt == maxRetries) {
          if (e.toString().contains('TimeoutException')) {
            return 'The request timed out. Please check your internet connection and try again. 📶';
          } else {
            return 'I\'m having trouble connecting right now. Please try again in a moment. 🔄';
          }
        } else if (attempt < maxRetries) {
          // Wait before retrying
          await Future.delayed(Duration(seconds: (attempt + 1) * 2));
        }
      }
    }
    
    return 'I\'m currently unavailable. Please try again later. 😔';
  }

  String _buildPrompt(String userMessage, String? bookContext, String? clubContext) {
    StringBuffer prompt = StringBuffer();
    
    prompt.writeln('You are an AI assistant for a book club platform. Your role is to help users discuss books, recommend reading materials, and facilitate meaningful conversations about literature.');
    
    if (clubContext != null) {
      prompt.writeln('\nClub Context: $clubContext');
    }
    
    if (bookContext != null) {
      prompt.writeln('\nBook Context: $bookContext');
    }
    
    prompt.writeln('\nPlease respond to the following message in a helpful, engaging, and literary manner:');
    prompt.writeln('\nUser: $userMessage');
    
    return prompt.toString();
  }

  Future<List<String>> getBookRecommendations({
    required String genre,
    required String userPreferences,
    int limit = 5,
  }) async {
    try {
      String prompt = '''
You are a book recommendation expert. Based on the following preferences, suggest $limit books:

Genre: $genre
User Preferences: $userPreferences

Please provide book recommendations in the following format:
- Book Title by Author Name: Brief description

Focus on well-regarded books that match the user's preferences. Include a mix of classic and contemporary works when appropriate.
''';

      final response = await getChatResponse(message: prompt);
      
      if (response != null) {
        // Parse the recommendations into a list
        final lines = response.split('\n')
            .where((line) => line.trim().startsWith('-'))
            .map((line) => line.trim().substring(1).trim())
            .toList();
        
        return lines.take(limit).toList();
      }
    } catch (e) {
      print('Error getting book recommendations: $e');
    }
    
    return [];
  }

  Future<String?> generateBookSummary(String bookTitle) async {
    try {
      String prompt = '''
Please provide a concise but informative summary of "$bookTitle". 

Include:
1. Main plot/theme (2-3 sentences)
2. Key characters (if applicable)
3. Writing style or notable aspects
4. Why readers might enjoy this book

Keep the summary engaging and spoiler-free.
''';

      return await getChatResponse(message: prompt);
    } catch (e) {
      print('Error generating book summary: $e');
      return null;
    }
  }

  Future<List<String>> generateDiscussionQuestions({
    required String bookTitle,
    int questionCount = 5,
  }) async {
    try {
      String prompt = '''
Generate $questionCount thoughtful discussion questions for "$bookTitle".

The questions should:
- Encourage deep thinking about themes, characters, and plot
- Be suitable for book club discussions
- Avoid major spoilers
- Range from accessible to more analytical

Format each question on a new line starting with "Q: "
''';

      final response = await getChatResponse(message: prompt);
      
      if (response != null) {
        final questions = response.split('\n')
            .where((line) => line.trim().startsWith('Q:'))
            .map((line) => line.trim().substring(2).trim())
            .toList();
        
        return questions.take(questionCount).toList();
      }
    } catch (e) {
      print('Error generating discussion questions: $e');
    }
    
    return [];
  }

  Future<String?> getReadingInsight({
    required String bookTitle,
    required String userQuestion,
  }) async {
    try {
      String prompt = '''
You are discussing the book "$bookTitle" with a book club member.

User's question or comment: $userQuestion

Provide a thoughtful, insightful response that:
- Addresses their question directly
- Offers literary analysis or interpretation
- Encourages further discussion
- Remains respectful of different viewpoints
- Focuses on the book's content, themes, and plot

Keep your response conversational but informative.
''';

      return await getChatResponse(
        message: prompt,
        bookContext: bookTitle,
      );
    } catch (e) {
      print('Error getting reading insight: $e');
      return null;
    }
  }

  // Premium AI features for paid members
  Future<String?> getPersonalizedRecommendation({
    required List<String> readBooks,
    required List<String> favoriteGenres,
    required String readingGoals,
  }) async {
    try {
      String prompt = '''
Based on this reader's profile, provide a personalized book recommendation:

Books they've read: ${readBooks.join(', ')}
Favorite genres: ${favoriteGenres.join(', ')}
Reading goals: $readingGoals

Please suggest one specific book with:
1. Why it matches their preferences
2. How it aligns with their reading goals
3. What they might learn or gain from it
4. Any potential challenges or considerations

Make this recommendation feel personal and thoughtful.
''';

      return await getChatResponse(message: prompt);
    } catch (e) {
      print('Error getting personalized recommendation: $e');
      return null;
    }
  }
}
