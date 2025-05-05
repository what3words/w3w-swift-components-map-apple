// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "w3w-swift-components-map-apple",
  
  platforms: [.iOS(.v13)],

  products: [
    .library(name: "W3WSwiftComponentsMapApple", targets: ["W3WSwiftComponentsMapApple"]),
  ],

  dependencies: [
    .package(url: "https://github.com/what3words/w3w-swift-themes.git", "1.0.0"..<"2.0.0"),
    .package(url: "https://github.com/what3words/w3w-swift-design.git", "1.0.0"..<"2.0.0"),
    .package(url: "https://github.com/what3words/w3w-swift-components-map.git", branch: "staging"),
    .package(path: "../w3w-swift-core"),
  ],

  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "W3WSwiftComponentsMapApple",
      dependencies: [
        .product(name: "W3WSwiftCore", package: "w3w-swift-core"),
        .product(name: "W3WSwiftDesign", package: "w3w-swift-design"),
        .product(name: "W3WSwiftComponentsMap", package: "w3w-swift-components-map"),
        .product(name: "W3WSwiftThemes", package: "w3w-swift-themes"),
      ]
    ),
    
    .testTarget(name: "w3w-swift-components-map-appleTests", dependencies: ["W3WSwiftComponentsMapApple"]),
  ]
)
