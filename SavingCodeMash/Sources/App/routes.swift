import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    let notesController = NotesController()
    try router.register(collection: notesController)
    
    let websiteController = WebsiteController()
    try router.register(collection: websiteController)
}
