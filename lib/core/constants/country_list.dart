// 🌍 বিশ্বের সব দেশের ডাটা মডেল
class CountryModel {
  final String name;
  final String code;
  final String flag;
  final String isoCode;

  CountryModel({required this.name, required this.code, required this.flag, required this.isoCode});
}

class AppConstants {
  // 🌍 গ্লোবাল কান্ট্রি লিস্ট (বিশ্বের প্রায় সব বড় দেশ)
  static List<CountryModel> countries = [
    CountryModel(name: 'Bangladesh', code: '+880', flag: '🇧🇩', isoCode: 'BD'),
    CountryModel(name: 'India', code: '+91', flag: '🇮🇳', isoCode: 'IN'),
    CountryModel(name: 'Pakistan', code: '+92', flag: '🇵🇰', isoCode: 'PK'),
    CountryModel(name: 'United States', code: '+1', flag: '🇺🇸', isoCode: 'US'),
    CountryModel(name: 'United Kingdom', code: '+44', flag: '🇬🇧', isoCode: 'GB'),
    CountryModel(name: 'Canada', code: '+1', flag: '🇨🇦', isoCode: 'CA'),
    CountryModel(name: 'Australia', code: '+61', flag: '🇦🇺', isoCode: 'AU'),
    CountryModel(name: 'Saudi Arabia', code: '+966', flag: '🇸🇦', isoCode: 'SA'),
    CountryModel(name: 'United Arab Emirates', code: '+971', flag: '🇦🇪', isoCode: 'AE'),
    CountryModel(name: 'Qatar', code: '+974', flag: '🇶🇦', isoCode: 'QA'),
    CountryModel(name: 'Oman', code: '+965', flag: '🇴🇲', isoCode: 'OM'),
    CountryModel(name: 'Kuwait', code: '+965', flag: '🇰🇼', isoCode: 'KW'),
    CountryModel(name: 'Bahrain', code: '+973', flag: '🇧🇭', isoCode: 'BH'),
    CountryModel(name: 'Malaysia', code: '+60', flag: '🇲🇾', isoCode: 'MY'),
    CountryModel(name: 'Singapore', code: '+65', flag: '🇸🇬', isoCode: 'SG'),
    CountryModel(name: 'Indonesia', code: '+62', flag: '🇮🇩', isoCode: 'ID'),
    CountryModel(name: 'Maldives', code: '+960', flag: '🇲🇻', isoCode: 'MV'),
    CountryModel(name: 'Italy', code: '+39', flag: '🇮🇹', isoCode: 'IT'),
    CountryModel(name: 'France', code: '+33', flag: '🇫🇷', isoCode: 'FR'),
    CountryModel(name: 'Germany', code: '+33', flag: '🇩🇪', isoCode: 'DE'),
    CountryModel(name: 'Spain', code: '+34', flag: '🇪🇸', isoCode: 'ES'),
    CountryModel(name: 'Portugal', code: '+351', flag: '🇵🇹', isoCode: 'PT'),
    CountryModel(name: 'South Africa', code: '+27', flag: '🇿🇦', isoCode: 'ZA'),
    CountryModel(name: 'Egypt', code: '+20', flag: '🇪🇬', isoCode: 'EG'),
    CountryModel(name: 'Turkey', code: '+20', flag: '🇹🇷', isoCode: 'TR'),
    CountryModel(name: 'Japan', code: '+81', flag: '🇯🇵', isoCode: 'JP'),
    CountryModel(name: 'South Korea', code: '+82', flag: '🇰🇷', isoCode: 'KR'),
    CountryModel(name: 'China', code: '+86', flag: '🇨🇳', isoCode: 'CN'),
    CountryModel(name: 'Brazil', code: '+55', flag: '🇧🇷', isoCode: 'BR'),
    CountryModel(name: 'Argentina', code: '+54', flag: '🇦🇷', isoCode: 'AR'),
    CountryModel(name: 'Mexico', code: '+52', flag: '🇲🇽', isoCode: 'MX'),
    CountryModel(name: 'Russia', code: '+86', flag: '🇷🇺', isoCode: 'RU'),
    // তুমি চাইলে এখানে আরও দেশ যুক্ত করতে পারবে
  ];
}