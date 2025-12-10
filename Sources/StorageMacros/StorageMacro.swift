import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum StorageDiagnostic: String, DiagnosticMessage {
  case multipleBindingsNotSupported

  var severity: DiagnosticSeverity { .warning }

  var message: String {
    switch self {
    case .multipleBindingsNotSupported:
      "Multiple bindings in a single declaration are not fully supported; only the first binding will have @AppStorage applied"
    }
  }

  var diagnosticID: MessageID {
    MessageID(domain: "StorageMacro", id: rawValue)
  }
}

public enum StorageMacro: MemberAttributeMacro {
  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingAttributesFor member: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [AttributeSyntax] {
    // Parse macro arguments
    var prefix = "io.lzhlovesjyq"
    var suiteName = "io.lzhlovesjyq.userdefaults"

    if let arguments = node.arguments?.as(LabeledExprListSyntax.self) {
      for argument in arguments {
        if let label = argument.label?.text,
           let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self),
           let value = stringLiteral.segments.first?.as(StringSegmentSyntax.self)?.content.text
        {
          switch label {
          case "prefix":
            prefix = value
          case "suiteName":
            suiteName = value
          default:
            break
          }
        }
      }
    }

    var declName: String?
    if let structDecl = declaration.as(StructDeclSyntax.self) {
      declName = structDecl.name.text
    } else if let classDecl = declaration.as(ClassDeclSyntax.self) {
      declName = classDecl.name.text
    }

    guard let declName, !declName.isEmpty else {
      return []
    }

    guard let variableDecl = member.as(VariableDeclSyntax.self),
          case let .keyword(keyword) = variableDecl.bindingSpecifier.tokenKind,
          keyword == Keyword.var
    else {
      return []
    }

    if !variableDecl.attributes.isEmpty {
      let identifiers = variableDecl.attributes
        .compactMap { $0.as(AttributeSyntax.self) }
        .compactMap { $0.attributeName.as(IdentifierTypeSyntax.self) }
      // Skip properties marked with @nonstorage or already have @AppStorage
      if identifiers.contains(where: { $0.name.text == "nonstorage" || $0.name.text == "AppStorage" }) {
        return []
      }
    }

    if !variableDecl.modifiers.isEmpty {
      let modifiers = variableDecl.modifiers
        .compactMap { $0.as(DeclModifierSyntax.self) }
        .compactMap(\.name)
      if modifiers.contains(where: {
        if case let .keyword(keyword) = $0.tokenKind,
           keyword == .private || keyword == .fileprivate
        {
          true
        } else {
          false
        }
      }) {
        return []
      }
    }

    let bindings = variableDecl.bindings.compactMap { $0.as(PatternBindingSyntax.self) }
    guard !bindings.isEmpty,
          let property = bindings.first,
          let propertyName = property.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
          property.accessorBlock == nil // Skip computed properties
    else {
      return []
    }

    // Check if property has initializer OR is optional type (which has implicit nil)
    let hasInitializer = property.initializer != nil
    let isOptionalType = isOptional(property.typeAnnotation?.type)

    guard hasInitializer || isOptionalType else {
      return []
    }

    // Warn if multiple bindings exist (e.g., var a = 1, b = 2)
    if bindings.count > 1 {
      context.diagnose(
        Diagnostic(
          node: variableDecl,
          message: StorageDiagnostic.multipleBindingsNotSupported
        )
      )
    }

    return [
      """
      @AppStorage("\(raw: prefix).\(raw: declName.lowercased()).\(raw: propertyName.lowercased())", store: (UserDefaults(suiteName: "\(raw: suiteName)") ?? .standard))
      """,
    ]
  }

  /// Check if a type is optional (T? or Optional<T>)
  private static func isOptional(_ type: TypeSyntax?) -> Bool {
    guard let type else { return false }

    // Check for T? syntax
    if type.is(OptionalTypeSyntax.self) {
      return true
    }

    // Check for Optional<T> syntax
    if let identifierType = type.as(IdentifierTypeSyntax.self),
       identifierType.name.text == "Optional"
    {
      return true
    }

    return false
  }
}
