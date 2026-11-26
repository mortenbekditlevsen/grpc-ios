// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription
import Foundation

var basePath = "."

let package = Package(
  name: "gRPC",
  defaultLocalization: "en",
  products: [
    .library(
      name: "gRPC-Core",
      targets: [
        "gRPC-Core",
      ]
    ),
    .library(
      name: "gRPC-cpp",
      targets: [
        "gRPC-cpp",
      ]
    )
  ],

  // firebase-swift: the forks with Windows fixes, which firebase-swift also
  // lists. A package that depends on firebase-swift would otherwise get these
  // upstream URLs: SwiftPM keeps the first one it meets for a package.
  dependencies: [
    .package(url: "https://github.com/mortenbekditlevsen/abseil-cpp-SwiftPM.git", branch: "windows-fixes-0.20250512.1"),
    .package(url: "https://github.com/mortenbekditlevsen/boringSSL-SwiftPM.git", branch: "windows-0.41.0"),
    // firebase-swift: zlib on Windows, which has no system zlib. Other
    // packages use this one too (libpng, for SwiftCrossUI), and SwiftPM
    // builds a package once, so they share a single copy.
    .package(url: "https://github.com/the-swift-collective/zlib.git", from: "1.3.1"),
  ],

  targets: [
    .target(
      name: "gRPC-Core",
      dependencies: [
        .product(name:"abseil", package: "abseil-cpp-SwiftPM"),
        .product(name:"openssl_grpc", package: "boringssl-SwiftPM"),
        .product(name: "ZLibC", package: "zlib", condition: .when(platforms: [.windows])),
      ],
      path: basePath,
      // Directories without a trailing "/": SwiftPM on Windows ignores
      // paths that end in one.
      exclude: [
        "src/objective-c",
        "src/cpp",
        "third_party/upb/upb/port/def.inc",
        "third_party/upb/upb/port/undef.inc",
        "third_party/utf8_range/utf8_range_sse.inc",
        "third_party/utf8_range/utf8_range_neon.inc",
        "third_party/re2/LICENSE",
        "third_party/utf8_range/LICENSE",
        "third_party/xxhash/LICENSE",
        // Not the bundled zlib: the system one, or on Windows the zlib
        // package's (see dependencies).
        "third_party/zlib",
        "tests",
      ],
    
      sources: [
        "src",
        "third_party",
      ],
      resources: [
        .copy("src/objective-c/PrivacyInfo.xcprivacy"),
      ],
      publicHeadersPath: "spm-core-include",
      cSettings: [
        .headerSearchPath("./"),
        .headerSearchPath("include/"),
        .headerSearchPath("third_party/re2/"),
        .headerSearchPath("third_party/upb/"),
        .headerSearchPath("third_party/utf8_range/"),
        .headerSearchPath("third_party/xxhash/"),
        .headerSearchPath("third_party/address_sorting/include/"),
        .headerSearchPath("src/core/ext/upb-gen/"),
        .headerSearchPath("src/core/ext/upbdefs-gen/"),
        .define("GRPC_ARES", to: "0"),
        // As gRPC's CMake build: windows.h's min and max macros break re2.
        .define("NOMINMAX", .when(platforms: [.windows])),
      ],
      linkerSettings: [
        // Only on Apple platforms: swift-build (Swift 6.4's default) passes
        // -framework to the linker on Linux too, where it fails. 5.9 tools
        // are needed to name visionOS.
        .linkedFramework("CoreFoundation", .when(platforms: [.macOS, .macCatalyst, .iOS, .tvOS, .watchOS, .visionOS])),
        .linkedLibrary("z", .when(platforms: [.macOS, .macCatalyst, .iOS, .tvOS, .watchOS, .visionOS, .linux, .android])),
      ]
    ),
    .target(
      name: "gRPC-cpp",
      dependencies: [
        .product(name:"abseil", package: "abseil-cpp-SwiftPM"),
        "gRPC-Core",
      ],
      path: basePath,
      exclude: [
        "tests",
        "include/grpcpp/ports_undef.inc",
        "include/grpcpp/ports_def.inc",
      ],
      sources: [
        "src/cpp",
      ],
      resources: [
        .copy("src/objective-c/PrivacyInfo.xcprivacy"),
      ],
      publicHeadersPath: "spm-cpp-include",
      cSettings: [
        .headerSearchPath("./"),
        .headerSearchPath("include/"),
        .headerSearchPath("third_party/upb/"),
        .headerSearchPath("src/core/ext/upb-gen"),
        .headerSearchPath("src/core/ext/upbdefs-gen/"),
        .define("NOMINMAX", .when(platforms: [.windows])),
      ]
    ),
    .testTarget(
      name: "build-test",
      dependencies: [
        "gRPC-cpp",
      ],
      path: basePath + "/tests/spm_build"
    ),
  ],
  cLanguageStandard: .gnu11,
  cxxLanguageStandard: .cxx17
)
