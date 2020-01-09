#Step One: Install and start a basic project 
* Back over in terminal, run `vapor xcode -y`, which will generate and open a discardable Xcode project for you. 
* Open up `routes.swift` - cmd-shift-o opens this cool search bar guy 
* And we have two example routes already set up for us. Ignore the controller business for now, that's an issue for future us. 
* let's breakdown what's happening in the basic route: the public route func takes a router, and that router has a `.get` method that has a closure that request object, whatever that is, and . When a call is made to this basic route, we get this response. 
* Take a look at the second example we've got--this one is taking a paramater. Each paramater provided to the `.get` method is a path component. So, if you fire up your server with `vapor run` again -- or use the handy run button up here, and this time go to `localhost:8080/hello" you should see "Hello world!" 
* You want to see something really cool? Type with me: 
```
router.get("hello", String.parameter) { req -> String in
        let name = try req.parameters.next(String.self)
        return "Hello, \(name)!"
    }
```
* now hit run again, head over to localhost:8080/hello/NAME and...check it out. 


# Time to get serious 
* Okay, what are we doing here: building a note-taking web app where we can create, update, and delete notes for each session. 
* What is a our model here, and what do we want it to have? 
* Session Title? Maybe a Presenter? And the notes part itself. Maybe a rating for the session, like 1-5 stars? 
* Clear out the cruft- `rm -rf Sources/App/Models/*, Sources/App/Controllers/*` and all the demo stuff in routes.swift, and the line about todo's in `configure.swift` migrations
* Configure.swift is a new place for us, so let's talk about this a bit. Vapor uses a framework called Fluent as a wrapper around the database. In vapor, we don't communicate with our database directly when we make a query, we use Fluent to so that we can use swift syntax instead of a bunch of finicky stings to communicate with our data. It's swift turtles all the way down with Vapor. This is the big selling point. Before we delete this line, take a look at what it's doing--adding a model called ToDo to an sqlite database...in a very swifty way. Models are the heart of Fluent, I took that line right off their website. You don't get back a dictionary or an array from a query, you can query directly with the models. Which means you can lean on the swift compiler to help you catch errors, among other things. 
* You can do this from Xcode, but...remember. Xcode projects are disposable in Vapor. The best practice is to do this outside of Xcode, to make sure the SPM and the Vapor Toolbox link the targets correctly. 
* in your terminal, `touch Sources/App/Models/Note`
* `vapor xcode -y` will regenerate your xcode code project with this new model and open for you. 
* Head over to Note.swift if you aren't there yet. Not a lot here--note that you don't have any boilerplate or that header block that another project would have. 
* First things first, import Vapor and FLuentSQLLite--note that you have a couple options here. Fluent supports four database drivers, SQL, SQLLight, Postgres, and MongoDB and there's an open source community-maintained driver for DynamoDB. We're going to use SQLLite for this one, because...it was the first one. 
* `final class Note: Codable`
* Now, we create our model class and make it final, which is a keyword in swift that means there can be no inheritance from this class and we can't override anything within it. This is a good plan bc you don't want to be messing around with these properties and intializers later. That way leads to chaos. 
* Note that we are conforming to Codable, too. All Fluent models must conform to Codable, it's a Swift protocol for mapping your data--as long as your property names match your JSON keys, data parsing happens easily and with great magic. 
* Add some properties(snippet 1), and an initializer(snippet 2) 
* Side note: I'm using code snippets that I set up ahead of time because typing in front of people is like driving with my dad. I will try and give you time to type this in yourself, but if I move on too quickly, let me know. Also, if you want a mini lesson on how to create and use code snippets or any of the other Xcode shortcuts I use, stick around after we wrap up and I'll show you. 
* Next we're going to do something that might look a little weird if you aren't used to Swift, we're going to create an extension. (snippet 3) This tells the Fluent what db to use, what type the ID will be, and the keypath of the id property. This is all info Fluent needs to make a dabase query. And, as it turns out, there's an even easier way to do this, delete what we just entered and replace it with: `extension Note: SQLiteModel {}`
* So remember when I said that Fluent supports a bunch of DB drivers? This is part of what you get with that package--If you mark your model as an SQLite Model, Fluent will know what database to use, what the ID is and where to find it. Yay protocols! 
* So speaking of that db, we will need to add the table and the databse schema and all that. (snippet t4) We're going to conform to another protocol here, Migration, that will allow Fluent to infer the schema thanks to codable. This is a pretty basic model so we're going with the default Migration implementation, but you can customize here if you have special circumstances. 
* Now that we're set up here, we need to tell Fluent to create the table when the app starts. So back to configure.swift Add this line, here where you took out the todo migration a few mintues ago (snippet 5) 
* Migrations in Fluent only run once, so it's important to know that Fluent won't recreate your table if you change the model. You'll have to run it again. Also note that you have to specify which db you are using with each migration--Fluent supports mixing multiple databases in a single application. 
* To run the migration, we'll need to build and run the app. Make sure your destination is set to MyMac up here and hit the run button. 
* (Show the migration output screenshot) you should get something like this in your console: 
* Success! 
* Now that we have this notes model, let's work on saving a note

#POSTing a note: 
* FLuent has another protocol, `Content` that works as a wrapper around codable to make it trivial to convert data back and forth. 
* So let's add THAT extension (snippet 6) now, if a browser or app sends properly-formatted JSON via a POST, we'll be able to decode it. 
```json
{
  "title": "Server Side Swift Saves CodeMash",
  "presenter": "Anne Cahalan",
  "notes": "This is the superbest session I am learning so much!!!",
  "rating": 10
}
```

* but we'll need a route to handle that POST, right? Otherwise, we're screaming into the void, and twitter already exists. So let's go over to routes.swift and add the following at the end of the routes method (snippet 7) 
* this does a lot in a little space, so I'll walk you through it
* We're registering a new route at /notes that accepts POST requests and returns a Future of the type Note, it will return your note once it's saved. 
* It decodes the request's JSON into a Note model using codable. This also returns a Future of the type Note, and uses `flatMap` to extract that note when decoding completes. 
* Finally if all goes well, it saves the note model using Fluent. This returns a Future Note as well, the actual note being saved. 
* Now, let's see if this works--open up RESTed or if you have something like PAW or Postman, that will work as well, but I'll be less able to help you out 
* Configure your host to 8080/notes, method: POST, JSON-encoded in the drop-down, enter your paramaters and their values, and then--hit SEND REQUEST button down here and...you should get your JSON response back formatted correctly! And it fills in that unique id, which we will need later. 
* Success? Success! 


# Setting up your database 
* So now we can post our notes...so we should probably save them, right? and that means databases! 
* Like I said, Fluent and Vapor can support a handful of different databases with minimal effort, but SQLite is the default. Let's take a look at configure.swift and start configuring your database if you want to use something else--for our purposes, we're going to continue with MYSQL. This is going to involve some configuration yak-shaving, but it will also show up a bit about how all the actually works and show you how to use a different db provider than the default.  
* This config file sets up a lot of things, we more than just the migration we did earlier. It registers the FluentSQLitePRovider to allow the application to interact via Fluent, it creates and registers a database--and notice that the database specifies that the storage is memory only. It only holds the data until things terminate, it's not persisted to disk. So let's fix that by giving it a path to store the database. 
* `let sqlite = try SQLiteDatabase(storage: .file(path: "notesDatabase.sqlite"))` This will look for a file at that path, create one if it doesn't find it, or use it if does. If you are cool with SQLite, you can actually stop here, but I wanted to run you through how to configure options other than the default, and that means we're going to proceed using MySQL instead. 
* So to test this with MySQL, we're going to need to fire up Docker, so if you haven't done that yet, wake up the whale. This is not a docker-focused talk, and web stuff is mostly dark magic to me, so for our purposes right now, we are going to cast some magic spells with Docker and not dig too deeply into what they do. 
* Run this command in the terminal, warning, it's pretty gnarly: 
* `docker run --name notes -e MYSQL_USER=vapor -e MYSQL_PASSWORD=password -e MYSQL_DATABASE=vapor -p 3306:3306 -d mysql/mysql-server:5.7` (post in slack if people want to copy-paste) 
* What this does is-- runs a new docker container called notes, specifies the database name, username, and password, allows applications to connect to the mysql server on its defaul port 3306, runs the server in the background. It also looks for and uses, or automatically downloads the Docker image mysql/mysql-server, version 5.7, which is the one we need for FLuent. 
* To check that this is running, type `docker ps` into your terminal et voila (show docker is running screenshot)
* Now comes that configuration yak shaving I mentioned earlier. Open up Package.swift and replace what's there with this: 
* delete products 
* delete the sqlite comment 
* `.package(url: "https://github.com/vapor/fluent-mysql.git", from: "3.0.0")`
* `.target(name: "App", dependencies: ["FluentMySQL", "Vapor"]),`
* Now close xcode and run `vapor xcode -y` again -- if you end up doing a lot of SSS with vapor, this is going to be a command you alias to something shorter pretty quickly. 
* When xcode reopens, let's head over to configure.swift and move that over to mysql as well 
* `import FluentMySQL`
* `try services.register(FluentMySQLProvider())`
 ```
 // Configure a MySQL database
    let mysqlConfig = MySQLDatabaseConfig(hostname: "localhost", username: "vapor", password: "password", database: "vapor")
    let mysql = MySQLDatabase(config: mysqlConfig)
```
* You could do all of this inline, sure, but if you want to know why I think that's a bad idea, come to my talk tomorrow morning on why sometimes more code is better than less code. 
* `databases.add(database: mysql, as: .mysql)` This is going to turn red and pitch a fit at you, but don't worry about it, we'll fix it in the next step. Open up the Notes model, and change the import and the kind of model protocol conformance we have happening and when we build and run again, all will be well and you'll see in the console that the migration ran(show that screenshot), and we have a lovely, if kinda empty, database waiting for us to fill it up with notely goodness. So let's do that. 

# Gettin' CRUDdy 
* CRUD operations are the four basic functions of any kind of persistent storage of data--you want to Create data, Retrieve it, Update it, and Delete it. 
* We've already done one of these, right? We created that POST route earlier this afternoon to add a new note. Let's think about our plan here for a moment, and think about what other routes we may want. 
* We'll want a GET at /notes that returns all our notes 
* We'll want that POST at /notes that creates a new one 
* We'll want a GET at notes/#id that fetches a specific note 
* We'll want a PUT at notes/#id that updates an existing note 
* and finally, we'll want a DELETE at notes/#id that can delete that note 
* Retrieve, the R part of our CRUD is actually two things--retrieve all our notes, and retrieve a single note with a given ID and here is where Fluent's ability to talk to databases for us gets super slick. Over in routes.swift, let's add our retrieve-all route. 
* (snippet 8) 
* This registers a new route, which expects a return of an array of notes, and performs the query--the SELECT * FROM notes bit 
* If we head over to RESTed we can go see if that worked...after some more yak shaving 
* make sure your app is running, hit the run button up here with the target as MyMac, and, since now we're playing around in a new db, run that post again! If you really want, change a few values and run the post again so we have two in there. And if you get a good response, let's change things up and run the GET request we just created (by selecting GET from the dropdown). And look, we have a JSON response with our two notes. LOOK AT US BUILDING AN API HOW COOL IS THIS. 
* Alright now, let's not get too excited. Let's see how this works for retrieving just ONE note, based on its id. Cast your mind back, if you will, to one of the first things we did in this session, where we made a route that showed our name? It's gonna be a lot like that. We need to make our model conform to the Parameter protocol, which we do with another extension over in Note.swift (do that, it's the easy way)
* You may be wondering about this extension business if you aren't used to swift--it's merely an organizational style thing. You could do this objective-c style where you declare them all up at the top, that would definitely work, but the accepted best practice in swift is to separate them out like this.
* Now that we can paramaterize our note model, let's go back to routes and make our individual notes route (snippet 9). This should all look familiar and should be starting to see the pattern here. We're going to create a route that's /notes/something and returns a Future Note, it extracts our note from the request using the parameters, which, under the hood, is a computed property that does all the work of getting our data from the db and even handles error cases when we look for an ID that doesn't exist. 
* Build and run, then let's head over to RESTed to see if it works. (add the ID to the route, try the GET again) 
* Success! 
* Alright, let's try a PUT to update one of these notes. (snippet 10) 
* To break this down, we're registering the route, we're using flatmap, this time with two Futures, to wait for the paramater extraction and content decoding, we're updating the existing note with the new data, then we are saving it and returning the result. 
* This, too, we can check in RESTed, change the method to PUT and adjust one of those properties. 
* HUZZAH 
* After we've done all this, I'm betting you can probably figure out delete pretty easily. The only difference is what we expect back. Up until now, we've been getting some kind of notes object back. Now, we're deleting the note, so it doesn't really make sense to send it back, so what we want instead is an HTTP response code. (snippet 11) 
* Again, registers a route, extracts the note we need based on the parameter, Fluent allows us to call delete direcly on the Future, so that's tidy and prevents some nesting, and turns the result into a No Content 204 result. So build and run again, and pop over to RESTed to see if it works. We should see the 204 response, and if we try that GET request at /notes, we should see...we've only got our one note left. 
* Everybody, take a moment to turn to your neighbor and give each other a high five. You have created full CRUD API using nothing but swift. 

#Controllers 
* I'm going to cover one more thing before we get into making an actual website with like UI and stuff, and that's Controllers. If you recall, we deleted some business about controllers out of the new project template way back at the start of this party. 
* Controllers in Vapor provide a better way to organize your code. We've only got one model going right now and a very simple single-table db, but what if we expand this little app to include things like, relationships between all of a speaker's talks or use some kind of tagging to quickly find our notes for mobile sessions vs. security sessions? You can see how this single routes file is going to get out of hand pretty quickly. 
* The best practice is to have a dedicated controller for each model. So we're going to build a note controller to handle all of the interactions on a note. 
* Quit xcode and head over to the terminal again, and type in `touch Sources/App/Controllers/NotesController.swift` and then `vapor xcode -y` to regenerate the project 
* Open up our new and empty NotesController, import Vapor and Fluent, create an NotesController struct that conforms to RouteCollection and add this empty boot function which is required by RouteController. (snippet 12) 
* Then, add a new function, called getAllHandler (snippet 13) This looks familiar, right? It looks exactly like the one in Routes.swift. 
* Up in that boot method? That's where we will register all our routes. So, go ahead and register this one like so `router.get("notes", use: getAllHandler)` This looks a lot like what's in Routes.swift, registering a route at /notes that will return all the notes. We don't need the one over in Routes anymore, so let's go remove it and tell it to use this instead. 
* Delete the GET request, and add (snippet 14). This creates a new NotesController and registers it with the router, thereby registering all the controllers routes. Build and run again and head over to RESTed and your GET request should work as normal. 
* This is good, but if you notice, we're also copying over these magic strings for routes, and if we change that ever, we're going to have to change it in a bunch of places. So, let's clean that up a little while we're here. 
* Vapor allows for the creation of route groups, so if you have a bunch of routes going to more or less the same place, you can create a route group and reference that instead. Go ahead and delete that line we just put into boot, and replace it with (snippet 15) 
* Now, the fun part. We get recreate all the stuff we just did over in Routes.swift here in the NotesController. I have the magic of code snippets, but this might take you a couple minutes. Protip, you can steal the guts of all your router.gets and router.posts and just copy them over into the guts of the new handler methods. (snippet 16)
* and now you'll need to register these all in boot, using that handy group (snippet 17) 
* And, you can delete everybody out of routes
* And can you see now how this could make routes.swift much easier to deal with in a very complicated application with a ton of models and routes? 
* Build and run again, and then use RESTed to check that you've got everything connected correctly. And, we've done a lot and this seems like a good place to stop. Let's take a quick break, run to the bathroom, check twitter, grab a drink, whatever, and meet back up here in about ten minutes and we'll start work on turning this JSON into pixels. 

#Leaf and website templates 
* Welcome back! 
* So, when we left we had a clean, swifty api creating, updating, deleting, crudding up a database like crazy. Now we're going to make a front end so we can actually use this thing in a real, meaningful way. 
* And for this, we are going to use Leaf, Vapor's templating language. There's lots of great reasons to use a templating language, they allow for a lot of flexibility and composability. Unfortunately, this means we are leaving the world of swift behind a bit and are going to mixing in some HTML
* So, let's go add Leaf as a package. Open up package.swift add `.package(url: "https://github.com/vapor/leaf.git", from: "3.0.0")` to our list of packages (don't forget the comma) and add it to the App target dependencieis. 
* close xcode and then at the terminal, `mkdir -p Resources/Views` -- this is where Leaf looks for templates. And then touch `Sources/App/Controllers/WebsiteController.swift` to make a website controller. And then, our friend vapor xcode -y 
* Over in WebsiteController, we're going create a new type to hold our website routes and a route that returns an index template, and that looks like this (web1) 
* This makes a new controller type, conforms it to route collections, and implements boot and a get handler just like we did before the break. 
* We'll talk about views in a minute, but this line here is the instructions to render a template called index.leaf from Resources/Views and return that result.  
* So let's make that. You can use any editor you want to do this, but we're hanging out in Xcode, so let's just stay there. You can just find the views folder over here on the navigator on the left, cmd-n to make a new file, and then give it the name index.leaf. If you want to turn on html syntax highlighting, you can Go to Editor > Syntax Highlighting > HTML 
* And we need to add some website boilerplate here, so I'll pop it in and give you a second to tippity tap (+ to get library, drag index1)
* How many of you are remembering like, the first computer thing you ever did right now? Look at us now, huh? 
* Aight, we've made a basic route and a basic page, time to register our route in routes.swift. I promise you this is the step you forget a thousand times and you'll try to load your stuff and it won't work and you'll swear at your code and cry and scare your cat and then realize that everything isn't broken and you aren't the worst developer in the world, you just forgot to do this one thing. So, calm down and open routes.swift and register the website controller and its collection. (snippet 18)
* Now we've got to configure Leaf over in Configure.swift -- Import Leaf (in alpha order, we are not an animal), then add `try services.register(LeafProvider())`, and add this line way at the bottom (snippet 19)
* that generic req.view line over in websitecontroller? we can use that particular call to actually switch to different templating engines if we need to. Why would we need to do that? Well, we could, if we were testing this, use a test renderer that would just throw up plain text to test against. All req.view wants is for Vapor to provide a type that conforms to the ViewRenderer protocol. This config line tells vapor to use the Leaf renderer when asked for a view renderer. 
* So, go ahead an run this and then head over to localhost 8080 and see what we got. 
* Man, it's like we're baby devs again. 
* Let's step it up, go back to index.leaf and change the title line to `<title>#(title) | Notes</title>` then head back to WebsiteController and add an index context struct (web2) and this line `let context = IndexContext(title: "Home page")` and the `context` to the render call. build and run, reload your page, you should see the updated title. 
* Getting there, getting a little more dynamic. Let's see what else we can add to our index context. Let's add an array of note object, huh? `let notes: [Note]?`
* And then let's complicate things a little in indexHandler, yeah? (web3) 
* So this is using a fluent query to get all our notes and add them, if they exist, to the IndexContext. 
* We're sending them over to this view, so let's do something with them, shall we? Let's open up index.leaf again and replace everything between the body tags with this super lovely html table (index1 on the gist)
* Build and run, and head over to the browser to see if it worked! Look at that man, that is an html table. We used to live like this, you know. 
* Alright, a very ugly table is well and good, but let's make a detail page with all the rest of our stuff, our actual notes and whatnot. 
* Back into websiteController, let's add a context (snippet 20) and another handler(snippet 21) - note that we have to pass the id into the context, too. We're going to need this id later when we're editing. 
*  Also add `router.get("notes", Note.parameter, use: noteHandler)` to boot 
*  Actually, we're going to be doing a lot of routes that will involve `/notes/something` so let's make a route group: `let webRoutes = router.grouped("notes")` and replace router in all cases except the index one, and delete the now-unnecessary "notes" path from the existing route
* and then create a new view, this one note.leaf, and (copy and paste `display note html` to screen)--this is how Leaf handles variables where we're passing data into the display page.
* and to get to this fancy new page, we'll have to create a link, so over in index.leaf, wrap the session title with `<a href="/notes/#(note.id)">` build and run aaaaand check us out! 

#Good god this is ugly. 
* So, right now we have two more things we need to do, create a page where we can actually input new notes and new sessions and make it less gruesomely painful to look at. I'm going to start with making it less ugly, and along the way we'll add some navigation to what will eventually be our create page. 
* So the first thing we can do is take advantage of some of that composability I talked about when we first introduced Leaf. What that means is we'll be embedding views within views so we can, for example, have some consistent styling, maybe a fancy header or something, maybe a nav bar. 
* Let's create a new template called base.leaf and paste in the boilerplate from the gist and between the body tags, let's just put this one line: `#get(content) 
* Leaf has a get tag that's now set to retrieve something variable called content. 
* Over in index.leaf, let's make a few quick changes: 
* Delete everything except what's between the body tags (don't keep the body tags) and wrap it in `#set("content") { }` and add, at the bottom, `#embed("base")` 
* This tells base to go get something called content, and tells index that a) this stuff is called "content" and b) you will be embedded in something called "base"
* We can do this over in note.leaf, too, wrap all that business in #set("content"){} and end with #embed("base")
* Now, to make this less painful to look at, we're going to use that great de-ugly-fying tool that has saved so many of us over the years--Bootstrap. Head over to getboostrap.com, and click Get Started, and on the right here, Starter template. 
* Grab the two required meta tags and drop those in base.leaf
* And the CSS link
* And the Javascript business
* And here's where that composibility gets handy--because all this is in base and all our views are embedded in base, this is available to all our views. 
* If you run this now, it will look a little better, but let's keep going. Wrap #get(content) in base with (base1, drag and drop)
* How about some navigation? Let's add a nav bar (drag and drop navbar) 
* Build and run, and check this out--we can navigate back and forth to the home page with some css bootstrap magic. 
* Let's make this table look a little better- add `class="table table-bordered table-hover"` to the table class; add `class="thead-light"` to the thead, build and run
* Huzzah! Now we can proceed to making a create page without wanting to poke our eyes out. 

#Create a note! Home stretch 
* So this is the last bit to make this a fully functioning note-taking web app that you can use to actually record notes for Codemash this year! 
* We're going to need to implement all the CRUD routes and create a page where all this can happen, so...let's gooooo! 
* We'll need a new context, so let's add our create context to the website controller (snippet 22) 
* And we'll need to create two route handlers (snippet 23)
* this first one should be familiar by now, it's just gonna render the createNote Leaf template that we haven't actually made yet. 
* the second one is a little new, so let's break it down. This one is going to take a paramater of type Note, vapor's going to decode our form data into a Note object for us, it's going to save it, make sure it has an id, the redirect us to a page for this new note. Neat! 
* So we gotta register these routes (snippet 24)
* And we need to create a view called createNote.leaf so go ahead and add that file and drop in all this: (createNote copy and paste) 
* And add a link over in base in the navBar that will get us there (Create Nav Link c/p)
* and then build and run and...hot dog. Let's create a new note (do that) and save it, and here we get redirected to our notes page, and if we hit Home, we see this session linked on the homepage. Woot!
* But we have two other CRUD operations: update and delete. Let's tackle update first. 
* As you can guess by now, we're going to need a new context and some new handlers and new routes, over in WebsiteController 
* Context (snippet 25)
* handler (snippet 26) - This is using a convenience form of flatmap to get the note from the request's parameter, decodes the incoming data and unwraps both results; it updates the note with the new data, ensures that there's an id to set (otherwise throws an error), saves the result and redirects to the updated note's page. 
* routes (snippet 27)
* Now, we need to make some adjustments to our createNote view so that it could be reused for editing. 
* We need to add `#if(editing){value="#(note.title)"}` checks to to each of our inputs 
* and adjust the button (create with edit page on the gist) 
* then, on your notes page, we need to add a button to edit (edit button c/p). And this is where we needed that ID we passed in the context. This hung me up a little when I was working on the first version of this app--I thought, since we were working with note objects, we should have access to the id. Turns out, the stuff we work with on these web pages needs to be passed via the context. 
* We are at the last bit of the CRUD-deleting! And, hopefully, by now, you can predict what we need to do and try it yourself. So: you'll need to crerate a handler that throws a response and redirects to the homepage; add the post routet to the boot router, and add a button over on the notes page next to edit that will call the delete route with that note's id. I'm going to give you all a couple minutes to try this just...based on what we've done so far, then I'll give you the code. So if you get stuck, try and debug based on what you have learned in the last couple hours. 
* route: `webRoutes(Note.parameter, "delete", use: deleteNoteHandler)`
* handler (web12)
