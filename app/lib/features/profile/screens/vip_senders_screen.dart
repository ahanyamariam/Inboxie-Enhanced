import 'package:flutter/material.dart';
import 'package:app/core/theme/app_colors.dart';
import 'package:app/services/storage_service.dart';
import 'package:app/features/profile/widgets/sender_list_tile.dart';

class VipSendersScreen extends StatefulWidget {
  const VipSendersScreen({super.key});

  @override
  State<VipSendersScreen> createState() => _VipSendersScreenState();
}

class _VipSendersScreenState extends State<VipSendersScreen> {
  final StorageService _storage = StorageService();
  final TextEditingController _emailController = TextEditingController();
  
  List<String> _vipSenders = [];

  @override
  void initState() {
    super.initState();
    _loadVipSenders();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _loadVipSenders() {
    setState(() {
      _vipSenders = _storage.getVipSenders();
    });
  }

  Future<void> _addVipSender() async {
    final email = _emailController.text.trim().toLowerCase();
    
    if (email.isEmpty) {
      _showError('Please enter an email address');
      return;
    }
    
    if (!_isValidEmail(email)) {
      _showError('Please enter a valid email address');
      return;
    }
    
    if (_vipSenders.contains(email)) {
      _showError('This sender is already in your VIP list');
      return;
    }

    await _storage.addVipSender(email);
    _emailController.clear();
    _loadVipSenders();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $email to VIP senders'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.green[600],
        ),
      );
    }
  }

  Future<void> _removeVipSender(String email) async {
    await _storage.removeVipSender(email);
    _loadVipSenders();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed $email from VIP senders'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: 'Undo',
            textColor: AppColors.accentYellow,
            onPressed: () async {
              await _storage.addVipSender(email);
              _loadVipSenders();
            },
          ),
        ),
      );
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.red[600],
      ),
    );
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.getSurface(context),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              const Text(
                'Add VIP Sender',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Emails from VIP senders will always be marked as important.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.getTextSecondary(context),
                ),
              ),
              const SizedBox(height: 20),
              
              TextField(
                controller: _emailController,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  Navigator.pop(context);
                  _addVipSender();
                },
                decoration: InputDecoration(
                  hintText: 'email@example.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: Colors.grey.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.primaryBlue,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _addVipSender();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Add VIP Sender',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'VIP Senders',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: _vipSenders.isEmpty
          ? _buildEmptyState()
          : _buildSendersList(),
      floatingActionButton: _vipSenders.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showAddDialog,
              backgroundColor: AppColors.primaryBlue,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.accentYellow.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.star_rounded,
                size: 48,
                color: AppColors.accentYellow,
              ),
            ),
            const SizedBox(height: 24),
            
            const Text(
              'No VIP Senders Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add important contacts as VIP senders. Their emails will always be prioritized.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            
            ElevatedButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add VIP Sender'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _vipSenders.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${_vipSenders.length} VIP sender${_vipSenders.length == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }
        
        final email = _vipSenders[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SenderListTile(
            email: email,
            isVip: true,
            onRemove: () => _removeVipSender(email),
          ),
        );
      },
    );
  }
}