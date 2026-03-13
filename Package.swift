// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MuniMiseEnForme",
    defaultLocalization: "fr",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "MMFDomain", targets: ["MMFDomain"]),
        .library(name: "MMFCore", targets: ["MMFCore"]),
        .library(name: "MMFFeatures", targets: [
            "MMFFeatureImport",
            "MMFFeatureExtraction",
            "MMFFeatureStructuring",
            "MMFFeatureValidation",
            "MMFFeatureTemplateEngine",
            "MMFFeatureOutput",
            "MMFFeatureWorker"
        ]),
        .executable(name: "muni-mise-en-forme", targets: ["MuniMiseEnFormeCLI"]),
        .executable(name: "muni-mise-en-forme-app", targets: ["MuniMiseEnFormeApp"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-testing.git", from: "0.7.0")
    ],
    targets: [
        .target(name: "MMFDomain"),
        .target(
            name: "MMFCore",
            dependencies: ["MMFDomain"]
        ),
        .target(
            name: "MMFInfrastructureLogging",
            dependencies: ["MMFCore"]
        ),
        .target(
            name: "MMFInfrastructureDocx",
            dependencies: ["MMFDomain", "MMFCore", "MMFInfrastructureLogging"]
        ),
        .target(
            name: "MMFInfrastructureFoundationModels",
            dependencies: ["MMFDomain", "MMFCore", "MMFInfrastructureLogging"]
        ),
        .target(
            name: "MMFFeatureImport",
            dependencies: ["MMFDomain", "MMFCore"]
        ),
        .target(
            name: "MMFFeatureExtraction",
            dependencies: ["MMFDomain", "MMFCore", "MMFInfrastructureDocx"]
        ),
        .target(
            name: "MMFFeatureStructuring",
            dependencies: ["MMFDomain", "MMFCore", "MMFInfrastructureFoundationModels"]
        ),
        .target(
            name: "MMFFeatureValidation",
            dependencies: ["MMFDomain", "MMFCore"]
        ),
        .target(
            name: "MMFFeatureTemplateEngine",
            dependencies: ["MMFDomain", "MMFCore", "MMFInfrastructureDocx"]
        ),
        .target(
            name: "MMFFeatureOutput",
            dependencies: ["MMFDomain", "MMFCore"]
        ),
        .target(
            name: "MMFFeatureWorker",
            dependencies: [
                "MMFDomain",
                "MMFCore",
                "MMFFeatureImport",
                "MMFFeatureExtraction",
                "MMFFeatureStructuring",
                "MMFFeatureValidation",
                "MMFFeatureTemplateEngine",
                "MMFFeatureOutput"
            ]
        ),
        .executableTarget(
            name: "MuniMiseEnFormeCLI",
            dependencies: [
                "MMFDomain",
                "MMFCore",
                "MMFFeatureImport",
                "MMFFeatureExtraction",
                "MMFFeatureStructuring",
                "MMFFeatureValidation",
                "MMFFeatureTemplateEngine",
                "MMFFeatureOutput",
                "MMFFeatureWorker",
                "MMFInfrastructureLogging",
                "MMFInfrastructureDocx",
                "MMFInfrastructureFoundationModels"
            ]
        ),
        .executableTarget(
            name: "MuniMiseEnFormeApp",
            dependencies: [
                "MMFDomain",
                "MMFCore",
                "MMFFeatureWorker",
                "MMFInfrastructureLogging",
                "MMFInfrastructureDocx",
                "MMFInfrastructureFoundationModels"
            ]
        ),
        .testTarget(
            name: "MMFTests",
            dependencies: [
                "MMFFeatureValidation",
                "MMFFeatureStructuring",
                "MMFFeatureTemplateEngine",
                "MMFFeatureWorker",
                "MMFDomain",
                .product(name: "Testing", package: "swift-testing")
            ]
        )
    ]
)
