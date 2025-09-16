import 'dart:io';
import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  String? name;
  DateTime? dob;
  String? gender;
  String? email;
  String? about;
  List<String> interests = [];
  List<String> disabilities = [];
  File? avatar;
  String? avatarUrl;

  int get age {
    if (dob == null) return 0;
    final today = DateTime.now();
    int age = today.year - dob!.year;
    if (today.month < dob!.month ||
        (today.month == dob!.month && today.day < dob!.day)) {
      age--;
    }
    return age;
  }

  int get profileCompletion {
    int total = 6;
    int filled = 0;
    if (name != null && name!.isNotEmpty) filled++;
    if (dob != null) filled++;
    if (gender != null && gender!.isNotEmpty) filled++;
    if (email != null && email!.isNotEmpty) filled++;
    if (interests.isNotEmpty) filled++;
    if (disabilities.isNotEmpty) filled++;
    return ((filled / total) * 100).toInt();
  }

  void setUser({
    String? name,
    DateTime? dob,
    String? gender,
    String? email,
    String? about,
    List<String>? interests,
    List<String>? disabilities,
    File? avatar,
    String? avatarUrl,
  }) {
    this.name = name ?? this.name;
    this.dob = dob ?? this.dob;
    this.gender = gender ?? this.gender;
    this.email = email ?? this.email;
    this.about = about ?? this.about;
    this.interests = interests ?? this.interests;
    this.disabilities = disabilities ?? this.disabilities;
    this.avatar = avatar ?? this.avatar;
    this.avatarUrl = avatarUrl ?? this.avatarUrl;
    notifyListeners();
  }

  void setAbout(String about) {
    this.about = about;
    notifyListeners();
  }

  void setAvatar(File file) {
    avatar = file;
    notifyListeners();
  }
}
