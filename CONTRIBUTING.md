# Contributing to MacTrayOrganiser

Thank you for your interest in contributing to MacTrayOrganiser! This document provides guidelines and instructions for contributing.

## Table of Contents
- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Pull Request Process](#pull-request-process)
- [Code Style](#code-style)
- [Reporting Issues](#reporting-issues)

---

## Code of Conduct

This project follows a simple code of conduct:
- Be respectful and inclusive
- Provide constructive feedback
- Focus on the issue, not the person
- Help others learn and grow

---

## Getting Started

### Prerequisites
- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later
- Git

### Fork & Clone

1. Fork the repository on GitHub
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/MacTrayOrganiser.git
   cd MacTrayOrganiser
   ```
3. Add upstream remote:
   ```bash
   git remote add upstream https://github.com/thejustinjames/MacTrayOrganiser.git
   ```

---

## Development Setup

### Opening the Project
```bash
open MacTrayOrganiser.xcodeproj
```

### Building
1. Select the **MacTrayOrganiser** scheme
2. Choose **My Mac** as the destination
3. Press `Cmd + B` to build or `Cmd + R` to build and run

### Running
- The app will appear in your **menu bar** (not the Dock)
- You'll need to grant Accessibility permission on first run
- Look for the grid icon (⊞) in the menu bar

### Debugging
- Use Xcode's debugger as normal
- Console logs appear in Xcode's debug console
- For Accessibility API issues, check Console.app for system logs

---

## Making Changes

### Branching Strategy
- `main` - Stable release branch
- `develop` - Development branch (if used)
- Feature branches: `feature/description`
- Bug fixes: `fix/description`

### Creating a Branch
```bash
git checkout main
git pull upstream main
git checkout -b feature/your-feature-name
```

### Commit Messages
Follow conventional commit format:
```
type: brief description

Longer description if needed.

Co-Authored-By: Your Name <your@email.com>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Code style (formatting, no logic change)
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

Example:
```
feat: add keyboard shortcuts for navigation

- Add Cmd+R for refresh
- Add Cmd+, for settings
- Add arrow key navigation in grid

Co-Authored-By: Jane Doe <jane@example.com>
```

---

## Pull Request Process

### Before Submitting
1. Ensure your code builds without warnings
2. Test your changes thoroughly
3. Update documentation if needed
4. Rebase on latest `main`:
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

### Submitting
1. Push your branch:
   ```bash
   git push origin feature/your-feature-name
   ```
2. Open a Pull Request on GitHub
3. Fill in the PR template
4. Link any related issues

### PR Template
```markdown
## Description
Brief description of changes.

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation
- [ ] Refactoring

## Testing
Describe how you tested the changes.

## Screenshots (if applicable)
Add screenshots for UI changes.

## Checklist
- [ ] Code builds without warnings
- [ ] Changes are tested
- [ ] Documentation is updated
- [ ] Commit messages follow guidelines
```

### Review Process
1. Maintainers will review your PR
2. Address any feedback
3. Once approved, your PR will be merged

---

## Code Style

### Swift Style Guide
- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use 4 spaces for indentation
- Maximum line length: 120 characters
- Use meaningful variable and function names

### SwiftUI Conventions
```swift
// View structure
struct MyView: View {
    // 1. Environment objects
    @EnvironmentObject var settings: AppSettings

    // 2. State properties
    @State private var isLoading = false

    // 3. Regular properties
    let title: String

    // 4. Body
    var body: some View {
        // ...
    }

    // 5. Subviews
    private var headerView: some View {
        // ...
    }

    // 6. Methods
    private func loadData() {
        // ...
    }
}
```

### File Organization
```swift
// 1. Imports
import SwiftUI
import AppKit

// 2. Main type
struct/class MyType {
    // MARK: - Properties

    // MARK: - Initialization

    // MARK: - Public Methods

    // MARK: - Private Methods
}

// 3. Extensions
extension MyType: SomeProtocol {
    // ...
}

// 4. Preview (for SwiftUI)
#Preview {
    MyView()
}
```

### Documentation
- Add documentation comments for public APIs
- Use `///` for documentation comments
- Include parameter and return descriptions

```swift
/// Scans all menu bar items and updates the published list.
///
/// This method queries the Accessibility API to find all menu bar items
/// from SystemUIServer, ControlCenter, and third-party apps.
///
/// - Note: Requires Accessibility permission to be granted.
func scan() {
    // ...
}
```

---

## Reporting Issues

### Bug Reports
Include:
1. **macOS version**
2. **App version**
3. **Steps to reproduce**
4. **Expected behavior**
5. **Actual behavior**
6. **Screenshots** (if applicable)
7. **Console logs** (if applicable)

### Feature Requests
Include:
1. **Problem** you're trying to solve
2. **Proposed solution**
3. **Alternatives** you've considered
4. **Additional context**

### Issue Template
```markdown
## Bug Report / Feature Request

### Environment
- macOS version:
- App version:

### Description
Clear description of the issue or feature.

### Steps to Reproduce (for bugs)
1. Step one
2. Step two
3. ...

### Expected Behavior

### Actual Behavior

### Screenshots

### Additional Context
```

---

## Architecture Overview

For a detailed understanding of the codebase, see [ARCHITECTURE.md](ARCHITECTURE.md).

Key areas:
- `Services/` - Core business logic and API interactions
- `Views/` - SwiftUI user interface
- `Models/` - Data models

---

## Questions?

If you have questions:
1. Check existing [Issues](https://github.com/thejustinjames/MacTrayOrganiser/issues)
2. Open a new issue with the "question" label
3. Be patient - maintainers are volunteers

---

Thank you for contributing! 🎉
