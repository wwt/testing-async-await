import Foundation

struct Repository: Codable, Equatable {
    let name: String
}

struct NetworkClient {
    static func repos(from urlString: String) async throws -> [Repository] {
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "url not found", code: -1)
        }

        let request = URLRequest(url: url)
        let (data, _) = try await URLSession.shared.data(for: request)
        let repos = try JSONDecoder().decode([Repository].self, from: data)

        return repos
    }

    static func faangRepos() async throws -> [Repository] {
        async let facebookRepos = NetworkClient.repos(from: "https://api.github.com/orgs/facebook/repos")
        async let amazonRepos = NetworkClient.repos(from: "https://api.github.com/orgs/aws/repos")
        async let appleRepos = NetworkClient.repos(from: "https://api.github.com/orgs/apple/repos")
        async let netflixRepos = NetworkClient.repos(from: "https://api.github.com/orgs/netflix/repos")
        async let googleRepos = NetworkClient.repos(from: "https://api.github.com/orgs/google/repos")

        let repos = try await facebookRepos + amazonRepos + appleRepos + netflixRepos + googleRepos
        return repos
    }

    static func faangReposTaskGroup() async throws -> [Repository] {
        try await withThrowingTaskGroup(of: [Repository].self) { taskGroup in
            let facebookRepos = try await NetworkClient.repos(from: "https://api.github.com/orgs/facebook/repos")
            let amazonRepos = try await NetworkClient.repos(from: "https://api.github.com/orgs/aws/repos")
            let appleRepos = try await NetworkClient.repos(from: "https://api.github.com/orgs/apple/repos")
            let netflixRepos = try await NetworkClient.repos(from: "https://api.github.com/orgs/netflix/repos")
            let googleRepos = try await NetworkClient.repos(from: "https://api.github.com/orgs/google/repos")

            let repos = facebookRepos + amazonRepos + appleRepos + netflixRepos + googleRepos
            return repos
        }
    }

    static func reposWithCompletion(from urlString: String, completion: @escaping (Result<[Repository], Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "invalid url", code: -1)))
            return
        }

        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request){ data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "no data returned", code: -1)))
                return
            }

            guard let repos = try? JSONDecoder().decode([Repository].self, from: data) else {
                completion(.failure(NSError(domain: "data could not decode", code: -1)))
                return
            }

            completion(.success(repos))
        }.resume()
    }

    static func reposWithCompletionAsync(from urlString: String) async throws -> [Repository] {
        try await withCheckedThrowingContinuation { continuation in
            NetworkClient.reposWithCompletion(from: urlString) { result in
                switch result {
                    case .success(let value):
                        continuation.resume(returning: value)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                }
            }
        }
    }
}
