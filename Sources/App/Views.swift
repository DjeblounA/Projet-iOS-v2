import Foundation

// MARK: - Shared layout

/// Wraps any page body inside the common HTML shell with Pico CSS.
func renderLayout(title: String, body: String) -> String {
    """
    <!DOCTYPE html>
    <html lang="fr" data-theme="light">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>\(title) — PianoLib</title>
      <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css">
      <style>
        :root {
          --pico-primary: #6246ea;
          --pico-primary-hover: #4f35c7;
        }
        body { padding-bottom: 3rem; }
        nav.top-nav {
          display: flex;
          align-items: center;
          gap: 1.5rem;
          padding: 1rem 0;
          margin-bottom: 2rem;
          border-bottom: 1px solid var(--pico-muted-border-color);
        }
        nav.top-nav a { text-decoration: none; font-weight: 600; color: var(--pico-primary); }
        nav.top-nav .brand { font-size: 1.25rem; margin-right: auto; }
        
        /* Barre de recherche améliorée */
        .search-bar { 
          display: flex; 
          flex-wrap: wrap; 
          gap: 0.5rem; 
          margin-bottom: 1.5rem; 
          align-items: flex-start;
        }
        .search-bar input[type="search"] { 
          flex: 2; 
          min-width: 200px;
          margin-bottom: 0; 
        }
        .search-bar select { 
          flex: 1; 
          min-width: 150px;
          margin-bottom: 0;
        }
        .search-bar button { 
          width: auto; 
          margin-bottom: 0;
          padding: 0 1.5rem;
        }
        .search-bar .clear-btn {
          padding: 0 1rem;
        }

        .badge {
          display: inline-block;
          padding: 0.15rem 0.55rem;
          border-radius: 999px;
          font-size: 0.75rem;
          font-weight: 600;
          color: #fff;
        }
        .badge-green  { background: #2d9c5a; }
        .badge-orange { background: #e07b00; }
        .badge-red    { background: #d33f3f; }
        .badge-purple { background: #7c3aed; }
        table { width: 100%; }
        .actions form { display: inline; }
        .actions button { margin: 0 0.2rem; }
      </style>
    </head>
    <body>
      <main class="container">
        <nav class="top-nav">
          <a href="/" class="brand">🎹 PianoLib</a>
          <a href="/">Bibliothèque</a>
          <a href="/score/new">Ajouter</a>
        </nav>
        \(body)
      </main>
    </body>
    </html>
    """
}

// MARK: - Index page (list + search)

/// Renders the main library page with all scores and a search bar.
func renderIndex(scores: [Score], search: String = "", difficulty: String = "", genre: String = "") -> String {
    
    // Génération des options de filtre
    let diffOptions = [""] + Difficulty.allCases.map { $0.rawValue }
    let diffSelect = diffOptions.map { d in
        let label = d.isEmpty ? "Toutes difficultés" : d
        let selected = d == difficulty ? " selected" : ""
        return "<option value='\(d)'\(selected)>\(label)</option>"
    }.joined()

    let genreOptions = [""] + Genre.allCases.map { $0.rawValue }
    let genreSelect = genreOptions.map { g in
        let label = g.isEmpty ? "Tous les genres" : g
        let selected = g == genre ? " selected" : ""
        return "<option value='\(g)'\(selected)>\(label)</option>"
    }.joined()

    let searchBar = """
    <form method="get" action="/" class="search-bar">
      <input type="search" name="search" placeholder="Titre, compositeur..." value="\(escapeHTML(search))">
      
      <select name="difficulty">
        \(diffSelect)
      </select>
      
      <select name="genre">
        \(genreSelect)
      </select>

      <button type="submit">Rechercher</button>
      
      \( (search.isEmpty && difficulty.isEmpty && genre.isEmpty) ? "" : 
         "<a href='/' role='button' class='secondary outline clear-btn'>✕</a>" )
    </form>
    """

    let rows: String
    if scores.isEmpty {
        rows = "<tr><td colspan='5' style='text-align:center;color:var(--pico-muted-color)'>Aucune partition trouvée.</td></tr>"
    } else {
        rows = scores.map { s in
            let id = s.id ?? 0
            return """
            <tr>
              <td><a href="/score/\(id)">\(escapeHTML(s.title))</a></td>
              <td>\(escapeHTML(s.composer))</td>
              <td><span class="badge badge-\(s.difficultyColor)">\(s.difficulty.rawValue)</span></td>
              <td>\(s.genre.rawValue)</td>
              <td class="actions">
                <a href="/score/\(id)" role="button" class="outline" style="padding:0.25rem 0.6rem;font-size:0.8rem">Détails</a>
                <form method="post" action="/delete/\(id)" onsubmit="return confirm('Supprimer cette partition ?')">
                  <button type="submit" class="secondary" style="padding:0.25rem 0.6rem;font-size:0.8rem">Supprimer</button>
                </form>
              </td>
            </tr>
            """
        }.joined()
    }

    let table = """
    <div class="overflow-auto">
        <table>
          <thead>
            <tr>
              <th>Titre</th>
              <th>Compositeur</th>
              <th>Difficulté</th>
              <th>Genre</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>\(rows)</tbody>
        </table>
    </div>
    """

    let body = """
    <h1>Ma bibliothèque</h1>
    \(searchBar)
    \(table)
    <p style="margin-top:1.5rem">
      <a href="/score/new" role="button">＋ Ajouter une partition</a>
    </p>
    """

    return renderLayout(title: "Bibliothèque", body: body)
}

// MARK: - Detail / Edit page

/// Renders the detail page for a single score, with an inline edit form.
func renderDetail(score: Score, errorMessage: String? = nil) -> String {
    let id = score.id ?? 0
    let errorHTML = errorMessage.map {
        "<div role='alert' style='color:var(--pico-del-color);margin-bottom:1rem'>⚠️ \(escapeHTML($0))</div>"
    } ?? ""

    let body = """
    <a href="/">&larr; Retour à la bibliothèque</a>
    <h2 style="margin-top:1rem">\(escapeHTML(score.title))</h2>
    <p><small>\(escapeHTML(score.composer)) &middot; \(score.genre.rawValue)</small>
       &nbsp;<span class="badge badge-\(score.difficultyColor)">\(score.difficulty.rawValue)</span></p>
    <hr>
    <h3>Modifier la partition</h3>
    \(errorHTML)
    <form method="post" action="/update/\(id)">
      \(renderScoreFields(score: score))
      <button type="submit">💾 Enregistrer les modifications</button>
      <a href="/" role="button" class="secondary outline" style="margin-left:0.75rem">Annuler</a>
    </form>
    <hr>
    <form method="post" action="/delete/\(id)" onsubmit="return confirm('Supprimer cette partition définitivement ?')">
      <button type="submit" class="contrast">🗑 Supprimer cette partition</button>
    </form>
    """

    return renderLayout(title: escapeHTML(score.title), body: body)
}

// MARK: - New score form

/// Renders the form for creating a new score.
func renderNewForm(prefill: Score? = nil, errorMessage: String? = nil) -> String {
    let empty = Score(title: "", composer: "", difficulty: .beginner, genre: .classical, notes: "")
    let score = prefill ?? empty

    let errorHTML = errorMessage.map {
        "<div role='alert' style='color:var(--pico-del-color);margin-bottom:1rem'>⚠️ \(escapeHTML($0))</div>"
    } ?? ""

    let body = """
    <a href="/">&larr; Retour à la bibliothèque</a>
    <h2 style="margin-top:1rem">Ajouter une partition</h2>
    \(errorHTML)
    <form method="post" action="/create">
      \(renderScoreFields(score: score))
      <button type="submit">＋ Ajouter à la bibliothèque</button>
    </form>
    """

    return renderLayout(title: "Nouvelle partition", body: body)
}

// MARK: - Reusable form fields

/// Returns the shared form fields for both create and update forms.
private func renderScoreFields(score: Score) -> String {
    let difficultyOptions = Difficulty.allCases.map { d in
        let selected = d == score.difficulty ? " selected" : ""
        return "<option value='\(d.rawValue)'\(selected)>\(d.rawValue)</option>"
    }.joined()

    let genreOptions = Genre.allCases.map { g in
        let selected = g == score.genre ? " selected" : ""
        return "<option value='\(g.rawValue)'\(selected)>\(g.rawValue)</option>"
    }.joined()

    return """
    <label>
      Titre *
      <input type="text" name="title" value="\(escapeHTML(score.title))" required placeholder="ex. Clair de Lune">
    </label>
    <label>
      Compositeur *
      <input type="text" name="composer" value="\(escapeHTML(score.composer))" required placeholder="ex. Claude Debussy">
    </label>
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:1rem">
      <label>
        Difficulté
        <select name="difficulty">\(difficultyOptions)</select>
      </label>
      <label>
        Genre
        <select name="genre">\(genreOptions)</select>
      </label>
    </div>
    <label>
      Notes libres
      <textarea name="notes" placeholder="Conseils d'interprétation, doigtés, édition recommandée…" rows="4">\(escapeHTML(score.notes))</textarea>
    </label>
    """
}

// MARK: - Utility

/// Escapes HTML special characters to prevent injection.
func escapeHTML(_ string: String) -> String {
    string
        .replacingOccurrences(of: "&",  with: "&amp;")
        .replacingOccurrences(of: "<",  with: "&lt;")
        .replacingOccurrences(of: ">",  with: "&gt;")
        .replacingOccurrences(of: "\"", with: "&quot;")
        .replacingOccurrences(of: "'",  with: "&#39;")
}
