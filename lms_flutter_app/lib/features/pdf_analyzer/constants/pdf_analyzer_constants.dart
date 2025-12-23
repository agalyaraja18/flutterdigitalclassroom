class PdfAnalyzerConstants {
  static const String baseUrl = 'http://0.0.0.0:5000/';
  static const String analyzerEndpoint = 'api/pdf-analyzer';
  
  // Timeouts
  static const int uploadTimeout = 300; // 5 minutes
  static const int queryTimeout = 60; // 1 minute
  
  // Polling intervals
  static const Duration statusPollingInterval = Duration(seconds: 3);
  static const Duration documentPollingInterval = Duration(seconds: 5);
}