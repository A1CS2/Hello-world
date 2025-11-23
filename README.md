# 🚀 AI Coding Suite

> Next-generation native macOS application combining the best features of Replit, Base44, Emergent, Cursor, Warp, and VS Code into a single, visually stunning development environment.

![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## ✨ Features

### 🎨 **Stunning Visual Design**
- **5 Premium Themes**: Neon Dark, Neon Blue, Cyberpunk, Midnight, and Aurora
- **Glassmorphism Effects**: Beautiful blur effects with depth and transparency
- **Neon Accents**: Programmable glow effects and neon borders
- **Animated Backgrounds**: Smooth gradient transitions and micro-interactions
- **Retina Optimized**: Crisp rendering on all Apple displays

### 🧩 **Modular UI Framework**
- **Drag-and-Drop Panels**: Every component is movable and resizable
- **Custom Layouts**: Save and load your preferred workspace configurations
- **Grid-Based Positioning**: Snap panels to grid for perfect alignment
- **Multi-Monitor Support**: Extend your workspace across displays

### 💻 **Professional Code Editor**
- **Syntax Highlighting**: Support for Swift, Python, JavaScript, TypeScript, Rust, Go, and more
- **Line Numbers**: Clear code navigation
- **Tab Management**: Multi-file editing with elegant tab bar
- **AI Code Completion**: Intelligent suggestions powered by OpenAI, Anthropic Claude, or local models
- **Error Detection**: Real-time error highlighting and fixes
- **Code Refactoring**: AI-assisted code improvements

### 🤖 **Advanced AI Integration**
- **Multiple AI Providers**:
  - OpenAI (GPT-4, GPT-3.5)
  - Anthropic Claude
  - Local LLM Support (future)
- **AI Features**:
  - Smart code completion
  - Code explanation
  - Automated refactoring
  - Error fixing
  - Natural language to code
  - AI chat assistant

### 🖥️ **Intelligent Terminal**
- **AI Command Suggestions**: Get shell command recommendations
- **Multi-Terminal Support**: Run multiple terminals simultaneously
- **Syntax Highlighting**: Colored output for better readability
- **Command History**: Quick access to previous commands

### 📁 **Powerful File Management**
- **File Explorer**: Hierarchical file tree with folder expansion
- **Quick File Search**: Find files instantly
- **Git Integration**: Visual source control panel
  - See changed files
  - Stage/unstage changes
  - Commit with messages
  - Visual diff viewing

### ⚙️ **Comprehensive Settings**
- **General**: Auto-save, update checking, telemetry
- **Theme**: Full theme customization and preview
- **Editor**: Font size, tab size, word wrap, line numbers
- **AI**: Provider selection, model choice, API key management
- **Plugins**: Extensible plugin system (Phase 3)

### ⌨️ **Keyboard Shortcuts**
- `⌘N` - New File
- `⌘O` - Open Folder
- `⌘B` - Toggle File Explorer
- `⌘`` ` - Toggle Terminal
- `⌘⇧I` - Toggle AI Panel
- `⌘K` - Ask AI
- `⌘⇧P` - Command Palette (coming soon)
- `⌘⇧E` - Explain Code
- `⌘⇧R` - Refactor Code
- `⌘⇧F` - Fix Errors

## 🏗️ Architecture

### Technology Stack
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI with AppKit integration
- **Target**: macOS 14.0+ (Sonoma)
- **Optimized for**: Apple Silicon (M1/M2/M3/M4)

### Project Structure
```
AICodingSuite/
├── AICodingSuite/
│   ├── AICodingSuiteApp.swift      # Main app entry point
│   ├── MainWindowView.swift        # Main window layout
│   ├── UI/
│   │   ├── ModularFramework/       # Draggable panel system
│   │   │   ├── DraggablePanel.swift
│   │   │   └── LayoutManager.swift
│   │   ├── Components/             # UI components
│   │   │   ├── CodeEditor/
│   │   │   ├── Terminal/
│   │   │   ├── FileExplorer/
│   │   │   └── Sidebars.swift
│   │   ├── Theme/                  # Theme engine
│   │   │   └── ThemeManager.swift
│   │   └── Settings/
│   │       └── SettingsView.swift
│   ├── AI/                         # AI integration
│   │   ├── AIManager.swift
│   │   └── Providers/
│   │       ├── OpenAIProvider.swift
│   │       ├── AnthropicProvider.swift
│   │       └── LocalLLMProvider.swift
│   ├── Workspace/                  # Project management
│   │   └── WorkspaceManager.swift
│   └── Plugins/                    # Plugin system (Phase 3)
├── Package.swift                    # Swift Package Manager
├── Info.plist                       # App configuration
└── ARCHITECTURE.md                  # Detailed architecture docs
```

## 🚀 Getting Started

### Prerequisites
- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later
- Apple Silicon Mac (M1/M2/M3/M4) or Intel Mac

### Building the Project

#### Option 1: Xcode
```bash
# Clone the repository
git clone <repository-url>
cd Hello-world

# Open in Xcode
open AICodingSuite/AICodingSuite.xcodeproj

# Build and run (⌘R)
```

#### Option 2: Command Line
```bash
# Navigate to project directory
cd Hello-world/AICodingSuite

# Build with Swift Package Manager
swift build

# Run the application
.build/debug/AICodingSuite
```

#### Option 3: Release Build
```bash
# Build release version
swift build -c release

# The binary will be at:
# .build/release/AICodingSuite
```

### Configuration

#### Setting up AI Providers

1. **OpenAI**:
   - Go to Settings → AI
   - Select "OpenAI" as provider
   - Choose your model (GPT-4 recommended)
   - Enter your API key
   - API key is stored securely in UserDefaults

2. **Anthropic Claude**:
   - Go to Settings → AI
   - Select "Anthropic" as provider
   - Enter your Claude API key

3. **Local Model** (Coming Soon):
   - Select "Local Model" as provider
   - No API key required

## 🎨 Themes

### Available Themes

1. **Neon Dark** (Default)
   - Deep dark background
   - Cyan and hot pink accents
   - Strong glassmorphism

2. **Neon Blue**
   - Dark blue tones
   - Electric blue and purple accents
   - Enhanced glow effects

3. **Cyberpunk**
   - Purple and black base
   - Magenta and cyan highlights
   - Maximum glow intensity

4. **Midnight**
   - Pure black background
   - Sky blue accents
   - Minimal effects

5. **Aurora**
   - Dark teal base
   - Mint and light blue accents
   - Balanced glassmorphism

### Customizing Themes
- Change active theme in Settings → Theme
- Preview themes before applying
- Adjust glow intensity
- Toggle glassmorphism effects

## 🗺️ Roadmap

### ✅ Phase 1 (Current - Complete)
- [x] Native macOS app shell
- [x] Modular drag-and-drop UI framework
- [x] Theme engine with 5 premium themes
- [x] Code editor with syntax highlighting
- [x] Embedded terminal with AI suggestions
- [x] File explorer
- [x] Git integration panel
- [x] AI chat interface
- [x] AI provider abstraction (OpenAI, Anthropic)
- [x] Workspace management
- [x] Layout persistence
- [x] Settings interface
- [x] Keyboard shortcuts

### 🚧 Phase 2 (Next)
- [ ] Full LSP (Language Server Protocol) integration
- [ ] Advanced syntax highlighting with TreeSitter
- [ ] Real-time AI code completion
- [ ] AI-powered error detection and fixes
- [ ] Live data visualizations and charts
- [ ] Advanced git operations (diff, merge, blame)
- [ ] Multi-file search and replace
- [ ] Command palette
- [ ] Integrated debugger
- [ ] Performance profiling tools

### 🔮 Phase 3 (Future)
- [ ] Plugin/extension system
- [ ] Plugin marketplace
- [ ] Team collaboration features
- [ ] Live code sharing
- [ ] Remote development
- [ ] Docker integration
- [ ] Database management tools
- [ ] REST API testing
- [ ] Custom widget creation

### 🎯 Phase 4 (Polish)
- [ ] Advanced animations and transitions
- [ ] Accessibility features (VoiceOver, high contrast)
- [ ] Performance optimization
- [ ] Memory profiling
- [ ] Metal GPU acceleration
- [ ] App Store preparation
- [ ] Comprehensive test suite
- [ ] User documentation

## 📖 Documentation

- [Architecture Documentation](ARCHITECTURE.md) - Detailed technical architecture
- [UI Reference Images](docs/references/) - Visual design references

## 🤝 Contributing

This project is currently in active development. Contributions welcome!

### Development Setup
1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

Inspired by the best features from:
- **Replit** - Cloud-based development
- **Base44** - Modern UI/UX
- **Emergent** - AI-first coding
- **Cursor** - AI code editing
- **Warp** - Modern terminal
- **VS Code** - Extension ecosystem

## 📞 Support

For questions, issues, or feature requests:
- Open an issue on GitHub
- Check existing documentation
- Review the ARCHITECTURE.md file

---

**Built with ❤️ using Swift and SwiftUI for macOS**

*Optimized for Apple Silicon • Native Performance • Beautiful Design*
