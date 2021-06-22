import Foundation

extension URLRequest {
    enum HTTPMethod {
        case get
        case put
        case post
        case patch
        case delete
    }

    init(_ method: HTTPMethod, urlString: String) {
        let url = URL(string: urlString)
        self.init(url: url!)
        httpMethod = "\(method)".uppercased()
    }
}
