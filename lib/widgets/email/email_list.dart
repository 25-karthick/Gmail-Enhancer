import 'package:flutter/material.dart';
import 'email_card.dart';
import '../../models/email_model.dart';

class EmailList extends StatelessWidget {
  final List<Email> emails;

  const EmailList({super.key, required this.emails});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: emails.length,
      itemBuilder: (context, index) {
        final email = emails[index];
        return EmailCard(email: email);
      },
    );
  }
}