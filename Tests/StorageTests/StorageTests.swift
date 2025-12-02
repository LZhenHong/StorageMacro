import StorageMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

let testMacros: [String: Macro.Type] = [
  "storage": StorageMacro.self,
  "nonstorage": NonStorageMacro.self,
]

final class StorageTests: XCTestCase {
  func test_nonstorage_macro() {
    assertMacroExpansion(
      """
      @storage
      struct A {
          @nonstorage
          var a = false
          let b = 1
          var c: Int
          private var d = 0
      }
      """,
      expandedSource: """
      struct A {
          var a = false
          let b = 1
          var c: Int
          private var d = 0
      }
      """,
      macros: testMacros
    )
  }

  func test_storage_macro() {
    assertMacroExpansion(
      """
      @storage
      struct A {
          var a = false
      }
      """,
      expandedSource: """
      struct A {
          @AppStorage("io.lzhlovesjyq.a.a", store: (UserDefaults(suiteName: "io.lzhlovesjyq.userdefaults") ?? .standard))
          var a = false
      }
      """,
      macros: testMacros
    )
  }

  func test_storage_macro_with_class() {
    assertMacroExpansion(
      """
      @storage
      class Settings {
          var isDarkMode = false
      }
      """,
      expandedSource: """
      class Settings {
          @AppStorage("io.lzhlovesjyq.settings.isdarkmode", store: (UserDefaults(suiteName: "io.lzhlovesjyq.userdefaults") ?? .standard))
          var isDarkMode = false
      }
      """,
      macros: testMacros
    )
  }

  func test_storage_macro_skips_fileprivate() {
    assertMacroExpansion(
      """
      @storage
      struct A {
          fileprivate var a = false
      }
      """,
      expandedSource: """
      struct A {
          fileprivate var a = false
      }
      """,
      macros: testMacros
    )
  }

  func test_storage_macro_skips_computed_property() {
    assertMacroExpansion(
      """
      @storage
      struct A {
          var computed: Int {
              return 1
          }
      }
      """,
      expandedSource: """
      struct A {
          var computed: Int {
              return 1
          }
      }
      """,
      macros: testMacros
    )
  }

  func test_storage_macro_skips_existing_appstorage() {
    assertMacroExpansion(
      """
      @storage
      struct A {
          @AppStorage("custom.key") var a = false
      }
      """,
      expandedSource: """
      struct A {
          @AppStorage("custom.key") var a = false
      }
      """,
      macros: testMacros
    )
  }

  func test_storage_macro_multiple_bindings_warning() {
    assertMacroExpansion(
      """
      @storage
      struct A {
          var a = 1, b = 2
      }
      """,
      expandedSource: """
      struct A {
          @AppStorage("io.lzhlovesjyq.a.a", store: (UserDefaults(suiteName: "io.lzhlovesjyq.userdefaults") ?? .standard))
          var a = 1, b = 2
      }
      """,
      diagnostics: [
        DiagnosticSpec(
          message: "Multiple bindings in a single declaration are not fully supported; only the first binding will have @AppStorage applied",
          line: 3,
          column: 5,
          severity: .warning
        ),
      ],
      macros: testMacros
    )
  }

  func test_storage_macro_custom_prefix() {
    assertMacroExpansion(
      """
      @storage(prefix: "com.myapp")
      struct A {
          var a = false
      }
      """,
      expandedSource: """
      struct A {
          @AppStorage("com.myapp.a.a", store: (UserDefaults(suiteName: "io.lzhlovesjyq.userdefaults") ?? .standard))
          var a = false
      }
      """,
      macros: testMacros
    )
  }

  func test_storage_macro_custom_suite_name() {
    assertMacroExpansion(
      """
      @storage(suiteName: "com.myapp.defaults")
      struct A {
          var a = false
      }
      """,
      expandedSource: """
      struct A {
          @AppStorage("io.lzhlovesjyq.a.a", store: (UserDefaults(suiteName: "com.myapp.defaults") ?? .standard))
          var a = false
      }
      """,
      macros: testMacros
    )
  }

  func test_storage_macro_custom_prefix_and_suite_name() {
    assertMacroExpansion(
      """
      @storage(prefix: "com.myapp", suiteName: "com.myapp.defaults")
      struct A {
          var a = false
      }
      """,
      expandedSource: """
      struct A {
          @AppStorage("com.myapp.a.a", store: (UserDefaults(suiteName: "com.myapp.defaults") ?? .standard))
          var a = false
      }
      """,
      macros: testMacros
    )
  }
}
