import 'package:flutter_test/flutter_test.dart';
import 'package:polyvault/models/message.dart';

void main() {
  group('Message Model Tests', () {
    test('should create message with required fields', () {
      final message = Message(
        id: '1',
        title: 'Test Message',
        content: 'This is a test message',
        type: MessageType.system,
        isRead: false,
      );

      expect(message.id, '1');
      expect(message.title, 'Test Message');
      expect(message.type, MessageType.system);
      expect(message.isRead, false);
    });

    test('should copy message with new values', () {
      final original = Message(
        id: '1',
        title: 'Original',
        content: 'Content',
        type: MessageType.system,
        isRead: false,
      );

      final copied = original.copyWith(isRead: true);
      
      expect(copied.id, original.id);
      expect(copied.title, original.title);
      expect(copied.isRead, true);
    });

    test('should have all message types', () {
      expect(MessageType.values.length, 7);
      expect(MessageType.values.contains(MessageType.system), true);
      expect(MessageType.values.contains(MessageType.security), true);
      expect(MessageType.values.contains(MessageType.device), true);
      expect(MessageType.values.contains(MessageType.credential), true);
      expect(MessageType.values.contains(MessageType.sync), true);
      expect(MessageType.values.contains(MessageType.backup), true);
      expect(MessageType.values.contains(MessageType.general), true);
    });
  });

  group('MessageService Tests', () {
    test('should get messages list', () async {
      final service = MessageService();
      final messages = await service.getMessages();
      
      expect(messages, isA<List<Message>>());
    });

    test('should get unread count', () async {
      final service = MessageService();
      final count = await service.getUnreadCount();
      
      expect(count, isA<int>());
      expect(count, greaterThanOrEqualTo(0));
    });

    test('should get message stats', () async {
      final service = MessageService();
      final stats = await service.getMessageStats();
      
      expect(stats, isA<MessageStats>());
      expect(stats.total, greaterThan(0));
    });

    test('should mark message as read', () async {
      final service = MessageService();
      final messages = await service.getMessages();
      
      if (messages.isNotEmpty) {
        final unreadMessage = messages.firstWhere((m) => !m.isRead, orElse: () => messages.first);
        await service.markAsRead(unreadMessage.id);
        
        final updatedMessages = await service.getMessages();
        final updated = updatedMessages.firstWhere((m) => m.id == unreadMessage.id);
        expect(updated.isRead, true);
      }
    });

    test('should mark all as read', () async {
      final service = MessageService();
      await service.markAllAsRead();
      
      final unreadCount = await service.getUnreadCount();
      expect(unreadCount, 0);
    });

    test('should delete message', () async {
      final service = MessageService();
      final messages = await service.getMessages();
      final initialCount = messages.length;
      
      if (messages.isNotEmpty) {
        await service.deleteMessage(messages.first.id);
        
        final updatedMessages = await service.getMessages();
        expect(updatedMessages.length, initialCount - 1);
      }
    });

    test('should send test message', () async {
      final service = MessageService();
      final messagesBefore = await service.getMessages();
      final countBefore = messagesBefore.length;
      
      await service.sendTestMessage();
      
      final messagesAfter = await service.getMessages();
      expect(messagesAfter.length, countBefore + 1);
    });
  });

  group('MessageStats Tests', () {
    test('should create stats', () {
      final stats = MessageStats(
        total: 10,
        unread: 3,
        system: 2,
        security: 1,
      );
      
      expect(stats.total, 10);
      expect(stats.unread, 3);
      expect(stats.system, 2);
      expect(stats.security, 1);
    });

    test('should calculate read count', () {
      final stats = MessageStats(
        total: 10,
        unread: 3,
        system: 2,
        security: 1,
      );
      
      expect(stats.read, 7);
    });
  });
}