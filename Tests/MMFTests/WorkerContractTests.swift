import Foundation
import Testing
import MMFFeatureWorker

@Test
func workerRequestDecodesWithoutContractVersion() throws {
    let json = """
    {
      "source_docx": "/tmp/source.docx",
      "structuring_mode": "deterministicOnly"
    }
    """

    let data = try #require(json.data(using: .utf8))
    let decoded = try JSONDecoder().decode(WorkerRequest.self, from: data)

    #expect(decoded.sourceDocxPath == "/tmp/source.docx")
    #expect(decoded.contractVersion == nil)
}

@Test
func workerResponseEncodesContractVersion() throws {
    let response = WorkerResponse(
        contractVersion: "1.0",
        success: true,
        outputDocxPath: "/tmp/out.docx",
        normalizedJsonPath: "/tmp/out.json",
        reportPath: "/tmp/report.json"
    )

    let data = try JSONEncoder().encode(response)
    let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]

    #expect(obj?["contract_version"] as? String == "1.0")
    #expect(obj?["success"] as? Bool == true)
}
