import Foundation
import Hummingbird

// MARK: - Database initialisation
// L'ajout de nonisolated(unsafe) règle l'erreur de "main actor-isolated"
nonisolated(unsafe) let db = try setupDatabase()

// MARK: - Application setup
let router = buildRouter()
let app = Application(
    responder: router.buildResponder(),
    configuration: .init(address: .hostname("0.0.0.0", port: 8080))
)

try await app.runService()

// MARK: - Router

func buildRouter() -> Router<BasicRequestContext> {
    let router = Router(context: BasicRequestContext.self)

    // ── GET / ── Liste des scores
    router.get("/") { request, context -> Response in
        let search = request.uri.queryParameters.get("search")
        let scores = try getAllScores(db: db, search: search)
        let html = renderIndex(scores: scores, search: search ?? "")
        return Response(
            status: .ok, headers: [.contentType: "text/html; charset=utf-8"],
            body: .init(byteBuffer: .init(string: html)))
    }

    // ── GET /score/new ── Formulaire
    router.get("/score/new") { _, _ -> Response in
        let html = renderNewForm()
        return Response(
            status: .ok, headers: [.contentType: "text/html; charset=utf-8"],
            body: .init(byteBuffer: .init(string: html)))
    }

    // ── GET /score/:id ── Détails
    router.get("/score/:id") { request, context -> Response in
        // CORRECTION ICI : on utilise context.parameters
        guard let idStr = context.parameters.get("id"),
            let id = Int(idStr),
            let score = try getScore(db: db, id: id)
        else {
            return Response(
                status: .notFound, body: .init(byteBuffer: .init(string: "Introuvable")))
        }
        let html = renderDetail(score: score)
        return Response(
            status: .ok, headers: [.contentType: "text/html; charset=utf-8"],
            body: .init(byteBuffer: .init(string: html)))
    }

    // ── POST /create ──
    router.post("/create") { request, context -> Response in
        // Utilisation du décodeur intégré pour les formulaires standard
        struct CreateScoreRequest: Decodable {
            let title: String
            let composer: String
            let notes: String
            let difficulty: String
            let genre: String
        }

        let input = try await request.decode(as: CreateScoreRequest.self, context: context)
        let score = Score(
            id: nil,
            title: input.title,
            composer: input.composer,
            difficulty: Difficulty(rawValue: input.difficulty) ?? .beginner,
            genre: Genre(rawValue: input.genre) ?? .other,
            notes: input.notes
        )
        try createScore(db: db, score: score)
        return Response(status: .seeOther, headers: [.location: "/"])
    }

    // ── POST /update/:id ──
    router.post("/update/:id") { request, context -> Response in
        guard let idStr = context.parameters.get("id"), let id = Int(idStr) else {
            return Response(status: .badRequest)
        }

        // On définit une structure locale pour le formulaire
        struct UpdateForm: Decodable {
            let title: String
            let composer: String
            let notes: String
            let difficulty: String
            let genre: String
        }

        // HB2 gère le "collectBody" en interne lors du decode
        let input = try await request.decode(as: UpdateForm.self, context: context)

        let updated = Score(
            id: id,
            title: input.title,
            composer: input.composer,
            difficulty: Difficulty(rawValue: input.difficulty) ?? .beginner,
            genre: Genre(rawValue: input.genre) ?? .other,
            notes: input.notes
        )

        try updateScore(db: db, id: id, score: updated)
        return Response(status: .seeOther, headers: [.location: "/score/\(id)"])
    }

    // ── POST /delete/:id ──
    router.post("/delete/:id") { request, context -> Response in
        if let idStr = context.parameters.get("id"), let id = Int(idStr) {
            try deleteScore(db: db, id: id)
        }
        return Response(status: .seeOther, headers: [.location: "/"])
    }

    return router
}

// Helper pour parser le corps du formulaire si request.decode n'est pas utilisé
func parseFormBody(_ body: String) -> [String: String]? {
    var result: [String: String] = [:]
    for pair in body.split(separator: "&") {
        let parts = pair.split(separator: "=", maxSplits: 1)
        guard parts.count == 2 else { continue }
        let key =
            String(parts[0]).removingPercentEncoding?.replacingOccurrences(of: "+", with: " ") ?? ""
        let value =
            String(parts[1]).removingPercentEncoding?.replacingOccurrences(of: "+", with: " ") ?? ""
        result[key] = value
    }
    return result.isEmpty ? nil : result
}
