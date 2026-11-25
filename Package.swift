// swift-tools-version:5.5
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
  ],

  targets: [
    .target(
      name: "gRPC-Core",
      dependencies: [
        .product(name:"abseil", package: "abseil-cpp-SwiftPM"),
        .product(name:"openssl_grpc", package: "boringssl-SwiftPM"),
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
        "third_party/zlib/LICENSE",
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
        // The bundled zlib, on every platform (Windows has no system one).
        .headerSearchPath("third_party/zlib"),
        .headerSearchPath("third_party/upb/"),
        .headerSearchPath("third_party/utf8_range/"),
        .headerSearchPath("third_party/xxhash/"),
        .headerSearchPath("third_party/address_sorting/include/"),
        .headerSearchPath("src/core/ext/upb-gen/"),
        .headerSearchPath("src/core/ext/upbdefs-gen/"),
        .define("GRPC_ARES", to: "0"),
        // As gRPC's CMake build: windows.h's min and max macros break re2.
        .define("NOMINMAX", .when(platforms: [.windows])),
        // Prefixes the bundled zlib's symbols with "z_", so they don't clash
        // with another copy of zlib in the same binary. Z_PREFIX leaves out
        // z_errmsg, which has the prefix already.
        .define("Z_PREFIX"),
        .define("z_errmsg", to: "grpc_z_errmsg"),
      ],
      linkerSettings: [
        .linkedFramework("CoreFoundation"),
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
