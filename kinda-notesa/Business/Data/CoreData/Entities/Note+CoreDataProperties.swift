import Foundation
import CoreData

extension NSManagedObject {
    @nonobjc public class func fetchRequest<T: NSManagedObject>() -> NSFetchRequest<T> {
        return NSFetchRequest<T>(entityName: String(describing: T.self))
    }
}

extension Note {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Note> {
        return NSFetchRequest<Note>(entityName: "Note")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var content: String?
    @NSManaged public var createdAt: Date?
}

extension Note: Identifiable {
    public var persistentID: NSManagedObjectID {
        return objectID
    }
}
