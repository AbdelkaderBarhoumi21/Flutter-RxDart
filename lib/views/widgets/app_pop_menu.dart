import 'package:flutter/material.dart';
import 'package:flutter_rxdart/dialogs/delete_account_dialog.dart';
import 'package:flutter_rxdart/dialogs/logout_dialog.dart';
import 'package:flutter_rxdart/utils/type_def.dart';

enum MenuAction { logout, deleteAccount }

class AppPopMenu extends StatelessWidget {
  const AppPopMenu({
    required this.logout,
    required this.deleteAccount,
    super.key,
  });
  final LogoutCallback logout;
  final DeleteAccountCallback deleteAccount;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<MenuAction>(
      itemBuilder: (context) {
        //value  is the value returned once an item is selected 
        return [
          const PopupMenuItem<MenuAction>(
            value: MenuAction.logout,
            child: Text('Logout'),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem<MenuAction>(
            value: MenuAction.deleteAccount,
            child: Text('Delete Account'),
          ),
        ];
      },
      onSelected: (value) async {
        switch (value) {
          case MenuAction.logout:
            final shouldLogout = await showLogoutDialog(context);
            if (shouldLogout) {
              logout();
            }
            break;
          case MenuAction.deleteAccount:
            final shouldDeleteAccount = await showDeleteAccountDialog(context);
            if (shouldDeleteAccount) {
              deleteAccount();
            }
            break;
        }
      },
    );
  }
}
