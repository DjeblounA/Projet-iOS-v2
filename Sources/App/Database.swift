// Database.swift
// Piano Sheet Music Library

import Foundation
import SQLite

// MARK: - Table & Column definitions
let scoresTable = Table("scores")

let colId = Expression<Int>("id")
let colTitle = Expression<String>("title")
let colComposer = Expression<String>("composer")
let colDifficulty = Expression<String>("difficulty")
let colGenre = Expression<String>("genre")
let colNotes = Expression<String>("notes")

// MARK: - Database setup

/// Opens (or creates) the SQLite database and creates the scores table if needed.
func setupDatabase() throws -> Connection {
    let db = try Connection("scores.sqlite3")

    try db.run(
        scoresTable.create(ifNotExists: true) { t in
            t.column(colId, primaryKey: .autoincrement)
            t.column(colTitle)
            t.column(colComposer)
            t.column(colDifficulty)
            t.column(colGenre)
            t.column(colNotes)
        })

    return db
}

// MARK: - CRUD operations

/// Returns all scores, optionally filtered by a search term (title or composer).
// Dans Database.swift
func getAllScores(
    db: Connection, search: String? = nil, difficulty: String? = nil, genre: String? = nil
) throws -> [Score] {
    var query = scoresTable.order(colTitle.asc)

    // Application des filtres si présents
    if let search = search, !search.isEmpty {
        query = query.filter(colTitle.like("%\(search)%") || colComposer.like("%\(search)%"))
    }

    // On exécute la requête et on transforme chaque ligne en objet Score
    return try db.prepare(query).map { row in
        Score(
            id: row[colId],
            title: row[colTitle],
            composer: row[colComposer],
            difficulty: Difficulty(rawValue: row[colDifficulty]) ?? .beginner,
            genre: Genre(rawValue: row[colGenre]) ?? .other,
            notes: row[colNotes]
        )
    }
}
/// Returns a single score by its id, or nil if not found.
func getScore(db: Connection, id: Int) throws -> Score? {
    let query = scoresTable.filter(colId == id)
    return try db.prepare(query).map { row in
        Score(
            id: row[colId],
            title: row[colTitle],
            composer: row[colComposer],
            difficulty: Difficulty(rawValue: row[colDifficulty]) ?? .beginner,
            genre: Genre(rawValue: row[colGenre]) ?? .other,
            notes: row[colNotes]
        )
    }.first
}

/// Inserts a new score and returns its new id.
@discardableResult
func createScore(db: Connection, score: Score) throws -> Int64 {
    let insert = scoresTable.insert(
        colTitle <- score.title,
        colComposer <- score.composer,
        colDifficulty <- score.difficulty.rawValue,
        colGenre <- score.genre.rawValue,
        colNotes <- score.notes
    )
    return try db.run(insert)
}

/// Updates an existing score identified by its id.
func updateScore(db: Connection, id: Int, score: Score) throws {
    let row = scoresTable.filter(colId == id)
    try db.run(
        row.update(
            colTitle <- score.title,
            colComposer <- score.composer,
            colDifficulty <- score.difficulty.rawValue,
            colGenre <- score.genre.rawValue,
            colNotes <- score.notes
        ))
}

/// Deletes a score by its id.
func deleteScore(db: Connection, id: Int) throws {
    let row = scoresTable.filter(colId == id)
    try db.run(row.delete())
}
