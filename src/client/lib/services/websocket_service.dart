import 'dart:async';
import 'dart:convert';

/// WebSocket消息类型
enum WebSocketMessageType {
  message,
  typing,
  read,
  delivered,
  error,
}

/// WebSocket消息
class WebSocketMessage {
  final String id;
  final WebSocketMessageType type;
  final String content;
  final String? senderId;
  final String? receiverId;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  WebSocketMessage({
    required this.id,
    required this.type,
    required this.content,
    this.senderId,
    this.receiverId,
    DateTime? timestamp,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      id: json['id'] as String,
      type: WebSocketMessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => WebSocketMessageType.message,
      ),
      content: json['content'] as String,
      senderId: json['senderId'] as String?,
      receiverId: json['receiverId'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'content': content,
      'senderId': senderId,
      'receiverId': receiverId,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// WebSocket连接状态
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// WebSocket服务
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocket? _socket;
  String? _baseUrl;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  
  final _messageController = StreamController<WebSocketMessage>.broadcast();
  final _connectionController = StreamController<ConnectionState>.broadcast();
  
  ConnectionState _state = ConnectionState.disconnected;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  // Getters
  Stream<WebSocketMessage> get messages => _messageController.stream;
  Stream<ConnectionState> get connectionState => _connectionController.stream;
  ConnectionState get state => _state;
  bool get isConnected => _state == ConnectionState.connected;

  /// 初始化WebSocket连接
  Future<void> connect(String baseUrl) async {
    _baseUrl = baseUrl;
    await _doConnect();
  }

  Future<void> _doConnect() async {
    if (_baseUrl == null) return;
    
    _updateState(ConnectionState.connecting);
    
    try {
      _socket = WebSocket(_baseUrl!);
      
      _socket!.onOpen = () {
        _updateState(ConnectionState.connected);
        _reconnectAttempts = 0;
        _startHeartbeat();
        _listenToMessages();
      };
      
      _socket!.onClose = (code, reason) {
        _stopHeartbeat();
        _updateState(ConnectionState.disconnected);
        _scheduleReconnect();
      };
      
      _socket!.onError = (error) {
        _updateState(ConnectionState.error);
        _scheduleReconnect();
      };
      
      _socket!.onMessage = (data) {
        _handleMessage(data);
      };
    } catch (e) {
      _updateState(ConnectionState.error);
      _scheduleReconnect();
    }
  }

  void _listenToMessages() {
    // Handled by onMessage callback
  }

  void _handleMessage(String data) {
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      final message = WebSocketMessage.fromJson(json);
      _messageController.add(message);
    } catch (e) {
      // Handle parse error
    }
  }

  void _updateState(ConnectionState newState) {
    _state = newState;
    _connectionController.add(newState);
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      send(WebSocketMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: WebSocketMessageType.message,
        content: 'ping',
      ));
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _updateState(ConnectionState.error);
      return;
    }
    
    _updateState(ConnectionState.reconnecting);
    _reconnectAttempts++;
    
    final delay = Duration(seconds: _reconnectAttempts * 2);
    _reconnectTimer = Timer(delay, () => _doConnect());
  }

  /// 发送消息
  void send(WebSocketMessage message) {
    if (_socket?.readyState == WebSocket.open) {
      _socket!.add(jsonEncode(message.toJson()));
    }
  }

  /// 发送文本消息
  void sendText(String content, {String? receiverId}) {
    send(WebSocketMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: WebSocketMessageType.message,
      content: content,
      receiverId: receiverId,
    ));
  }

  /// 发送正在输入状态
  void sendTyping(String? receiverId) {
    send(WebSocketMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: WebSocketMessageType.typing,
      content: '',
      receiverId: receiverId,
    ));
  }

  /// 发送已读回执
  void sendReadReceipt(String messageId, String? senderId) {
    send(WebSocketMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: WebSocketMessageType.read,
      content: messageId,
      senderId: senderId,
    ));
  }

  /// 断开连接
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _stopHeartbeat();
    await _socket?.close();
    _updateState(ConnectionState.disconnected);
  }

  /// 释放资源
  void dispose() {
    disconnect();
    _messageController.close();
    _connectionController.close();
  }
}