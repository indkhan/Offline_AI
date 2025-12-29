// settings_screen.dart
// Settings screen for configuring generation parameters
// Includes max tokens, temperature, and top_p controls

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int _maxTokens;
  late double _temperature;
  late double _topP;

  @override
  void initState() {
    super.initState();
    final chatProvider = context.read<ChatProvider>();
    _maxTokens = chatProvider.maxTokens;
    _temperature = chatProvider.temperature;
    _topP = chatProvider.topP;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: 'Appearance',
            children: [
              _buildThemeSelector(),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Generation Settings',
            children: [
              _buildMaxTokensSetting(),
              const Divider(),
              _buildTemperatureSetting(),
              const Divider(),
              _buildTopPSetting(),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'About',
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Offline LLM Chat'),
                subtitle: const Text('Version 1.0.0'),
              ),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('Powered by llama.cpp'),
                subtitle: const Text('Local inference engine'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildMaxTokensSetting() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Max Tokens',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                '$_maxTokens',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Maximum number of tokens to generate',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _maxTokens.toDouble(),
            min: 64,
            max: 2048,
            divisions: 31,
            label: '$_maxTokens',
            onChanged: (value) {
              setState(() {
                _maxTokens = value.round();
              });
              context.read<ChatProvider>().updateSettings(maxTokens: _maxTokens);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureSetting() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Temperature',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                _temperature.toStringAsFixed(2),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Higher values make output more random',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _temperature,
            min: 0.0,
            max: 2.0,
            divisions: 40,
            label: _temperature.toStringAsFixed(2),
            onChanged: (value) {
              setState(() {
                _temperature = value;
              });
              context.read<ChatProvider>().updateSettings(temperature: _temperature);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopPSetting() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Top P',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                _topP.toStringAsFixed(2),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Nucleus sampling parameter',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _topP,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            label: _topP.toStringAsFixed(2),
            onChanged: (value) {
              setState(() {
                _topP = value;
              });
              context.read<ChatProvider>().updateSettings(topP: _topP);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.palette_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Theme',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildThemeOption(
                context,
                themeProvider,
                AppThemeMode.light,
                'Light',
                Icons.light_mode,
              ),
              const SizedBox(height: 8),
              _buildThemeOption(
                context,
                themeProvider,
                AppThemeMode.dark,
                'Dark',
                Icons.dark_mode,
              ),
              const SizedBox(height: 8),
              _buildThemeOption(
                context,
                themeProvider,
                AppThemeMode.system,
                'System',
                Icons.brightness_auto,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeProvider themeProvider,
    AppThemeMode mode,
    String label,
    IconData icon,
  ) {
    final isSelected = themeProvider.themeMode == mode;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => themeProvider.setThemeMode(mode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
