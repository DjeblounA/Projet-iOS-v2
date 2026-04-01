// main.swift
// Piano Sheet Music Library
// Hummingbird 2 + SQLite

import Hummingbird
import Foundation

// MARK: - Database initialisation

let db = try setupDatabase()

// MARK: - Application setup

let app = Application(
    router: buildRouter(),
    configuration: .init(address: .hostname("127.0.0.1", port: 8080))
)

try await app.runService()

// MARK: - Router

func buildRouter() -> Router<BasicRequestContext> {
    let router = Router(context: BasicRequestContext.self)

    // ── GET / ── List all scores (with optional search) ──────────────────────
    router.get("/") { request, _ -> Response in
        let search = request.uri.queryParameters.get("search") ?? ""
        let scores = try getAllScores(db: db, search: search.isEmpty ? nil : search)
        let html   = renderIndex(scores: scores, search: search)
        return Response(status: .ok, headers: [.contentType: "text/html; charset=utf-8"],
                        body: .init(byteBuffer: .init(string: html)))
    }

    // ── GET /score/new ── New score form ──────────────────────────────────────
    router.get("/score/new") { _, _ -> Response in
        let html = renderNewForm()
        return Response(status: .ok, headers: [.contentType: "text/html; charset=utf-8"],
                        body: .init(byteBuffer: .init(string: html)))
    }

    // ── GET /score/:id ── Detail page ─────────────────────────────────────────
    router.get("/score/:id") { request, _ -> Response in
        guard let idStr = request.uri.parameters.get("id"),
              let id    = Int(idStr),
              let score = try getScore(db: db, id: id)
        else {
            return Response(status: .notFound,
                            body: .init(byteBuffer: .init(string: "Partition introuvable.")))
        }
        let html = renderDetail(score: score)
        return Response(status: .ok, headers: [.contentType: "text/html; charset=utf-8"],
                        body: .init(byteBuffer: .init(string: html)))
    }

    // ── POST /create ── Create a new score ───────────────────────────────────
    router.post("/create") { request, _ -> Response in
        // Decode form body
        guard let body  = try? await request.body.collect(upTo: 1_048_576),
              let params = parseFormBody(String(buffer: body))
        else {
            let html = renderNewForm(errorMessage: "Impossible de lire le formulaire.")
            return Response(status: .badRequest, headers: [.contentType: "text/html; charset=utf-8"],
                            body: .init(byteBuffer: .init(string: html)))
        }

        // Validate required fields
        let title    = params["title"]?.trimmingCharacters(in: .whitespaces) ?? ""
        let composer = params["composer"]?.trimmingCharacters(in: .whitespaces) ?? ""

        guard !title.isEmpty, !composer.isEmpty else {
            let prefill = Score(
                title:      title,
                composer:   composer,
                difficulty: Difficulty(rawValue: params["difficulty"] ?? "") ?? .beginner,
                genre:      Genre(rawValue: params["genre"] ?? "") ?? .other,
                notes:      params["notes"] ?? ""
            )
            let html = renderNewForm(prefill: prefill,
                                     errorMessage: "Le titre et le compositeur sont obligatoires.")
            return Response(status: .unprocessableContent,
                            headers: [.contentType: "text/html; charset=utf-8"],
                            body: .init(byteBuffer: .init(string: html)))
        }

        let score = Score(
            title:      title,
            composer:   composer,
            difficulty: Difficulty(rawValue: params["difficulty"] ?? "") ?? .beginner,
            genre:      Genre(rawValue: params["genre"] ?? "") ?? .other,
            notes:      params["notes"] ?? ""
        )

        try createScore(db: db, score: score)

        return Response(
            status: .seeOther,
            headers: [.location: "/"]
        )
    }

    // ── POST /update/:id ── Update an existing score ─────────────────────────
    router.post("/update/:id") { request, _ -> Response in
        guard let idStr = request.uri.parameters.get("id"),
              let id    = Int(idStr)
        else {
            return Response(status: .badRequest,
                            body: .init(byteBuffer: .init(string: "Identifiant invalide.")))
        }

        guard let body  = try? await request.body.collect(upTo: 1_048_576),
              let params = parseFormBody(String(buffer: body))
        else {
            return Response(status: .badRequest,
                            body: .init(byteBuffer: .init(string: "Formulaire illisible.")))
        }

        let title    = params["title"]?.trimmingCharacters(in: .whitespaces) ?? ""
        let composer = params["composer"]?.trimmingCharacters(in: .whitespaces) ?? ""

        guard !title.isEmpty, !composer.isEmpty else {
            if let existing = try getScore(db: db, id: id) {
                let html = renderDetail(score: existing,
                                        errorMessage: "Le titre et le compositeur sont obligatoires.")
                return Response(status: .unprocessableContent,
                                headers: [.contentType: "text/html; charset=utf-8"],
                                body: .init(byteBuffer: .init(string: html)))
            }
            return Response(status: .notFound,
                            body: .init(byteBuffer: .init(string: "Partition introuvable.")))
        }

        let updated = Score(
            id:         id,
            title:      title,
            composer:   composer,
            difficulty: Difficulty(rawValue: params["difficulty"] ?? "") ?? .beginner,
            genre:      Genre(rawValue: params["genre"] ?? "") ?? .other,
            notes:      params["notes"] ?? ""
        )
        try updateScore(db: db, id: id, score: updated)

        return Response(status: .seeOther, headers: [.location: "/score/\(id)"])
    }

    // ── POST /delete/:id ── Delete a score ────────────────────────────────────
    router.post("/delete/:id") { request, _ -> Response in
        guard let idStr = request.uri.parameters.get("id"),
              let id    = Int(idStr)
        else {
            return Response(status: .badRequest,
                            body: .init(byteBuffer: .init(string: "Identifiant invalide.")))
        }
        try deleteScore(db: db, id: id)
        return Response(status: .seeOther, headers: [.location: "/"])
    }

    return router
}

// MARK: - Form parsing helper

/// Parses a URL-encoded form body (key=value&key2=value2) into a dictionary.
func parseFormBody(_ body: String) -> [String: String]? {
    var result: [String: String] = [:]
    for pair in body.split(separator: "&") {
        let parts = pair.split(separator: "=", maxSplits: 1)
        guard parts.count == 2 else { continue }
        let key   = String(parts[0]).removingPercentEncoding?.replacingOccurrences(of: "+", with: " ") ?? ""
        let value = String(parts[1]).removingPercentEncoding?.replacingOccurrences(of: "+", with: " ") ?? ""
        result[key] = value
    }
    return result.isEmpty ? nil : result
}
