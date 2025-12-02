# Storage

A Swift Macro that automatically applies `@AppStorage` to properties, simplifying UserDefaults persistence in SwiftUI.

[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2013+%20|%20macOS%2010.15+%20|%20tvOS%2013+%20|%20watchOS%206+-blue.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Features

- Automatically generates `@AppStorage` attributes for stored properties
- Customizable key prefix and UserDefaults suite name
- Supports both `struct` and `class` types
- Opt-out mechanism with `@nonstorage`
- Skips computed properties, `private`/`fileprivate` properties automatically

## Requirements

- Swift 5.9+
- iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+

## Installation

### Swift Package Manager

Add the following to your `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/LZhenHong/StorageMacro.git", from: "0.0.1")
]
```

Or in Xcode: **File > Add Package Dependencies...** and enter the repository URL.

## Usage

### Basic Usage

```swift
import Storage

@storage
struct Settings {
  var isDarkMode = false
  var fontSize = 14
  var username = "Guest"
}
```

This expands to:

```swift
struct Settings {
  @AppStorage("io.lzhlovesjyq.settings.isdarkmode", store: (UserDefaults(suiteName: "io.lzhlovesjyq.userdefaults") ?? .standard))
  var isDarkMode = false

  @AppStorage("io.lzhlovesjyq.settings.fontsize", store: (UserDefaults(suiteName: "io.lzhlovesjyq.userdefaults") ?? .standard))
  var fontSize = 14

  @AppStorage("io.lzhlovesjyq.settings.username", store: (UserDefaults(suiteName: "io.lzhlovesjyq.userdefaults") ?? .standard))
  var username = "Guest"
}
```

### Custom Prefix and Suite Name

```swift
@storage(prefix: "com.myapp", suiteName: "com.myapp.defaults")
struct Settings {
  var isDarkMode = false
}
```

### Excluding Properties

Use `@nonstorage` to exclude specific properties:

```swift
@storage
struct Settings {
  var persistedValue = true

  @nonstorage
  var temporaryValue = false  // Won't have @AppStorage applied
}
```

### Automatically Skipped Properties

The macro automatically skips:

- `let` constants
- `private` or `fileprivate` properties
- Computed properties
- Properties without default values
- Properties already marked with `@AppStorage`

```swift
@storage
struct Settings {
  var stored = true           // ✅ Gets @AppStorage
  let constant = "value"      // ⏭️ Skipped (constant)
  private var secret = ""     // ⏭️ Skipped (private)
  var computed: Int { 42 }    // ⏭️ Skipped (computed)
  var noDefault: String       // ⏭️ Skipped (no default value)
}
```

## API Reference

### `@storage`

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `prefix` | `String` | `"io.lzhlovesjyq"` | Key prefix for AppStorage |
| `suiteName` | `String` | `"io.lzhlovesjyq.userdefaults"` | UserDefaults suite name |

### `@nonstorage`

Marker attribute to exclude a property from automatic `@AppStorage` generation.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
