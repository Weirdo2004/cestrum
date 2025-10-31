// A simple data class to hold all the signup info
import 'dart:io';

class SignUpData {
  String email = '';
  String password = ''; // From previous step
  String name = '';
  String nickname = '';
  int age = 18;
  String gender = '';
  bool showAge = true;
  Set<String> purpose = {'friends'}; // 'friends' or 'date'
  bool agreedToTerms = false;
  File? photoFile;
}
