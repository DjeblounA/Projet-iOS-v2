// Models.swift
// Piano Sheet Music Library

import Foundation

/// Difficulty levels for a piano piece
enum Difficulty: String, Codable, CaseIterable, Sendable {
    case beginner     = "Débutant"
    case intermediate = "Intermédiaire"
    case advanced     = "Avancé"
    case virtuoso     = "Virtuose"
}

/// Genre of a piano piece
enum Genre: String, Codable, CaseIterable, Sendable {
    case classical = "Classique"
    case jazz      = "Jazz"
    case pop       = "Pop"
    case romantic  = "Romantique"
    case baroque   = "Baroque"
    case modern    = "Moderne"
    case other     = "Autre"
}

/// Represents a piano sheet music entry in the library
struct Score: Codable, Sendable {
    var id: Int?
    var title: String
    var composer: String
    var difficulty: Difficulty
    var genre: Genre
    var notes: String

    init(
        id: Int? = nil,
        title: String,
        composer: String,
        difficulty: Difficulty,
        genre: Genre,
        notes: String
    ) {
        self.id = id
        self.title = title
        self.composer = composer
        self.difficulty = difficulty
        self.genre = genre
        self.notes = notes
    }
}

// MARK: - Extension: Display helpers
extension Score {
    /// A short human-readable summary of the score
    var summary: String {
        "\(title) — \(composer) (\(difficulty.rawValue), \(genre.rawValue))"
    }

    /// Badge color class for difficulty (used in HTML views)
    var difficultyColor: String {
        switch difficulty {
        case .beginner:     return "green"
        case .intermediate: return "orange"
        case .advanced:     return "red"
        case .virtuoso:     return "purple"
        }
    }
}
