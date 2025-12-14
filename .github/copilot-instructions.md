# GitHub Copilot Instructions for AI Coding Suite

## Project Overview
AI Coding Suite is a next-generation native macOS application built with Swift/SwiftUI, combining features from Replit, Base44, Emergent, Cursor, Warp, and VS Code. The project is optimized for Apple Silicon (M4 Pro) running macOS 14.0+ (Sonoma).

## Technology Stack
- **Language**: Swift 5.9+
- **Framework**: SwiftUI with AppKit integration
- **Architecture**: MVVM with Combine
- **Build System**: Xcode 15.0+, Swift Package Manager
- **Target**: macOS 14.0+ (Sonoma), ARM64 optimized

## Code Style & Conventions

### Swift Naming Conventions
- Use descriptive, clear names following Swift API Design Guidelines
- Types: PascalCase (e.g., `ThemeManager`, `AIManager`)
- Properties/Functions: camelCase (e.g., `currentTheme`, `updateLayout()`)
- Constants: camelCase (e.g., `defaultTimeout`, `maxCacheSize`)
- Protocols: Descriptive nouns or adjectives, often ending in "able" or "Protocol" (e.g., `Themeable`, `AIProviderProtocol`)

### File Headers
Always include standard file headers:
```swift
//
//  FileName.swift
//  AICodingSuite2
//
//  Created by S. Griggs on [date].
//
```

### SwiftUI Best Practices
- Prefer SwiftUI views over AppKit when possible
- Use `@State` for local view state, `@StateObject` for owned objects, `@ObservedObject` for passed objects
- Extract complex views into smaller, reusable components
- Use `#Preview` macro for SwiftUI previews
- Keep view bodies small and readable

### Architecture Patterns
- **MVVM**: Use ViewModels for business logic, Views for UI only
- **Combine**: Use for reactive programming and data flow
- **Dependency Injection**: Pass dependencies explicitly rather than using singletons
- **Protocol-Oriented**: Use protocols for abstraction (e.g., `AIProviderProtocol`)

## Project Structure

### Key Directories
```
AICodingSuite/
├── AI/                         # AI integration layer
│   ├── AIManager.swift
│   ├── Features/               # AI features (completion, refactoring)
│   └── Providers/              # AI provider implementations
├── UI/
│   ├── Theme/                  # Theme engine and theme definitions
│   ├── Components/             # UI components (editor, terminal, etc.)
│   ├── ModularFramework/       # Drag-and-drop panel system
│   └── Settings/               # Settings interface
├── Workspace/                  # Project and file management
├── LSP/                        # Language Server Protocol client
├── Plugins/                    # Plugin system
├── Database/                   # Database management
├── Docker/                     # Docker integration
└── Performance/                # Performance profiling and monitoring
```

## Key Features & Components

### 1. Theme System (5 Premium Themes)
- **Neon Dark**: Default, cyan/pink accents
- **Neon Blue**: Professional blue tones
- **Cyberpunk**: Purple/magenta/cyan
- **Midnight**: Pure black with sky blue
- **Aurora**: Dark teal with mint accents

Themes include:
- Glassmorphism effects (blur, transparency)
- Neon glow effects
- Animated gradient backgrounds
- Retina-optimized rendering

### 2. Modular UI Framework
- Draggable panels with resize handles
- Grid-based positioning with snapping
- Layout persistence (save/load)
- Multi-monitor support
- All major components are movable/resizable

### 3. AI Integration
Supports multiple AI providers through `AIProviderProtocol`:
- **OpenAI**: GPT-4, GPT-3.5
- **Anthropic**: Claude models
- **Local LLM**: Future support for local models

AI Features:
- Real-time code completion (300ms debounce, 60s LRU cache)
- Code explanation and documentation
- Automated refactoring
- Error detection and fixes
- Natural language to code
- Terminal command suggestions

### 4. LSP (Language Server Protocol)
- JSON-RPC 2.0 implementation
- Support for multiple languages (Swift, Python, JS/TS, Rust, Go, etc.)
- Features: completion, hover, diagnostics, go-to-definition, find references
- Document synchronization (didOpen, didChange, didClose)

### 5. Plugin System
- Sandboxed execution for security
- Permission-based access (7 permission types)
- 12 capability types (Editor, Workspace, Terminal, UI, AI, etc.)
- Plugin marketplace with categories
- One-click install/uninstall

## Keyboard Shortcuts
When implementing new features, consider these existing shortcuts:
- `⌘N` - New File
- `⌘O` - Open Folder
- `⌘B` - Toggle File Explorer
- ⌘` (Command + Backtick) - Toggle Terminal
- `⌘⇧I` - Toggle AI Panel
- `⌘K` - Ask AI
- `⌘⇧P` - Command Palette
- `⌘⇧E` - Explain Code
- `⌘⇧R` - Refactor Code
- `⌘⇧F` - Multi-file Search
- `⌘⇧G` - Git Panel

## Dependencies & Integration

### External Libraries
- Use Swift Package Manager (SPM) for dependencies
- Minimize external dependencies where native solutions exist
- Prefer Apple frameworks (Foundation, SwiftUI, AppKit) over third-party

### Common Imports
```swift
import SwiftUI          // UI framework
import Combine          // Reactive programming
import AppKit           // Native macOS APIs
import Foundation       // Core functionality
```

## Performance & Optimization

### Apple Silicon Optimization
- Leverage Metal for GPU-accelerated rendering where applicable
- Use ARM64-specific optimizations
- Profile with Instruments for performance bottlenecks

### Best Practices
- Use lazy loading for large datasets
- Implement caching with LRU eviction (see `RealTimeCompletion.swift`)
- Debounce user input to reduce API calls
- Use background queues for heavy operations
- Monitor memory usage (target: <200MB baseline, <500MB peak)

## Accessibility & User Experience

### Accessibility Features
- VoiceOver support with descriptive announcements
- High contrast mode (WCAG compliant)
- Keyboard navigation for all features
- Font scaling support
- Respect reduce motion preferences
- Haptic feedback where appropriate

### Animation Guidelines
- Use built-in animation presets (spring, bounce, glow)
- Implement micro-interactions (shimmer, pulse)
- Always check `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion`
- Keep animations subtle and purposeful

## Testing & Quality

### Code Quality
- Write clear, self-documenting code
- Add comments only where logic is complex
- Use descriptive variable and function names
- Handle errors gracefully with proper error types
- Validate user input

### Testing Strategy
- Unit tests for business logic
- Integration tests for LSP and AI providers
- UI tests for critical user flows
- Performance tests for large files/projects

## Common Patterns

### AI Provider Implementation
When adding new AI providers, implement `AIProviderProtocol`:
```swift
protocol AIProviderProtocol {
    func complete(prompt: String) async throws -> String
    func chat(messages: [ChatMessage]) async throws -> String
}
```

### Theme Definition
Themes should include:
- Primary, secondary, accent colors
- Background colors with opacity
- Glow/blur effects
- Dark mode compatibility

### Panel Creation
New draggable panels should:
- Inherit from base panel component
- Support resize handles
- Save/restore position and size
- Include minimize/maximize controls

## Security Considerations

### API Keys
- Store API keys in UserDefaults or Keychain
- Never commit API keys to source control
- Provide clear UI for key management

### Plugin Sandbox
- Plugins run with limited permissions
- Explicit permission requests for sensitive operations
- Validate all plugin inputs
- Limit file system access

### Data Privacy
- Telemetry is opt-in only
- Anonymize all user data
- No PII (Personally Identifiable Information) in logs
- Provide data export and deletion options

## Build & Development

### Building the Project
```bash
# Open in Xcode
open AICodingSuite/AICodingSuite.xcodeproj

# Command line build
cd AICodingSuite
swift build

# Release build
swift build -c release
```

### Code Signing
- Configure in Xcode: Signing & Capabilities
- Use unique bundle identifier: `com.yourname.aicodingsuite`
- Enable "Automatically manage signing"

## Documentation

### Code Documentation
- Document public APIs with Swift doc comments (`///`)
- Include parameter descriptions and return values
- Provide usage examples for complex features

### User Documentation
Key documentation files:
- `README.md` - Project overview and quick start
- `ARCHITECTURE.md` - Technical architecture details
- `BUILD_INSTRUCTIONS.md` - Building and installation
- `PROJECT_HANDOFF.md` - Complete project status
- `PHASE2-FEATURES.md`, `PHASE3-FEATURES.md` - Feature documentation

## Future Considerations

### Phase Roadmap (Current Status)
Based on PROJECT_HANDOFF.md, all four phases have been completed:
- **Phase 1**: ✅ Complete - Foundation and core features
- **Phase 2**: ✅ Complete - Advanced IDE capabilities (LSP, AI completion, debugging)
- **Phase 3**: ✅ Complete - Plugin system and professional tools
- **Phase 4**: ✅ Complete - Polish, animations, accessibility, telemetry

### Upcoming Features
When implementing new features, consider:
- Integration with existing plugin system
- Accessibility from day one
- Performance impact on large projects
- Theme compatibility
- Keyboard shortcut assignments
- Localization (future)

## Common Tasks & Patterns

### Adding a New Theme
1. Define colors in `ThemeManager.swift`
2. Include glassmorphism and glow settings
3. Test with all UI components
4. Add to theme picker in Settings

### Adding a New Command Palette Command
1. Add to command list in `CommandPalette.swift`
2. Define category, keywords, and keyboard shortcut
3. Implement action handler
4. Test fuzzy search matching

### Adding a New AI Feature
1. Implement in `AI/Features/`
2. Use existing `AIManager` for provider access
3. Add caching if needed (see `RealTimeCompletion.swift`)
4. Expose through UI with appropriate keyboard shortcut
5. Update Command Palette

### Extending LSP Support
1. Add language configuration to `LSPClient.swift`
2. Define server capabilities
3. Test completion, hover, and diagnostics
4. Add syntax highlighting rules if needed

## Debugging & Troubleshooting

### Common Issues
- **Build Errors**: Ensure Xcode 15.0+ and macOS 14.0+
- **Code Signing**: Configure team and bundle identifier
- **Performance**: Profile with Instruments, check for memory leaks
- **LSP Issues**: Verify language server installation and configuration
- **Theme Not Applying**: Check `ThemeManager` singleton state

### Logging
- Use `print()` for development logging
- Consider structured logging for production
- Log errors with context for debugging

## Contact & Support
For questions about architecture or implementation:
- Review `ARCHITECTURE.md` for detailed technical specs
- Check `PROJECT_HANDOFF.md` for feature status
- Refer to phase documentation for specific features

---

**Remember**: This is a native macOS app optimized for Apple Silicon. Always prioritize performance, native feel, and beautiful design. The app should feel like a first-party Apple application with professional-grade features.
