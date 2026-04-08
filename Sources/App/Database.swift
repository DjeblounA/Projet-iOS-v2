import Foundation
import SQLite

// définition de la table et des colonnes sqlite
let scoresTable = Table("scores")
let colId = Expression<Int>("id")
let colTitle = Expression<String>("title")
let colComposer = Expression<String>("composer")
let colDifficulty = Expression<String>("difficulty")
let colGenre = Expression<String>("genre")
let colNotes = Expression<String>("notes")

// initialisation de la base de données
func setupDatabase() throws -> Connection {
    let db = try Connection("scores.sqlite3")

    // création de la table si elle n'existe pas encore
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

// récupération des partitions avec filtres multiples
func getAllScores(
    db: Connection, search: String? = nil, difficulty: String? = nil, genre: String? = nil
) throws -> [Score] {
    var query = scoresTable.order(colTitle.asc)

    // filtre par texte (titre ou auteur)
    if let search = search, !search.isEmpty {
        query = query.filter(colTitle.like("%\(search)%") || colComposer.like("%\(search)%"))
    }

    // filtre par difficulté (si une valeur est sélectionnée et n'est pas vide)
    if let difficulty = difficulty, !difficulty.isEmpty {
        query = query.filter(colDifficulty == difficulty)
    }

    // filtre par genre musical
    if let genre = genre, !genre.isEmpty {
        query = query.filter(colGenre == genre)
    }

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

// charger une partition spécifique via son id
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

// ajout d'un nouvel enregistrement
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

// mise à jour des données d'une partition
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

// suppression d'une partition
func deleteScore(db: Connection, id: Int) throws {
    let row = scoresTable.filter(colId == id)
    try db.run(row.delete())
}