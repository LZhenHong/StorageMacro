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
    let (prefix, suiteName) = parseArguments(from: node)

    guard let declName = declarationName(from: declaration), !declName.isEmpty else {
      return []
    }

    guard let variableDecl = member.as(VariableDeclSyntax.self),
          variableDecl.bindingSpecifier.tokenKind == .keyword(.var)
    else {
      return []
    }

    guard !hasExcludedAttribute(variableDecl),
          !hasPrivateAccess(variableDecl)
    else {
      return []
    }

    let bindings = variableDecl.bindings.compactMap { $0.as(PatternBindingSyntax.self) }
    guard let property = bindings.first,
          let propertyName = property.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
          property.accessorBlock == nil
    else {
      return []
    }

    guard property.initializer != nil || isOptional(property.typeAnnotation?.type) else {
      return []
    }

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

  // MARK: - Helpers

  private static func parseArguments(
    from node: AttributeSyntax
  ) -> (prefix: String, suiteName: String) {
    var prefix = "io.lzhlovesjyq"
    var suiteName = "io.lzhlovesjyq.userdefaults"

    guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
      return (prefix, suiteName)
    }

    for argument in arguments {
      guard let label = argument.label?.text,
            let value = argument.expression.as(StringLiteralExprSyntax.self)?
            .segments.first?.as(StringSegmentSyntax.self)?.content.text
      else { continue }

      switch label {
      case "prefix": prefix = value
      case "suiteName": suiteName = value
      default: break
      }
    }

    return (prefix, suiteName)
  }

  private static func declarationName(from declaration: some DeclGroupSyntax) -> String? {
    if let structDecl = declaration.as(StructDeclSyntax.self) {
      return structDecl.name.text
    } else if let classDecl = declaration.as(ClassDeclSyntax.self) {
      return classDecl.name.text
    }
    return nil
  }

  private static func hasExcludedAttribute(_ decl: VariableDeclSyntax) -> Bool {
    decl.attributes.contains { attr in
      guard let name = attr.as(AttributeSyntax.self)?
        .attributeName.as(IdentifierTypeSyntax.self)?.name.text
      else { return false }
      return name == "nonstorage" || name == "AppStorage"
    }
  }

  private static func hasPrivateAccess(_ decl: VariableDeclSyntax) -> Bool {
    decl.modifiers.contains { modifier in
      modifier.name.tokenKind == .keyword(.private) || modifier.name.tokenKind == .keyword(.fileprivate)
    }
  }

  private static func isOptional(_ type: TypeSyntax?) -> Bool {
    guard let type else { return false }
    if type.is(OptionalTypeSyntax.self) {
      return true
    }
    if let identifierType = type.as(IdentifierTypeSyntax.self),
       identifierType.name.text == "Optional" {
      return true
    }
    return false
  }
}
