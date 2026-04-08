import Foundation

// MARK: - Shared layout

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
      
      .card {
        background: white;
        padding: 1.5rem;
        border-radius: var(--pico-border-radius);
        box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1), 0 2px 4px -1px rgba(0,0,0,0.06);
        margin-bottom: 1.5rem;
        border: 1px solid #e9ecef;
      }

      nav.container {
        background: white;
        margin-bottom: 2rem;
        padding: 0 1rem;
        box-shadow: 0 1px 2px rgba(0,0,0,0.05);
        border-radius: 0 0 12px 12px;
      }

      .btn-delete {
        background-color: #e63946;
        border: none;
        padding: 0.4rem 1rem;
        font-size: 0.85rem;
        width: auto !important;
        display: inline-flex;
        align-items: center;
        margin: 0;
      }
      .btn-delete:hover { background-color: #d62828; }
      
      .score-meta { font-size: 0.9rem; color: #6c757d; }
      
      .badge {
          display: inline-block;
          padding: 0.2rem 0.6rem;
          border-radius: 20px;
          font-size: 0.75rem;
          font-weight: bold;
          background: #e9ecef;
          color: #495057;
      }
      .badge-green  { background: #2d9c5a; color: white; }
      .badge-orange { background: #e07b00; color: white; }
      .badge-red    { background: #d33f3f; color: white; }
      .badge-purple { background: #7c3aed; color: white; }
    </style>
  </head>
  <body>
    <nav class="container">
      <ul>
        <li><strong>🎹 PianoLib</strong></li>
      </ul>
      <ul>
        <li><a href="/">Bibliothèque</a></li>
        <li><a href="/score/new" class="outline">Ajouter</a></li>
      </ul>
    </nav>
    <main class="container">
      \(body)
    </main>
  </body>
  </html>
  """
}

// MARK: - Index page

func renderIndex(scores: [Score], search: String = "", difficulty: String = "", genre: String = "")
  -> String
{
  let content =
    scores.isEmpty
    ? "<article class='card'><p style='text-align:center;margin:0;'>Aucune partition trouvée.</p></article>"
    : scores.map { score in
      """
      <article class="card">
          <div style="display: flex; justify-content: space-between; align-items: center;">
              <div>
                  <h4 style="margin:0">\(escapeHTML(score.title))</h4>
                  <div class="score-meta">
                      \(escapeHTML(score.composer)) • <span class="badge">\(score.genre.rawValue)</span>
                  </div>
              </div>
              <div style="display: flex; align-items: center; gap: 1rem;">
                  <span class="badge badge-\(score.difficultyColor)">\(score.difficulty.rawValue)</span>
                  <a href="/score/\(score.id ?? 0)" role="button" class="outline secondary" style="padding: 0.4rem 0.8rem; font-size: 0.8rem; margin:0;">Détails</a>
              </div>
          </div>
      </article>
      """
    }.joined()

  return renderLayout(
    title: "Accueil",
    body: """
          <header style="margin-bottom: 2rem;">
              <h2>Ma Bibliothèque</h2>
              <form action="/" method="get" style="display: flex; gap: 10px; margin-bottom: 0;">
                  <input type="search" name="search" placeholder="Rechercher..." value="\(escapeHTML(search))" style="margin-bottom:0;">
                  <button type="submit" style="width: auto; margin-bottom:0;">Rechercher</button>
              </form>
          </header>
          <section>
              \(content)
          </section>
      """)
}

// MARK: - Detail page

func renderDetail(score: Score, errorMessage: String? = nil) -> String {
  let id = score.id ?? 0
  let errorHTML = errorMessage.map { "<p style='color:#e63946;'>⚠️ \(escapeHTML($0))</p>" } ?? ""

  let body = """
    <nav aria-label="breadcrumb">
      <ul>
        <li><a href="/">Bibliothèque</a></li>
        <li>\(escapeHTML(score.title))</li>
      </ul>
    </nav>

    <div class="card">
        <header style="display: flex; justify-content: space-between; align-items: start; margin-bottom: 1rem;">
            <div>
                <h1 style="margin-bottom: 0;">\(escapeHTML(score.title))</h1>
                <p style="font-size: 1.2rem; color: #6c757d; margin:0;">\(escapeHTML(score.composer))</p>
            </div>
            <span class="badge badge-\(score.difficultyColor)" style="padding: 0.5rem 1rem;">
                \(score.difficulty.rawValue)
            </span>
        </header>

        <hr>
        
        \(errorHTML)

        <form method="post" action="/update/\(id)">
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem;">
                <label>Titre <input type="text" name="title" value="\(escapeHTML(score.title))" required></label>
                <label>Compositeur <input type="text" name="composer" value="\(escapeHTML(score.composer))" required></label>
            </div>
            <label>Notes <textarea name="notes" rows="4">\(escapeHTML(score.notes))</textarea></label>
            
            <div style="display: flex; justify-content: space-between; align-items: center; margin-top: 1.5rem;">
                <div style="display: flex; gap: 0.75rem;">
                    <button type="submit" style="width: auto; margin:0;">💾 Enregistrer</button>
                    <a href="/" role="button" class="secondary outline" style="width: auto; margin:0;">Annuler</a>
                </div>
            </div>
        </form>
        <hr>
        <form action="/delete/\(id)" method="post" onsubmit="return confirm('Supprimer définitivement ?');" style="margin:0">
            <button type="submit" class="btn-delete">🗑 Supprimer cette partition</button>
        </form>
    </div>
    """
  return renderLayout(title: score.title, body: body)
}

// MARK: - New Score Form

func renderNewForm(prefill: Score? = nil, errorMessage: String? = nil) -> String {
  let score =
    prefill ?? Score(title: "", composer: "", difficulty: .beginner, genre: .classical, notes: "")
  let errorHTML = errorMessage.map { "<p style='color:#e63946;'>⚠️ \(escapeHTML($0))</p>" } ?? ""

  let body = """
    <h2>Ajouter une partition</h2>
    <div class="card">
        \(errorHTML)
        <form method="post" action="/create">
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem;">
                <label>Titre <input type="text" name="title" value="\(escapeHTML(score.title))" required></label>
                <label>Compositeur <input type="text" name="composer" value="\(escapeHTML(score.composer))" required></label>
            </div>
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem;">
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
            <label>Notes <textarea name="notes" rows="3">\(escapeHTML(score.notes))</textarea></label>
            <button type="submit" style="margin-top: 1rem;">＋ Ajouter à la bibliothèque</button>
        </form>
    </div>
    """
  return renderLayout(title: "Nouvelle partition", body: body)
}

// MARK: - Utility

func escapeHTML(_ string: String) -> String {
  string.replacingOccurrences(of: "&", with: "&amp;")
    .replacingOccurrences(of: "<", with: "&lt;")
    .replacingOccurrences(of: ">", with: "&gt;")
    .replacingOccurrences(of: "\"", with: "&quot;")
    .replacingOccurrences(of: "'", with: "&#39;")
}
