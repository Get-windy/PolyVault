import 'package:flutter_test/flutter_test.dart';
import 'package:polyvault/models/models.dart';

void main() {
  group('Credential Model Tests', () {
    test('Credential can be created from JSON', () {
      final json = {
        'id': 'test-id',
        'serviceName': 'GitHub',
        'username': 'testuser',
        'password': 'password123',
        'notes': 'Test note',
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-01-01T00:00:00.000Z',
      };

      final credential = Credential.fromJson(json);

      expect(credential.id, 'test-id');
      expect(credential.serviceName, 'GitHub');
      expect(credential.username, 'testuser');
      expect(credential.password, 'password123');
      expect(credential.notes, 'Test note');
    });

    test('Credential can be converted to JSON', () {
      final credential = Credential(
        id: 'test-id',
        serviceName: 'GitHub',
        username: 'testuser',
        password: 'password123',
        notes: 'Test note',
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      );

      final json = credential.toJson();

      expect(json['id'], 'test-id');
      expect(json['serviceName'], 'GitHub');
      expect(json['username'], 'testuser');
      expect(json['password'], 'password123');
      expect(json['notes'], 'Test note');
    });

    test('Credential copyWith works correctly', () {
      final credential = Credential(
        id: 'test-id',
        serviceName: 'GitHub',
        username: 'testuser',
        password: 'password123',
        notes: 'Test note',
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      );

      final updated = credential.copyWith(
        serviceName: 'GitLab',
        password: 'newpassword',
      );

      expect(updated.id, 'test-id');
      expect(updated.serviceName, 'GitLab');
      expect(updated.password, 'newpassword');
      expect(updated.username, 'testuser');
    });
  });

  group('CredentialSummary Model Tests', () {
    test('CredentialSummary can be created from JSON', () {
      final json = {
        'id': 'test-id',
        'serviceName': 'GitHub',
        'username': 'testuser',
        'createdAt': '2024-01-01T00:00:00.000Z',
      };

      final summary = CredentialSummary.fromJson(json);

      expect(summary.id, 'test-id');
      expect(summary.serviceName, 'GitHub');
      expect(summary.username, 'testuser');
    });
  });

  group('Device Model Tests', () {
    test('Device can be created from JSON', () {
      final json = {
        'id': 'device-1',
        'name': 'My Phone',
        'platform': 'Android',
        'status': 'online',
        'lastConnected': '2024-01-01T00:00:00.000Z',
        'ipAddress': '192.168.1.100',
        'isTrusted': true,
      };

      final device = Device.fromJson(json);

      expect(device.id, 'device-1');
      expect(device.name, 'My Phone');
      expect(device.platform, 'Android');
      expect(device.status, DeviceStatus.online);
      expect(device.isTrusted, true);
    });

    test('Device can be converted to JSON', () {
      final device = Device(
        id: 'device-1',
        name: 'My Phone',
        platform: 'Android',
        status: DeviceStatus.online,
        lastConnected: DateTime.parse('2024-01-01T00:00:00.000Z'),
        ipAddress: '192.168.1.100',
        isTrusted: true,
      );

      final json = device.toJson();

      expect(json['id'], 'device-1');
      expect(json['name'], 'My Phone');
      expect(json['platform'], 'Android');
      expect(json['status'], 'online');
      expect(json['isTrusted'], true);
    });

    test('DeviceStatus enum works correctly', () {
      expect(DeviceStatus.values.length, 4);
      expect(DeviceStatus.values.contains(DeviceStatus.online), true);
      expect(DeviceStatus.values.contains(DeviceStatus.offline), true);
      expect(DeviceStatus.values.contains(DeviceStatus.connecting), true);
      expect(DeviceStatus.values.contains(DeviceStatus.error), true);
    });
  });

  group('StorageStats Model Tests', () {
    test('StorageStats can be created from JSON', () {
      final json = {
        'totalCredentials': 10,
        'lastBackup': '2024-01-01T00:00:00.000Z',
      };

      final stats = StorageStats.fromJson(json);

      expect(stats.totalCredentials, 10);
      expect(stats.lastBackup, isNotNull);
    });

    test('StorageStats handles null lastBackup', () {
      final json = {
        'totalCredentials': 5,
      };

      final stats = StorageStats.fromJson(json);

      expect(stats.totalCredentials, 5);
      expect(stats.lastBackup, isNull);
    });
  });

  group('ConnectionStatus Model Tests', () {
    test('ConnectionStatus disconnected factory works', () {
      final status = ConnectionStatus.disconnected();

      expect(status.isConnected, false);
      expect(status.serverUrl, isNull);
      expect(status.errorMessage, isNull);
    });

    test('ConnectionStatus can be created from JSON', () {
      final json = {
        'isConnected': true,
        'serverUrl': 'http://localhost:3001',
        'lastConnected': '2024-01-01T00:00:00.000Z',
      };

      final status = ConnectionStatus.fromJson(json);

      expect(status.isConnected, true);
      expect(status.serverUrl, 'http://localhost:3001');
      expect(status.lastConnected, isNotNull);
    });
  });

  group('UserSession Model Tests', () {
    test('UserSession can be created from JSON', () {
      final json = {
        'token': 'test-token-123',
        'userId': 'user-1',
        'expiresAt': '2024-12-31T23:59:59.000Z',
      };

      final session = UserSession.fromJson(json);

      expect(session.token, 'test-token-123');
      expect(session.userId, 'user-1');
      expect(session.isExpired, false);
    });

    test('UserSession isExpired works correctly', () {
      final expiredSession = UserSession(
        token: 'test-token',
        userId: 'user-1',
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      final validSession = UserSession(
        token: 'test-token',
        userId: 'user-1',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(expiredSession.isExpired, true);
      expect(validSession.isExpired, false);
    });
  });

  group('ApiResponse Model Tests', () {
    test('ApiResponse success factory works', () {
      final response = ApiResponse.success('test-data', message: 'Success!');

      expect(response.success, true);
      expect(response.data, 'test-data');
      expect(response.message, 'Success!');
      expect(response.error, isNull);
    });

    test('ApiResponse error factory works', () {
      final response = ApiResponse<String>.error('Error occurred');

      expect(response.success, false);
      expect(response.error, 'Error occurred');
      expect(response.data, isNull);
    });
  });
}