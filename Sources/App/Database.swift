// Database.swift
// Piano Sheet Music Library
// SQLite operations

import SQLite
import Foundation

// MARK: - Schema Definition

let scoresTable = Table("scores")
let colId         = Expression<Int>("id")
let colTitle      = Expression<String>("title")
let colComposer   = Expression<String>("composer")
let colDifficulty = Expression<String>("difficulty")
let colGenre      = Expression<String>("genre")
let colNotes      = Expression<String>("notes")

// MARK: - Setup

/// Initialises the SQLite database and creates the table if it doesn't exist.
func setupDatabase() throws -> Connection {
    // Crée le fichier db.sqlite s'il n'existe pas
    let db = try Connection("db.sqlite")

    try db.run(scoresTable.create(ifNotExists: true) { t in
        t.column(colId, primaryKey: .autoincrement)
        t.column(colTitle)
        t.column(colComposer)
        t.column(colDifficulty)
        t.column(colGenre)
        t.column(colNotes)
    })

    return db
}

// MARK: - CRUD Operations

/// Returns all scores, optionally filtered by search term, difficulty, and genre.
func getAllScores(db: Connection, search: String? = nil, difficulty: String? = nil, genre: String? = nil) throws -> [Score] {
    var query = scoresTable.order(colTitle.asc)

    // Filtre par texte (Titre ou Compositeur)
    if let search = search {
        let pattern = "%\(search)%"
        query = query.filter(colTitle.like(pattern) || colComposer.like(pattern))
    }

    // Filtre par difficulté
    if let diff = difficulty, !diff.isEmpty {
        query = query.filter(colDifficulty == diff)
    }

    // Filtre par genre
    if let gen = genre, !gen.isEmpty {
        query = query.filter(colGenre == gen)
    }

    // Exécution et transformation en objets Score
    return try db.prepare(query).map { row in
        Score(
            id:         row[colId],
            title:      row[colTitle],
            composer:   row[colComposer],
            difficulty: Difficulty(rawValue: row[colDifficulty]) ?? .beginner,
            genre:      Genre(rawValue: row[colGenre]) ?? .other,
            notes:      row[colNotes]
        )
    }
}

/// Fetches a single score by its ID.
func getScore(db: Connection, id: Int) throws -> Score? {
    let query = scoresTable.filter(colId == id)
    if let row = try db.pluck(query) {
        return Score(
            id:         row[colId],
            title:      row[colTitle],
            composer:   row[colComposer],
            difficulty: Difficulty(rawValue: row[colDifficulty]) ?? .beginner,
            genre:      Genre(rawValue: row[colGenre]) ?? .other,
            notes:      row[colNotes]
        )
    }
    return nil
}

/// Inserts a new score into the database.
func createScore(db: Connection, score: Score) throws {
    let insert = scoresTable.insert(
        colTitle      <- score.title,
        colComposer   <- score.composer,
        colDifficulty <- score.difficulty.rawValue,
        colGenre      <- score.genre.rawValue,
        colNotes      <- score.notes
    )
    try db.run(insert)
}

/// Updates an existing score.
func updateScore(db: Connection, id: Int, score: Score) throws {
    let target = scoresTable.filter(colId == id)
    let update = target.update(
        colTitle      <- score.title,
        colComposer   <- score.composer,
        colDifficulty <- score.difficulty.rawValue,
        colGenre      <- score.genre.rawValue,
        colNotes      <- score.notes
    )
    try db.run(update)
}

/// Deletes a score from the database.
func deleteScore(db: Connection, id: Int) throws {
    let target = scoresTable.filter(colId == id)
    try db.run(target.delete())
}