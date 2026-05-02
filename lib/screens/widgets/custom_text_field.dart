import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class CustomTextField extends StatefulWidget {
  // 📝 ইনপুট বক্সের ভেতরে আবছা যে লেখা থাকে (Hint text)
  final String hintText;
  
  // ⌨️ ইউজারের টাইপ করা ডাটা ধরে রাখার কন্ট্রোলার
  final TextEditingController controller;
  
  // 🔒 এটা কি পাসওয়ার্ড বক্স? (True দিলে লেখাগুলো স্টার/ডট হয়ে যাবে)
  final bool isPassword;
  
  // 📱 কিবোর্ডের ধরন (ইমেইল, নাম্বার নাকি সাধারণ টেক্সট)
  final TextInputType keyboardType;
  
  // 🎨 ইনপুট বক্সের শুরুতে কোনো আইকন দেখাতে চাইলে
  final IconData? prefixIcon;

  const CustomTextField({
    super.key,
    required this.hintText,
    required this.controller,
    this.isPassword = false, // ডিফল্টভাবে এটা সাধারণ টেক্সট বক্স থাকবে
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  // 👁️ পাসওয়ার্ড দেখাবে নাকি লুকাবে, তার ট্র্যাক রাখার ভেরিয়েবল
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    // 🌙 ফোন ডার্ক মোডে আছে নাকি লাইট মোডে, সেটা চেক করা হচ্ছে
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      // 🔒 যদি পাসওয়ার্ড বক্স হয় এবং obscureText ট্রু হয়, তবেই লেখা লুকাবে
      obscureText: widget.isPassword ? _obscureText : false,
      
      // 🎨 লেখার কালার মোড অনুযায়ী অটোমেটিক চেঞ্জ হবে
      style: TextStyle(
        color: isDarkMode ? AppColors.darkText : AppColors.lightText,
      ),
      
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(
          color: isDarkMode ? AppColors.darkSubText : AppColors.lightSubText,
        ),
        
        // 🎨 বক্সের ব্যাকগ্রাউন্ড কালার (ডার্ক মোডে ডার্ক, লাইট মোডে সাদা)
        filled: true,
        fillColor: isDarkMode ? AppColors.darkCard : AppColors.lightCard,
        
        // 🎨 বক্সের শুরুর আইকন (যদি দেওয়া হয়)
        prefixIcon: widget.prefixIcon != null
            ? Icon(
                widget.prefixIcon,
                color: isDarkMode ? AppColors.darkSubText : AppColors.lightSubText,
              )
            : null,
            
        // 👁️ পাসওয়ার্ড বক্স হলে ডানদিকে চোখের আইকন দেখানোর লজিক
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: isDarkMode ? AppColors.darkSubText : AppColors.lightSubText,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText; // আইকনে ক্লিক করলে পাসওয়ার্ড দেখাবে/লুকাবে
                  });
                },
              )
            : null,
            
        // 🔲 নরমাল অবস্থায় বক্সের বর্ডার ডিজাইন
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.transparent : Colors.grey.shade300,
          ),
        ),
        
        // 🔲 যখন ইউজার বক্সে ক্লিক করে টাইপ করা শুরু করবে (Focused state)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primaryOrange, // ক্লিক করলে তোমার সিগনেচার অরেঞ্জ বর্ডার আসবে!
            width: 2,
          ),
        ),
      ),
    );
  }
}