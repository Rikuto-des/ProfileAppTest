import Foundation
import UIKit

struct Profile: Identifiable, Codable {
    let id: UUID
    var name: String
    var bio: String
    var interests: [String]
    var imageData: Data?
    
    enum CodingKeys: String, CodingKey {
        case id, name, bio, interests, imageData
    }
    
    init(id: UUID = UUID(), name: String, bio: String, interests: [String], image: UIImage? = nil) {
        self.id = id
        self.name = name
        self.bio = bio
        self.interests = interests
        self.imageData = image?.jpegData(compressionQuality: 0.8)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        bio = try container.decode(String.self, forKey: .bio)
        interests = try container.decode([String].self, forKey: .interests)
        imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
    }
}
