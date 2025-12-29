# Dark Mode Implementation Plan

## Architecture Analysis

### Current State
- App already has light and dark themes defined in `main.dart`
- Uses `ThemeMode.system` (follows device settings)
- Material 3 design with ChatGPT green seed color (#10A37F)
- No user control over theme preference

### Goal
- Add user-controlled theme toggle (Light/Dark/System)
- Persist theme preference across app restarts
- Beautiful, consistent dark mode across all screens
- Settings screen with theme selector

## Implementation Strategy

### 1. Theme Provider (State Management)
**File**: `lib/providers/theme_provider.dart`
- Manage theme mode state (light/dark/system)
- Persist preference using SharedPreferences
- Notify listeners on theme change
- Initialize from saved preference

### 2. Enhanced Theme Definitions
**File**: `lib/config/app_theme.dart`
- Centralized theme configuration
- Custom light theme with refined colors
- Custom dark theme with carefully chosen colors
- Consistent styling across components

**Dark Mode Color Palette**:
- Background: Deep dark (#0D1117, #161B22)
- Surface: Slightly lighter (#1C2128, #22272E)
- Primary: ChatGPT green (#10A37F)
- Text: High contrast whites/grays
- Borders: Subtle dark grays

### 3. Settings Screen Update
**File**: `lib/screens/settings_screen.dart`
- Add "Appearance" section
- Theme mode selector (Radio buttons or Segmented control)
- Options: Light, Dark, System
- Visual feedback on selection

### 4. Main App Integration
**File**: `lib/main.dart`
- Add ThemeProvider to MultiProvider
- Bind MaterialApp.themeMode to provider
- Initialize theme on app start

### 5. Widget Compatibility
- All widgets already use Theme.of(context)
- No hardcoded colors detected
- Material 3 ensures automatic adaptation
- Test all screens for contrast and readability

## Color Scheme Design

### Light Theme
```
Primary: #10A37F (ChatGPT green)
Background: #FFFFFF
Surface: #F7F7F8
OnSurface: #202123
Error: #EF4444
```

### Dark Theme
```
Primary: #10A37F (ChatGPT green - same for brand consistency)
Background: #0D1117 (GitHub dark)
Surface: #161B22
SurfaceVariant: #22272E
OnSurface: #E6EDF3
OnSurfaceVariant: #8B949E
Error: #F85149
Outline: #30363D
```

## Implementation Steps

1. ✅ Create ThemeProvider with persistence
2. ✅ Create AppTheme configuration with beautiful dark colors
3. ✅ Update main.dart to use ThemeProvider
4. ✅ Add theme selector to Settings screen
5. ✅ Test theme switching on all screens
6. ✅ Verify persistence across app restarts
7. ✅ Fine-tune colors for optimal readability

## Testing Checklist

- [ ] Chat screen in dark mode
- [ ] Model selection screen in dark mode
- [ ] Settings screen in dark mode
- [ ] Conversation drawer in dark mode
- [ ] All dialogs in dark mode
- [ ] Theme persists after app restart
- [ ] System theme changes are respected
- [ ] No contrast issues or unreadable text
- [ ] Smooth theme transitions
