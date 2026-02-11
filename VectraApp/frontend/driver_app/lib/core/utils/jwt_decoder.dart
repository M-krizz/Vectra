import 'dart:convert';

/// JWT decoder utility for extracting claims from tokens
class JwtDecoder {
  JwtDecoder._();

  /// Decode a JWT token and return its payload
  static Map<String, dynamic>? decode(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Extract user role from JWT token
  static String? extractRole(String token) {
    final payload = decode(token);
    if (payload == null) return null;

    // Try common claim names for role
    return payload['role'] as String? ??
        payload['user_role'] as String? ??
        payload['roles']?.first as String?;
  }

  /// Extract user ID from JWT token
  static String? extractUserId(String token) {
    final payload = decode(token);
    if (payload == null) return null;

    return payload['sub'] as String? ??
        payload['user_id'] as String? ??
        payload['id'] as String?;
  }

  /// Extract expiration timestamp from JWT token
  static DateTime? extractExpiration(String token) {
    final payload = decode(token);
    if (payload == null) return null;

    final exp = payload['exp'];
    if (exp == null) return null;

    if (exp is int) {
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    }
    return null;
  }

  /// Check if JWT token is expired
  static bool isExpired(String token) {
    final expiration = extractExpiration(token);
    if (expiration == null) return true;
    return DateTime.now().isAfter(expiration);
  }

  /// Check if JWT token will expire within given duration
  static bool willExpireSoon(String token, Duration within) {
    final expiration = extractExpiration(token);
    if (expiration == null) return true;
    return DateTime.now().add(within).isAfter(expiration);
  }

  /// Extract custom claim from JWT token
  static T? extractClaim<T>(String token, String claimName) {
    final payload = decode(token);
    if (payload == null) return null;
    return payload[claimName] as T?;
  }

  /// Validate token has required claims
  static bool hasRequiredClaims(
    String token,
    List<String> requiredClaims,
  ) {
    final payload = decode(token);
    if (payload == null) return false;

    for (final claim in requiredClaims) {
      if (!payload.containsKey(claim) || payload[claim] == null) {
        return false;
      }
    }
    return true;
  }
}

/// User role constants
class UserRoles {
  UserRoles._();

  static const String driver = 'DRIVER';
  static const String rider = 'RIDER';
  static const String admin = 'ADMIN';
}

/// Driver status constants
class DriverStatus {
  DriverStatus._();

  static const String online = 'ONLINE';
  static const String offline = 'OFFLINE';
  static const String busy = 'BUSY';
  static const String suspended = 'SUSPENDED';
}

/// Document verification status
class DocumentStatus {
  DocumentStatus._();

  static const String pending = 'PENDING';
  static const String verified = 'VERIFIED';
  static const String rejected = 'REJECTED';
  static const String expired = 'EXPIRED';
}
