import Leaf
import Vapor

struct WebsiteController: RouteCollection {
    func boot(router: Router) throws {
        router.get(use: indexHandler)
        
        let webRoutes = router.grouped("notes")
        webRoutes.get(Note.parameter, use: noteHandler)
        webRoutes.get("create", use: createNoteHandler)
        webRoutes.post(Note.self, at: "create", use: createNotePostHandler)
        webRoutes.get(Note.parameter, "edit", use: editNoteHandler)
        webRoutes.post(Note.parameter, "edit", use: editNotePostHandler)
        webRoutes.post(Note.parameter, "delete", use: deleteNoteHandler)
    }
    
    func indexHandler(_ req: Request) throws -> Future<View> {
        return Note.query(on: req).all().flatMap(to: View.self) { notes in
            let notesData = notes.isEmpty ? nil : notes
            let context = IndexContext(title: "Home page", notes: notesData)
            return try req.view().render("index", context)
        }
    }
    
    func noteHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(Note.self).flatMap(to: View.self) { note in
            guard let noteID = note.id else {
                throw Abort(.unprocessableEntity)
            }
            let context = NoteContext(title: note.title, presenter: note.presenter, notes: note.notes, rating: note.rating, id: noteID)
            return try req.view().render("note", context)
        }
    }
    
    func createNoteHandler(_ req: Request) throws -> Future<View> {
        let context = CreateNoteContext()
        return try req.view().render("createNote", context)
    }
    
    func createNotePostHandler(_ req: Request, note: Note) throws -> Future<Response> {
        return note.save(on: req).map(to: Response.self) { note in
            guard let id = note.id else {
                throw Abort(.internalServerError)
            }
            
            return req.redirect(to: "/notes/\(id)")
        }
    }
    
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
    
    func deleteNoteHandler(_ req: Request) throws -> Future<Response> {
        return try req.parameters.next(Note.self).delete(on: req).transform(to: req.redirect(to: "/"))
    }
}

struct IndexContext: Encodable {
    let title: String
    let notes: [Note]?
}

struct NoteContext: Encodable {
    var title: String
    var presenter: String
    var notes: String
    var rating: Int
    var id: Int
}

struct CreateNoteContext: Encodable {
    let title = "Create a Note"
}

struct EditNoteContext: Encodable {
    let title = "Edit Note"
    let note: Note
    let editing = true
}

