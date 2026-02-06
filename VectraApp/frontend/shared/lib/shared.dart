/// Shared package for Vectra apps
/// Contains API client, models, constants, and utilities
library shared;

// Constants
export 'src/constants/api_constants.dart';
export 'src/constants/app_constants.dart';

// API Client
export 'src/api/api_client.dart';
export 'src/api/api_exceptions.dart';

// Models
export 'src/models/user_model.dart';
export 'src/models/auth_response_model.dart';
export 'src/models/api_response_model.dart';

// Services
export 'src/services/storage_service.dart';

// Socket
export 'src/socket/socket_service.dart';
