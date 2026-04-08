import Foundation

// structure globale de la page avec pico css et styles personnalisés
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
        --pico-primary: #4361ee;
        --pico-border-radius: 12px;
      }
      body { background-color: #f8f9fa; padding-bottom: 3rem; }
      main { padding-top: 2rem; }
      
      /* style pour les conteneurs en forme de cartes */
      .card {
        background: white;
        padding: 1.5rem;
        border-radius: var(--pico-border-radius);
        box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1);
        margin-bottom: 1.5rem;
        border: 1px solid #e9ecef;
      }

      nav.container {
        background: white;
        margin-bottom: 2rem;
        box-shadow: 0 1px 2px rgba(0,0,0,0.05);
        border-radius: 0 0 12px 12px;
      }

      .btn-delete {
        background-color: #e63946;
        border: none;
        padding: 0.4rem 1rem;
        font-size: 0.85rem;
        width: auto !important;
      }
      
      /* badges pour les niveaux de difficulté */
      .badge {
          display: inline-block;
          padding: 0.2rem 0.6rem;
          border-radius: 20px;
          font-size: 0.75rem;
          font-weight: bold;
          background: #e9ecef;
      }
      .badge-green  { background: #2d9c5a; color: white; }
      .badge-orange { background: #e07b00; color: white; }
      .badge-red    { background: #d33f3f; color: white; }
      .badge-purple { background: #7c3aed; color: white; }

      /* alignement de la barre de recherche et filtres */
      .filter-bar {
          display: grid;
          grid-template-columns: 2fr 1fr 1fr auto;
          gap: 1rem;
          align-items: end;
          margin-bottom: 2rem;
      }
    </style>
  </head>
  <body>
    <nav class="container">
      <ul><li><strong>🎹 PianoLib</strong></li></ul>
      <ul>
        <li><a href="/">Bibliothèque</a></li>
        <li><a href="/score/new" class="outline">Ajouter</a></li>
      </ul>
    </nav>
    <main class="container">\(body)</main>
  </body>
  </html>
  """
}

// page d'accueil avec recherche filtrée et affichage en cartes
func renderIndex(scores: [Score], search: String = "", difficulty: String = "", genre: String = "") -> String {
  
  // préparation des menus de sélection pour les filtres
  let diffOptions = "<option value=''>Difficultés</option>" + Difficulty.allCases.map { 
    "<option value='\($0.rawValue)' \($0.rawValue == difficulty ? "selected" : "")>\($0.rawValue)</option>" 
  }.joined()
  
  let genreOptions = "<option value=''>Genres</option>" + Genre.allCases.map { 
    "<option value='\($0.rawValue)' \($0.rawValue == genre ? "selected" : "")>\($0.rawValue)</option>" 
  }.joined()

  let content = scores.isEmpty
    ? "<article class='card'><p style='text-align:center;'>aucune partition trouvée</p></article>"
    : scores.map { score in
      """
      <article class="card">
          <div style="display: flex; justify-content: space-between; align-items: center;">
              <div>
                  <h4 style="margin:0">\(escapeHTML(score.title))</h4>
                  <p style="margin:0; color:#6c757d;">\(escapeHTML(score.composer)) • <small>\(score.genre.rawValue)</small></p>
              </div>
              <div style="display: flex; align-items: center; gap: 1rem;">
                  <span class="badge badge-\(score.difficultyColor)">\(score.difficulty.rawValue)</span>
                  <a href="/score/\(score.id ?? 0)" role="button" class="outline secondary" style="margin:0; padding: 0.4rem 0.8rem; font-size: 0.8rem;">Détails</a>
              </div>
          </div>
      </article>
      """
    }.joined()

  return renderLayout(title: "Accueil", body: """
      <form action="/" method="get" class="filter-bar">
          <label>Recherche <input type="search" name="search" placeholder="titre, auteur..." value="\(escapeHTML(search))"></label>
          <label>Niveau <select name="difficulty">\(diffOptions)</select></label>
          <label>Genre <select name="genre">\(genreOptions)</select></label>
          <button type="submit">OK</button>
      </form>
      <section>\(content)</section>
  """)
}

// vue détaillée pour modifier ou supprimer une partition
func renderDetail(score: Score, errorMessage: String? = nil) -> String {
  let id = score.id ?? 0
  let errorHTML = errorMessage.map { "<p style='color:red;'>⚠️ \($0)</p>" } ?? ""

  return renderLayout(title: score.title, body: """
    <nav aria-label="breadcrumb">
      <ul>
        <li><a href="/">Bibliothèque</a></li>
        <li>\(escapeHTML(score.title))</li>
      </ul>
    </nav>
    <div class="card">
        <h2>Modifier la partition</h2>
        \(errorHTML)
        <form method="post" action="/update/\(id)">
            <div style="display:grid; grid-template-columns: 1fr 1fr; gap:1rem;">
                <label>Titre <input type="text" name="title" value="\(escapeHTML(score.title))" required></label>
                <label>Auteur <input type="text" name="composer" value="\(escapeHTML(score.composer))" required></label>
            </div>
            <div style="display:grid; grid-template-columns: 1fr 1fr; gap:1rem;">
                <label>Difficulté
                    <select name="difficulty">
                        \(Difficulty.allCases.map { "<option value='\($0.rawValue)' \($0 == score.difficulty ? "selected" : "")>\($0.rawValue)</option>" }.joined())
                    </select>
                </label>
                <label>Genre
                    <select name="genre">
                        \(Genre.allCases.map { "<option value='\($0.rawValue)' \($0 == score.genre ? "selected" : "")>\($0.rawValue)</option>" }.joined())
                    </select>
                </label>
            </div>
            <label>Notes <textarea name="notes" rows="4">\(escapeHTML(score.notes))</textarea></label>
            <button type="submit">Enregistrer</button>
        </form>
        <hr>
        <form action="/delete/\(id)" method="post" onsubmit="return confirm('Supprimer définitivement ?');">
            <button type="submit" class="btn-delete">Supprimer</button>
        </form>
    </div>
    """)
}

// formulaire pour l'ajout d'un nouveau morceau
func renderNewForm(prefill: Score? = nil, errorMessage: String? = nil) -> String {
  return renderLayout(title: "Ajouter", body: """
    <h2>Nouvelle partition</h2>
    <div class="card">
        <form method="post" action="/create">
            <label>Titre <input type="text" name="title" placeholder="titre" required></label>
            <label>Auteur <input type="text" name="composer" placeholder="compositeur" required></label>
            <div style="display:grid; grid-template-columns: 1fr 1fr; gap:1rem;">
                <label>Difficulté
                    <select name="difficulty">
                        \(Difficulty.allCases.map { "<option value='\($0.rawValue)'>\($0.rawValue)</option>" }.joined())
                    </select>
                </label>
                <label>Genre
                    <select name="genre">
                        \(Genre.allCases.map { "<option value='\($0.rawValue)'>\($0.rawValue)</option>" }.joined())
                    </select>
                </label>
            </div>
            <button type="submit">Ajouter à la bibliothèque</button>
        </form>
    </div>
    """)
}

// fonction utilitaire pour sécuriser le texte affiché
func escapeHTML(_ string: String) -> String {
  string.replacingOccurrences(of: "&", with: "&amp;")
    .replacingOccurrences(of: "<", with: "&lt;")
    .replacingOccurrences(of: ">", with: "&gt;")
    .replacingOccurrences(of: "\"", with: "&quot;")
}