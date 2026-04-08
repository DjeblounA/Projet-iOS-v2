import Foundation
import Hummingbird

// connexion à la base de données avec gestion de la concurrence swift 6
nonisolated(unsafe) let db = try setupDatabase()

// configuration et lancement de l'application
let router = buildRouter()
let app = Application(
    responder: router.buildResponder(),
    configuration: .init(address: .hostname("0.0.0.0", port: 8080))
)

try await app.runService()

// définition des routes du serveur
func buildRouter() -> Router<BasicRequestContext> {
    let router = Router(context: BasicRequestContext.self)

    // affichage de la bibliothèque avec prise en charge des filtres
router.get("/") { request, context -> Response in
    // on récupère les filtres depuis l'URL (?search=...&difficulty=...&genre=...)
    let search = request.uri.queryParameters.get("search")
    let difficulty = request.uri.queryParameters.get("difficulty")
    let genre = request.uri.queryParameters.get("genre")
    
    // on passe TOUS les paramètres à la fonction de base de données
    let scores = try getAllScores(db: db, search: search, difficulty: difficulty, genre: genre)
    
    // on renvoie les valeurs à la vue pour que les menus déroulants restent sélectionnés
    let html = renderIndex(scores: scores, search: search ?? "", difficulty: difficulty ?? "", genre: genre ?? "")
    
    return Response(
        status: .ok, 
        headers: [.contentType: "text/html; charset=utf-8"],
        body: .init(byteBuffer: .init(string: html)))
}

    // affichage du formulaire de création
    router.get("/score/new") { _, _ -> Response in
        let html = renderNewForm()
        return Response(
            status: .ok, 
            headers: [.contentType: "text/html; charset=utf-8"],
            body: .init(byteBuffer: .init(string: html)))
    }

    // consultation des détails d'une partition via son identifiant
    router.get("/score/:id") { request, context -> Response in
        guard let idStr = context.parameters.get("id"),
              let id = Int(idStr),
              let score = try getScore(db: db, id: id)
        else {
            return Response(status: .notFound, body: .init(byteBuffer: .init(string: "partition introuvable")))
        }
        let html = renderDetail(score: score)
        return Response(
            status: .ok, 
            headers: [.contentType: "text/html; charset=utf-8"],
            body: .init(byteBuffer: .init(string: html)))
    }

    // traitement de l'ajout d'une nouvelle partition
    router.post("/create") { request, context -> Response in
        let bodyBuffer = try await request.body.collect(upTo: 1_048_576)
        let bodyString = String(buffer: bodyBuffer)
        
        guard let params = parseFormBody(bodyString) else {
            return Response(status: .badRequest)
        }

        let score = Score(
            id: nil,
            title: params["title"] ?? "",
            composer: params["composer"] ?? "",
            difficulty: Difficulty(rawValue: params["difficulty"] ?? "") ?? .beginner,
            genre: Genre(rawValue: params["genre"] ?? "") ?? .other,
            notes: params["notes"] ?? ""
        )
        
        try createScore(db: db, score: score)
        return Response(status: .seeOther, headers: [.location: "/"])
    }

    // enregistrement des modifications d'une partition existante
    router.post("/update/:id") { request, context -> Response in
        guard let idStr = context.parameters.get("id"), let id = Int(idStr) else {
            return Response(status: .badRequest)
        }

        let bodyBuffer = try await request.body.collect(upTo: 1_048_576)
        let bodyString = String(buffer: bodyBuffer)
        
        guard let params = parseFormBody(bodyString) else {
            return Response(status: .badRequest)
        }

        let updated = Score(
            id: id,
            title: params["title"] ?? "",
            composer: params["composer"] ?? "",
            difficulty: Difficulty(rawValue: params["difficulty"] ?? "") ?? .beginner,
            genre: Genre(rawValue: params["genre"] ?? "") ?? .other,
            notes: params["notes"] ?? ""
        )

        try updateScore(db: db, id: id, score: updated)
        return Response(status: .seeOther, headers: [.location: "/score/\(id)"])
    }

    // suppression d'une entrée de la base de données
    router.post("/delete/:id") { request, context -> Response in
        if let idStr = context.parameters.get("id"), let id = Int(idStr) {
            try deleteScore(db: db, id: id)
        }
        return Response(status: .seeOther, headers: [.location: "/"])
    }

    return router
}

// utilitaire pour extraire les données des formulaires html
func parseFormBody(_ body: String) -> [String: String]? {
    var result: [String: String] = [:]
    for pair in body.split(separator: "&") {
        let parts = pair.split(separator: "=", maxSplits: 1)
        guard parts.count == 2 else { continue }
        let key = String(parts[0]).removingPercentEncoding?.replacingOccurrences(of: "+", with: " ") ?? ""
        let value = String(parts[1]).removingPercentEncoding?.replacingOccurrences(of: "+", with: " ") ?? ""
        result[key] = value
    }
    return result.isEmpty ? nil : result
}