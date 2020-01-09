import Fluent
import Vapor

struct NotesController: RouteCollection {
    func boot(router: Router) throws {
        let notesRoutes = router.grouped("notes")
        notesRoutes.get(use: getAllHandler)
        notesRoutes.get(Note.parameter, use: getHandler)
        notesRoutes.post(use: createHandler)
        notesRoutes.put(Note.parameter, use: updateHandler)
        notesRoutes.delete(Note.parameter, use: deleteHandler)
    }
    
    func getAllHandler(_ req: Request) throws -> Future<[Note]> {
        return Note.query(on: req).all()
    }
    
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
}
