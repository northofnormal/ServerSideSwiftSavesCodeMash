# Code snippets for Server Side Swift Saves CodeMash: 

###Snippet 1: Note model properties
```swift
	var id: Int?
    var title: String
    var presenter: String
    var notes: String
    var rating: Int
``` 

###Snippet 2: Note model initializer
```swift
init(title: String, presenter: String, notes: String, rating: Int) {
	self.title = title
    self.presenter = presenter
    self.notes = notes
	self.rating = rating
}
```


###Snippet 3: Database conformance the hard way
```swift
extension Note: Model {
    typealias Database = SQLiteDatabase
    typealias ID = Int
    public static var idKey: IDKey = \Note.id 
}
```


###Snippet 4: Make the model migrate-able 
```swift
extension Note: Migration { }
```


###Snippet 5: Add the migration
```swift
migrations.add(model: Note.self, database: .sqlite)
```


###Snippet 6: Conform to content 
```swift
extension Note: Content { }
```


###Snippet 7: Post Route 
```swift
router.post("notes") { req -> Future<Note> in
	return try req.content.decode(Note.self).flatMap(to: Note.self) { note in
		return note.save(on: req)
	}
}
```


###Snippet 8: Getting all notes 
```swift
router.get("notes") { req -> Future<[Note]> in
	return Note.query(on: req).all()
}
```


###Snippet 9: Getting a specific note 
```swift
router.get("notes", Note.parameter) { req -> Future<Note> in
	return try req.parameters.next(Note.self)
}
```


###Snippet 10: Updating a note 
```swift
router.put("notes", Note.parameter) { req -> Future<Note> in
	return try flatMap(to: Note.self, req.parameters.next(Note.self), req.content.decode(Note.self)) { note, updatedNote in
		note.title = updatedNote.title
		note.presenter = updatedNote.presenter
		note.notes = updatedNote.notes
		note.rating = updatedNote.rating
            
		return note.save(on: req)
    }
}
```


###Snippet 11: Deleting a note 
```swift
router.delete("notes", Note.parameter) { req -> Future<HTTPStatus> in
	return try req.parameters.next(Note.self).delete(on: req).transform(to: .noContent)
}
```

###Snippet 12: Controller setup
```swift
import Fluent
import Vapor

struct NotesController: RouteCollection {
	func boot(router: Router) throws { }
}
```

###Snippet 13: Get all handler
```swift
func getAllHandler(_ req: Request) throws -> Future<[Note]> {
	return Note.query(on: req).all()
}
```

###Snippet 14: Register Controller and collection
```swift
let notesController = NotesController()
try router.register(collection: notesController)
```

###Snippet 15: Website Controller Notes Route Grouped
```swift
let notesRoutes = router.grouped("notes")
notesRoutes.get(use: getAllHandler)
```

###Snippet 16: The rest of the handlers
```swift
func getHandler(_ req: Request) throws -> Future<Note> {
	return try req.parameters.next(Note.self)
}

func createHandler(_ req: Request) throws -> Future<Note> {
	return try req.content.decode(Note.self).flatMap(to: Note.self) { note in
		return note.save(on: req)
	}
}
    
func updateHandler(_ req: Request) throws -> Future<Note> {
	return try flatMap(to: Note.self, req.parameters.next(Note.self), req.content.decode(Note.self)) { note, updatedNote in
		note.title = updatedNote.title
		note.presenter = updatedNote.presenter
		note.notes = updatedNote.notes
		note.rating = updatedNote.rating
            
		return note.save(on: req)
	}
}
    
func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
	return try req.parameters.next(Note.self).delete(on: req).transform(to: .noContent)
}
```

###Snippet 17: Register the Routes 
```swift
notesRoutes.get(Note.parameter, use: getHandler)
notesRoutes.post(use: createHandler)
notesRoutes.put(Note.parameter, use: updateHandler)
notesRoutes.delete(Note.parameter, use: deleteHandler)
```

###Snippet 18: Register the Website controller and its route collection
```swift
let websiteController = WebsiteController()
try router.register(collection: websiteController)
```

###Snippet 19: Configure Leaf 
```swift
// Congifure Leaf
config.prefer(LeafRenderer.self, for: ViewRenderer.self)
```

###Snippet 20: Note Context
```swift
struct NoteContext: Encodable {
    var title: String
    var presenter: String
    var notes: String
    var rating: Int
    var id: Int
}
```

###Snippet 21: Handler for a single note 
```swift
func noteHandler(_ req: Request) throws -> Future<View> {
	return try req.parameters.next(Note.self).flatMap(to: View.self) { note in
		guard let noteID = note.id else {
			throw Abort(.unprocessableEntity)
		}
            
	let context = NoteContext(title: note.title, presenter: note.presenter, notes: note.notes, rating: note.rating, id: noteID)
	return try req.view().render("note", context)
	}
}
```

###Snippet 22: Create note context
```swift
struct CreateNoteContext: Encodable {
    let title = "Create a Note"
}
```

###Snippet 23: Create note handlers 
```swift
func createNoteHandler(_ req: Request) throws -> Future<View> {
	let context = CreateNoteContext()
	return try req.view().render("createNote", context)
}
    
func createNotePostHandler(_ req: Request, note: Note) throws -> Future<Response> {
	return note.save(on: req).map(to: Response.self) { note in
		guard let id = note.id else {
			throw Abort(.internalServerError)
}
```

###Snippet 24: Create note routes 
```swift
webRoutes.get("create", use: createNoteHandler)
webRoutes.post(Note.self, at: "create", use: createNotePostHandler)
```

###Snippet 25: Edit note context
```swift
struct EditNoteContext: Encodable {
    let title = "Edit Note"
    let note: Note
    let editing = true 
}
```

###Snippet 26: Edit note handlers
```swift
func editNoteHandler(_ req: Request) throws -> Future<View> {
    return try req.parameters.next(Note.self).flatMap(to: View.self) { note in
        let context = EditNoteContext(note: note)
        return try req.view().render("createNote", context)
    }
}

func editNotePostHandler(_ req: Request) throws -> Future<Response> {
    return try flatMap(to: Response.self, req.parameters.next(Note.self), req.content.decode(Note.self)) { note, data in
        note.title = data.title
        note.presenter = data.presenter
        note.notes = data.notes
        note.rating = data.rating
        
        guard let id = note.id else {
            throw Abort(.internalServerError)
        }
        
        let redirect = req.redirect(to: "/notes/\(id)")
        return note.save(on: req).transform(to: redirect)
    }
}
```

###Snippet 27: Edit note routes
```swift
webRoutes.get(Note.parameter, "edit", use: editNoteHandler)
webroutes.post(Note.parameter, "edit", use: editNotePostHandler)
```

###Snippet 28: Delete note handler
```swift
func deleteNoteHandler(_ req: Request) throws -> Future<Response> {
	return try req.parameters.next(Note.self).delete(on: req).transform(to: req.redirect(to: "/"))
}
```
