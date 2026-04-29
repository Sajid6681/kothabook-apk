class ApiConstants {
  // 🚀 ডোমেইন ব্যবহার করা হচ্ছে এবং পোর্ট ৮০৮০ যা ক্লাউডফ্লেয়ার সাপোর্ট করে
  static const String baseUrl = "http://api.kothabook.com:8080"; 

  // ─── Auth Endpoints ───
  static const String register = "$baseUrl/api/auth/register";
  static const String login = "$baseUrl/api/auth/login";
}