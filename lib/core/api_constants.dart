class ApiConstants {
  // ✅ Nginx reverse proxy দিয়ে যাবে — port লাগবে না
  static const String baseUrl = "http://api.kothabook.com";

  // ─── Auth Endpoints ───
  static const String register = "$baseUrl/api/auth/register";
  static const String login    = "$baseUrl/api/auth/login";
}