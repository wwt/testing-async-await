import XCTest
@testable import TestingAsyncAwait

final class NetworkClientTests: XCTestCase {
    func testReposReturnsResult() async throws {
        let urlString = "https://api.github.com/orgs/apple/repos"
        let expectedRepos = [
            Repository(name: "swift"),
            Repository(name: "llvm-project"),
            Repository(name: "swift-driver")
        ]
        let data = try JSONEncoder().encode(expectedRepos)
        StubAPIResponse(
            request: .init(.get, urlString: urlString),
            statusCode: 200,
            result: .success(data)
        ).thenVerifyRequest {
            XCTAssertEqual($0.url?.absoluteString, urlString)
        }

        let repos = try await NetworkClient.repos(from: urlString)
        XCTAssertEqual(repos, expectedRepos)
    }

    func testReposThrows() async throws {
        let urlString = "https://api.github.com/notgoingtowork"
        StubAPIResponse(
            request: .init(.get, urlString: urlString),
            statusCode: 404,
            result: .failure(NSError(domain: "url not found", code: -1))
        ).thenVerifyRequest {
            XCTAssertEqual($0.url?.absoluteString, urlString)
        }

        await XCTAssertThrowsError(try await NetworkClient.repos(from: urlString))
//        do {
//            _ = try await NetworkClient.repos(from: urlString)
//            XCTFail("This call should throw an error.")
//        } catch let error as NSError {
//            XCTAssertEqual(error.domain, "invalid url")
//            XCTAssertEqual(error.code, -1)
//        }
    }

    func testReposWithCompletionAsyncReturnsResult() async throws {
        let urlString = "https://api.github.com/orgs/apple/repos"
        let expectedRepos = [
            Repository(name: "swift"),
            Repository(name: "llvm-project"),
            Repository(name: "swift-driver")
        ]
        let data = try JSONEncoder().encode(expectedRepos)
        StubAPIResponse(
            request: .init(.get, urlString: urlString),
            statusCode: 200,
            result: .success(data)
        ).thenVerifyRequest {
            XCTAssertEqual($0.url?.absoluteString, urlString)
        }

        let repos = try await NetworkClient.reposWithCompletionAsync(from: urlString)
        XCTAssertEqual(repos, expectedRepos)
    }

    func testReposWithCompletionAsyncThrows() async throws {
        let urlString = "https://api.github.com/notgoingtowork"
        StubAPIResponse(
            request: .init(.get, urlString: urlString),
            statusCode: 404,
            result: .failure(NSError(domain: "url not found", code: -1))
        ).thenVerifyRequest {
            XCTAssertEqual($0.url?.absoluteString, urlString)
        }

         await XCTAssertThrowsError(try await NetworkClient.reposWithCompletionAsync(from: urlString))
    }

    func testFaangReposReturnsResult() async throws {
        let repos = try await NetworkClient.faangRepos()
        XCTAssertTrue(!repos.isEmpty)
        XCTAssertTrue(repos.contains(where: { $0.name.lowercased().contains("facebook") }))
        XCTAssertTrue(repos.contains(where: { $0.name.lowercased().contains("amazon") }))
        XCTAssertTrue(repos.contains(where: { $0.name.lowercased().contains("swift") })) // Apple doesn't have their name in repos
        XCTAssertTrue(repos.contains(where: { $0.name.lowercased().contains("netflix") }))
        XCTAssertTrue(repos.contains(where: { $0.name.lowercased().contains("google") }))
    }

    func testFaangReposTaskGroupReturnsResult() async throws {
        let repos = try await NetworkClient.faangReposTaskGroup()
        XCTAssertTrue(!repos.isEmpty)
        XCTAssertTrue(repos.contains(where: { $0.name.lowercased().contains("facebook") }))
        XCTAssertTrue(repos.contains(where: { $0.name.lowercased().contains("amazon") }))
        XCTAssertTrue(repos.contains(where: { $0.name.lowercased().contains("swift") })) // Apple doesn't have their name in repos
        XCTAssertTrue(repos.contains(where: { $0.name.lowercased().contains("netflix") }))
        XCTAssertTrue(repos.contains(where: { $0.name.lowercased().contains("google") }))
    }
}

extension XCTest {
    func XCTAssertThrowsError<T: Sendable>(
        _ expression: @autoclosure () async throws -> T,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line,
        _ errorHandler: (_ error: Error) -> Void = { _ in }
    ) async {
        do {
            _ = try await expression()
            XCTFail(message(), file: file, line: line)
        } catch {
            errorHandler(error)
        }
    }
}
