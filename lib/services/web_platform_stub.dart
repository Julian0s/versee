/// Mobile platform stubs for web-specific dart:html classes
/// Provides empty implementations to prevent compilation errors

// File operations
class File {
  final String name;
  final int size;
  final String type;
  
  File(List<dynamic> parts, this.name, [Map<String, String>? options]) 
    : size = 0, type = options?['type'] ?? '';
}

class FileList {
  int get length => 0;
  File? item(int index) => null;
  List<File> toList() => [];
}

class FileUploadInputElement {
  bool multiple = false;
  String accept = '';
  FileList? files;
  Stream<dynamic> get onChange => Stream.empty();
  void click() {}
}

class FileReader {
  String? result;
  dynamic result2; // for ArrayBuffer results
  Stream<dynamic> get onLoad => Stream.empty();
  Stream<dynamic> get onError => Stream.empty();
  void readAsDataURL(dynamic file) {}
  void readAsArrayBuffer(dynamic file) {}
}

// Canvas operations
class CanvasElement {
  int width = 0;
  int height = 0;
  String toDataUrl([String? type, dynamic quality]) => '';
  CanvasRenderingContext2D getContext(String contextType) => CanvasRenderingContext2D();
}

class CanvasRenderingContext2D {
  void drawImage(dynamic image, int x, int y, [int? width, int? height]) {}
}

class ImageElement {
  String src = '';
  int naturalWidth = 0;
  int naturalHeight = 0;
  Stream<dynamic> get onLoad => Stream.empty();
  Stream<dynamic> get onError => Stream.empty();
}

// Video element for media processing
class VideoElement {
  String src = '';
  int videoWidth = 0;
  int videoHeight = 0;
  double duration = 0.0;
  Stream<dynamic> get onLoadedMetadata => Stream.empty();
}

// Network operations
class HttpRequest {
  String responseType = '';
  dynamic response;
  int status = 200;
  String responseText = '';
  Stream<dynamic> get onLoad => Stream.empty();
  Stream<dynamic> get onReadyStateChange => Stream.empty();
  void open(String method, String url) {}
  void send([dynamic data]) {}
}

class Blob {
  Blob(List<dynamic> parts, [Map<String, dynamic>? options]);
}

// URL utilities
class Url {
  static String createObjectUrl(dynamic blob) => '';
  static void revokeObjectUrl(String url) {}
}

// IndexedDB stubs
class Database {
  Transaction transaction(List<String> storeNames, String mode) => Transaction();
  bool get closed => false;
  void close() {}
}

class Transaction {
  ObjectStore objectStore(String name) => ObjectStore();
  Stream<dynamic> get onComplete => Stream.empty();
  Stream<dynamic> get onError => Stream.empty();
}

class ObjectStore {
  Request put(dynamic value, [dynamic key]) => Request();
  Request get(dynamic key) => Request();
  Request delete(dynamic key) => Request();
  Request clear() => Request();
  Index createIndex(String name, dynamic keyPath, [Map<String, dynamic>? options]) => Index();
  Index index(String name) => Index();
}

class Index {
  Request openCursor({dynamic range, String? direction}) => Request();
}

class Request {
  dynamic result;
  dynamic target;
  String? error;
  Stream<dynamic> get onSuccess => Stream.empty();
  Stream<dynamic> get onError => Stream.empty();
}

class VersionChangeEvent {
  Request get target => Request();
}

class KeyRange {
  static KeyRange upperBound(dynamic bound) => KeyRange();
}

// Navigator and storage
class Navigator {
  bool get onLine => true;
  Storage? get storage => Storage();
  dynamic get indexedDB => null;
  String get userAgent => 'Mobile App';
  dynamic get serviceWorker => null;
}

class Storage {
  Future<Map<String, dynamic>> estimate() async => {'quota': 0, 'usage': 0};
}

class LocalStorage {
  String? operator [](String key) => null;
  void operator []=(String key, String value) {}
  void removeItem(String key) {}
}

// Window and document
class Window {
  final Navigator navigator = Navigator();
  LocalStorage get localStorage => LocalStorage();
  dynamic get indexedDB => null;
  Future<dynamic> fetch(String url) async => throw UnsupportedError('Fetch not supported on mobile');
  void addEventListener(String type, dynamic listener) {}
  dynamic open(String url, String name, String features) => null;
  Location get location => Location();
}

class Document {
  CanvasElement createElement(String tag) {
    switch (tag) {
      case 'canvas':
        return CanvasElement();
      default:
        throw UnsupportedError('Element $tag not supported');
    }
  }
}

class Location {
  String get href => '/';
  String get origin => '';
  String get pathname => '/';
}

// Global objects
final window = Window();
final document = Document();

// Constructor functions are handled by the classes themselves