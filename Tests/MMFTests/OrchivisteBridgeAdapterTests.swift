import Foundation
import OrchivisteKitContracts
import Testing
import MMFFeatureWorker

@Test
func makeExecutionPlanForRunUsesCanonicalParameters() throws {
    let request = ToolRequest(
        requestID: "req-1",
        tool: "MuniMiseEnForme",
        action: "run",
        parameters: [
            "source_docx": .string("/tmp/source.docx"),
            "template_docx": .string("/tmp/template.docx"),
            "output_docx": .string("/tmp/output.docx"),
            "report_json": .string("/tmp/report.json"),
            "normalized_json": .string("/tmp/normalized.json"),
            "structuring_mode": .string("deterministic")
        ]
    )

    let plan = try OrchivisteBridgeAdapter.makeExecutionPlan(from: request)

    #expect(plan.workerRequest.sourceDocxPath == "/tmp/source.docx")
    #expect(plan.workerRequest.templateDocxPath == "/tmp/template.docx")
    #expect(plan.workerRequest.outputDocxPath == "/tmp/output.docx")
    #expect(plan.workerRequest.reportPath == "/tmp/report.json")
    #expect(plan.workerRequest.structuringMode == .deterministicOnly)
    #expect(plan.normalizedJSONOutputURL?.path == "/tmp/normalized.json")
}

@Test
func makeExecutionPlanForAnalyzeSupportsInputArtifactURI() throws {
    let request = ToolRequest(
        requestID: "req-2",
        tool: "MuniMiseEnForme",
        action: "analyze",
        inputArtifacts: [
            ArtifactDescriptor(id: "source", kind: .input, uri: "file:///tmp/source.docx")
        ]
    )

    let plan = try OrchivisteBridgeAdapter.makeExecutionPlan(from: request)

    #expect(plan.workerRequest.sourceDocxPath == "/tmp/source.docx")
    #expect(plan.workerRequest.templateDocxPath == nil)
    #expect(plan.workerRequest.outputDocxPath == nil)
    #expect(plan.workerRequest.reportPath == nil)
}

@Test
func makeResultUsesCanonicalNeedsReviewStatusWhenWarningsExist() {
    let request = ToolRequest(
        requestID: "req-3",
        tool: "MuniMiseEnForme",
        action: "run"
    )
    let response = WorkerResponse(
        contractVersion: "1.0",
        success: true,
        outputDocxPath: "/tmp/output.docx",
        normalizedJsonPath: "/tmp/normalized.json",
        reportPath: "/tmp/report.json",
        warnings: ["style warning"],
        errors: []
    )

    let result = OrchivisteBridgeAdapter.makeResult(
        for: request,
        response: response,
        startedAt: "2026-03-14T12:00:00Z",
        finishedAt: "2026-03-14T12:00:05Z"
    )

    #expect(result.status == .needsReview)
    #expect(result.progressEvents.count == 2)
    #expect(result.progressEvents.last?.status == .needsReview)
    #expect(result.outputArtifacts.count == 3)
    #expect(result.errors.isEmpty)
}

@Test
func makeFailureResultUsesCanonicalFailedStatus() {
    let request = ToolRequest(
        requestID: "req-4",
        tool: "MuniMiseEnForme",
        action: "run"
    )
    let toolError = OrchivisteBridgeError.missingParameter("source_docx").toolError

    let result = OrchivisteBridgeAdapter.makeFailureResult(
        for: request,
        startedAt: "2026-03-14T12:00:00Z",
        finishedAt: "2026-03-14T12:00:01Z",
        error: toolError
    )

    #expect(result.status == .failed)
    #expect(result.errors.count == 1)
    #expect(result.errors.first?.code == "MISSING_PARAMETER")
    #expect(result.progressEvents.last?.status == .failed)
}
