@attached(memberAttribute)
public macro storage(
  prefix: String = "io.lzhlovesjyq",
  suiteName: String = "io.lzhlovesjyq.userdefaults"
) = #externalMacro(module: "StorageMacros", type: "StorageMacro")

@attached(peer)
public macro nonstorage() = #externalMacro(module: "StorageMacros", type: "NonStorageMacro")
