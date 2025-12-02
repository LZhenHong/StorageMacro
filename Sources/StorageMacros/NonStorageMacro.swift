import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum NonStorageError: CustomStringConvertible, Error {
  case onlyApplicableToVariables

  var description: String {
    switch self {
    case .onlyApplicableToVariables:
      "@nonstorage is only applicable to properties."
    }
  }
}

public enum NonStorageMacro: PeerMacro {
  public static func expansion(
    of _: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in _: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard let variableDecl = declaration.as(VariableDeclSyntax.self),
          case let .keyword(keyword) = variableDecl.bindingSpecifier.tokenKind,
          keyword == Keyword.var
    else {
      throw NonStorageError.onlyApplicableToVariables
    }
    return []
  }
}
