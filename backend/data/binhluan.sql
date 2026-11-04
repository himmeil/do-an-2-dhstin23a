CREATE TABLE IF NOT EXISTS comments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  place_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  account_name TEXT NOT NULL CHECK (length(account_name) BETWEEN 1 AND 254),
  content TEXT NOT NULL CHECK (length(content) BETWEEN 1 AND 1000),
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

CREATE INDEX IF NOT EXISTS idx_comments_place_created
  ON comments(place_id, created_at DESC, id DESC);
