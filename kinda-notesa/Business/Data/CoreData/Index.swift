//
//  CoreData.swift
//  kinda-notesa
//
//  Created by Arsen Kipachu on 12/7/24.
//
import Foundation
import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "NoteCoreData")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func saveContext() {
        do {
            try context.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
    
    func createNote(title: String, content: String) -> Note {
        let note = Note(context: context)
        note.id = UUID()
        note.title = title
        note.content = content
        note.createdAt = Date()
        saveContext()
        return note
    }
    
    func fetchNotes(searchText: String? = nil) -> [Note] {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        if let searchText = searchText, !searchText.isEmpty {
            request.predicate = NSPredicate(
                format: "title CONTAINS[cd] %@ OR content CONTAINS[cd] %@",
                searchText, searchText
            )
        }
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching notes: \(error)")
            return []
        }
    }
    
    func deleteNote(_ note: Note) {
        context.delete(note)
        saveContext()
    }
    
    func updateNote(_ note: Note, newTitle: String, newContent: String) {
        note.title = newTitle
        note.content = newContent
        saveContext()
    }
}

