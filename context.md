# Audiobook App API Documentation

## Base URL

```
http://localhost:3000/api
```

## Authentication

All protected routes require a JWT token in the Authorization header:

```dart
headers: {
  'Authorization': 'Bearer YOUR_JWT_TOKEN',
  'Content-Type': 'application/json',
}
```

## Endpoints

### Authentication

#### Register User

- **POST** `/auth/register`

```dart
final response = await http.post(
  Uri.parse('${baseUrl}/auth/register'),
  body: json.encode({
    'username': 'user123',
    'email': 'user@example.com',
    'password': 'password123'
  }),
  headers: {'Content-Type': 'application/json'},
);
```

#### Login

- **POST** `/auth/login`

```dart
final response = await http.post(
  Uri.parse('${baseUrl}/auth/login'),
  body: json.encode({
    'email': 'user@example.com',
    'password': 'password123'
  }),
  headers: {'Content-Type': 'application/json'},
);
```

### Audiobooks

#### Get All Audiobooks

- **GET** `/audiobooks`

```dart
final response = await http.get(
  Uri.parse('${baseUrl}/audiobooks'),
  headers: {'Authorization': 'Bearer $token'},
);
```

#### Get Single Audiobook

- **GET** `/audiobooks/:id`

```dart
final response = await http.get(
  Uri.parse('${baseUrl}/audiobooks/$id'),
  headers: {'Authorization': 'Bearer $token'},
);
```

#### Create Audiobook (Admin only)

- **POST** `/audiobooks`

```dart
final request = http.MultipartRequest(
  'POST',
  Uri.parse('${baseUrl}/audiobooks'),
);
request.fields['title'] = 'Book Title';
request.fields['author'] = 'Author Name';
request.fields['description'] = 'Book description';
request.fields['duration'] = '3600'; // in seconds
request.files.add(await http.MultipartFile.fromPath(
  'audioFile',
  audioFilePath,
));
request.files.add(await http.MultipartFile.fromPath(
  'coverImage',
  coverImagePath,
));
request.headers['Authorization'] = 'Bearer $token';
final response = await request.send();
```

### User Library

#### Get User's Library

- **GET** `/library`

```dart
final response = await http.get(
  Uri.parse('${baseUrl}/library'),
  headers: {'Authorization': 'Bearer $token'},
);
```

#### Add to Library

- **POST** `/library/:audiobookId`

```dart
final response = await http.post(
  Uri.parse('${baseUrl}/library/$audiobookId'),
  headers: {'Authorization': 'Bearer $token'},
);
```

#### Remove from Library

- **DELETE** `/library/:audiobookId`

```dart
final response = await http.delete(
  Uri.parse('${baseUrl}/library/$audiobookId'),
  headers: {'Authorization': 'Bearer $token'},
);
```

### Progress Tracking

#### Update Progress

- **POST** `/progress/:audiobookId`

```dart
final response = await http.post(
  Uri.parse('${baseUrl}/progress/$audiobookId'),
  body: json.encode({
    'currentPosition': 120, // position in seconds
    'completed': false
  }),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json'
  },
);
```

#### Get Progress

- **GET** `/progress/:audiobookId`

```dart
final response = await http.get(
  Uri.parse('${baseUrl}/progress/$audiobookId'),
  headers: {'Authorization': 'Bearer $token'},
);
```

## Flutter Implementation Tips

1. Create an API service class:

```dart
class ApiService {
  final String baseUrl = 'http://localhost:3000/api';
  String? token;

  Future<void> login(String email, String password) async {
    // Implementation
  }

  Future<List<Audiobook>> getAudiobooks() async {
    // Implementation
  }

  // Other methods...
}
```

2. Use a state management solution (e.g., Provider, Riverpod, or GetX) to manage the API service and authentication state.

3. Create models for your data:

```dart
class Audiobook {
  final int id;
  final String title;
  final String author;
  final String coverUrl;
  // Other properties...

  Audiobook.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      title = json['title'],
      author = json['author'],
      coverUrl = json['coverUrl'];
}
```

4. Handle errors appropriately:

```dart
try {
  final response = await apiService.someApiCall();
  // Handle success
} on DioError catch (e) {
  // Handle network errors
} catch (e) {
  // Handle other errors
}
```
