# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
# Build the package
swift build

# Run all tests
swift test

# Run a single test
swift test --filter StorageTests/test_storage_macro
```

## Architecture

This is a Swift Macro package that automatically applies `@AppStorage` attributes to properties in structs/classes.

### Package Structure

- **Storage** (library target): Exposes two macros for client use
- **StorageMacros** (macro target): Contains the macro implementations using SwiftSyntax
- **StorageTests**: Uses `SwiftSyntaxMacrosTestSupport` for macro expansion testing

### Macros

**`@storage(prefix:suiteName:)`** (MemberAttributeMacro): Applied to a struct/class, automatically adds `@AppStorage` to all `var` properties that:
- Have an initializer (default value) OR are optional types (`T?` or `Optional<T>`)
- Are not marked `private` or `fileprivate`
- Are not marked with `@nonstorage`
- Are not computed properties
- Don't already have `@AppStorage`

Parameters:
- `prefix`: Key prefix for AppStorage (default: `"io.lzhlovesjyq"`)
- `suiteName`: UserDefaults suite name (default: `"io.lzhlovesjyq.userdefaults"`)

The generated `@AppStorage` key follows the pattern: `<prefix>.<typename>.<propertyname>`.

**`@nonstorage`** (PeerMacro): Opt-out marker to exclude specific properties from automatic `@AppStorage` generation.

### Testing Pattern

Tests use `assertMacroExpansion` from SwiftSyntaxMacrosTestSupport to verify macro output against expected expanded source. Diagnostics can be verified using `DiagnosticSpec`.

## Code Style

- Use 2-space indentation for Swift code
- Write comments in English
