import Foundation

struct Profile: Identifiable, Codable {
    let id = UUID()
    var name: String
    var bio: String
    var interests: [String]
}
