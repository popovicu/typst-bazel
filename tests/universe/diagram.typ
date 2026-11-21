// fletcher draws with cetz, which formats with oxifmt and runs a
// WebAssembly plugin. The document names fletcher only.
#import "@preview/fletcher:0.6.0": diagram, edge, node

#set document(title: "Drawn")

#diagram(
  node((0, 0), [Bazel]),
  edge("->"),
  node((1, 0), [Typst]),
)
