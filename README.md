# Offline Posts Manager — Lab 5

A Flutter app that manages posts locally using SQLite, demonstrating CRUD operations and stateful UI updates.

---

## Project Structure

```
lib/
├── main.dart                          # App entry point & theme
├── models/
│   └── post.dart                      # Post data model
├── database/
│   └── database_helper.dart           # SQLite helper (CRUD + error handling)
└── screens/
    ├── posts_list_screen.dart          # Screen 1: View all posts
    ├── post_detail_screen.dart         # Screen 2: View single post
    └── post_form_screen.dart           # Screen 3: Add / Edit post
```

---

## Getting Started

```bash
flutter pub get
flutter run
```

---

## Discussion Answers (for the handwritten section)

---

### 1. Dependencies Used and Why

| Package | Version | Purpose |
|---------|---------|---------|
| `sqflite` | ^2.3.0 | SQLite database plugin for Flutter (iOS & Android) |
| `path` | ^1.9.0 | Constructs the correct file-system path to the database file |

**Why SQLite?**
- SQLite is a lightweight, embedded relational database — it runs entirely on the device without any server or internet connection.
- Perfect for an **Offline Posts Manager** because data persists across app restarts even without network.
- `sqflite` is the standard Flutter plugin that wraps the native SQLite engine on both Android and iOS.
- Unlike SharedPreferences (key-value only), SQLite supports **structured queries**, **filtering**, **sorting**, and **joins** — making it ideal for managing a collection of posts.

---

### 2. Database Exception Handling

Three categories of exceptions are handled in `database_helper.dart`:

#### a) Database Not Initialised
```dart
Future<Database> get database async {
  if (_database != null) return _database!;
  _database = await _initDatabase();  // Lazy initialisation
  return _database!;
}
```
The singleton pattern ensures the database is only opened once. If `_initDatabase()` fails, it throws a descriptive `Exception('Failed to initialise database: ...')` that surfaces in the UI.

#### b) Insert / Update / Delete Errors
Every write operation is wrapped in a `try-catch` that catches `DatabaseException` (sqflite-specific) and generic `Exception`:
```dart
try {
  return await db.insert(_tableName, post.toMap(), ...);
} on DatabaseException catch (e) {
  throw Exception('Insert failed — ${e.result ?? e.toString()}');
} catch (e) {
  throw Exception('Unexpected error during insert: $e');
}
```

#### c) Invalid or Corrupted Data
- The `Post.fromMap()` factory uses explicit casts (`as String`, `as int?`) — if the schema is corrupted, a `TypeError` is thrown and caught upstream.
- Forms validate input **before** it ever reaches the database (empty fields, minimum lengths).
- `conflictAlgorithm: ConflictAlgorithm.replace` on insert prevents constraint violations from crashing the app.

---

### 3. SQLite in Flutter

#### Database vs Table
- A **database** is a single `.db` file stored on the device (e.g., `posts_manager.db`). It's the container.
- A **table** is a structured grid inside the database, like a spreadsheet. Our app has one table: `posts`, with columns: `id`, `title`, `body`, `author`, `createdAt`.

#### CRUD Operations

| Operation | SQL | sqflite Method |
|-----------|-----|----------------|
| Create    | `INSERT INTO posts ...` | `db.insert()` |
| Read all  | `SELECT * FROM posts ORDER BY id DESC` | `db.query()` |
| Read one  | `SELECT * FROM posts WHERE id = ?` | `db.query(where: ...)` |
| Update    | `UPDATE posts SET ... WHERE id = ?` | `db.update()` |
| Delete    | `DELETE FROM posts WHERE id = ?` | `db.delete()` |

#### How Flutter Interacts with the Database Asynchronously
- All SQLite operations are **I/O bound** (reading/writing to disk).
- `sqflite` exposes every method as a `Future` — Flutter's mechanism for asynchronous operations.
- We use `async/await` so the **UI thread is never blocked**:
  ```dart
  Future<List<Post>> getAllPosts() async {
    final db = await database;        // Wait for DB to be ready
    final maps = await db.query(...); // Wait for query result
    return maps.map((m) => Post.fromMap(m)).toList();
  }
  ```
- In the UI, `setState()` is called after the async operation completes to trigger a rebuild, keeping the interface responsive throughout.