// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:provider/provider.dart';
// import '../user_provider.dart';
// import 'disability_page.dart';
//
// class ProfilePage extends StatefulWidget {
//   const ProfilePage({super.key});
//
//   @override
//   State<ProfilePage> createState() => _ProfilePageState();
// }
//
// class _ProfilePageState extends State<ProfilePage> {
//   final nameController = TextEditingController();
//   DateTime? selectedDate;
//   String? gender;
//   File? _avatar;
//
//   Future<void> _pickDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime(2000, 1, 1),
//       firstDate: DateTime(1900),
//       lastDate: DateTime.now(),
//     );
//     if (picked != null) {
//       setState(() {
//         selectedDate = picked;
//       });
//     }
//   }
//
//   Future<void> _pickImage() async {
//     final ImagePicker picker = ImagePicker();
//     final XFile? pickedFile =
//     await picker.pickImage(source: ImageSource.gallery);
//
//     if (pickedFile != null) {
//       setState(() {
//         _avatar = File(pickedFile.path);
//       });
//       context.read<UserProvider>().setAvatar(pickedFile.path);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFE6F3FA),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFFE6F3FA),
//         elevation: 0,
//         title: const Text("Add Profile Details",
//             style: TextStyle(color: Colors.black)),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           children: [
//             GestureDetector(
//               onTap: _pickImage,
//               child: CircleAvatar(
//                 radius: 50,
//                 backgroundImage: _avatar != null
//                     ? FileImage(_avatar!)
//                     : const AssetImage("assets/avatar.png") as ImageProvider,
//                 child: Align(
//                   alignment: Alignment.bottomRight,
//                   child: Container(
//                     decoration: const BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: Colors.white,
//                     ),
//                     padding: const EdgeInsets.all(4),
//                     child: const Icon(Icons.edit,
//                         size: 20, color: Colors.black),
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//
//             TextField(
//               controller: nameController,
//               decoration: const InputDecoration(labelText: "Name"),
//             ),
//             const SizedBox(height: 20),
//
//             // Date of Birth picker
//             GestureDetector(
//               onTap: () => _pickDate(context),
//               child: AbsorbPointer(
//                 child: TextFormField(
//                   decoration: const InputDecoration(
//                     labelText: "Date of Birth",
//                     suffixIcon: Icon(Icons.calendar_today),
//                   ),
//                   controller: TextEditingController(
//                     text: selectedDate == null
//                         ? ""
//                         : "${selectedDate!.day.toString().padLeft(2, '0')}/"
//                         "${selectedDate!.month.toString().padLeft(2, '0')}/"
//                         "${selectedDate!.year}",
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//
//             DropdownButtonFormField<String>(
//               value: gender,
//               hint: const Text("Select Gender"),
//               items: ["Male", "Female", "Other"]
//                   .map((g) => DropdownMenuItem(value: g, child: Text(g)))
//                   .toList(),
//               onChanged: (val) => setState(() => gender = val),
//             ),
//             const Spacer(),
//
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.black,
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(30)),
//                 padding:
//                 const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
//               ),
//               onPressed: () {
//                 context.read<UserProvider>().setProfile(
//                   nameController.text,
//                   selectedDate == null
//                       ? ""
//                       : "${selectedDate!.toLocal()}".split(' ')[0],
//                   gender ?? "",
//                 );
//                 Navigator.push(context,
//                     MaterialPageRoute(builder: (_) => const DisabilityPage()));
//               },
//               child: const Text("Next →"),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
