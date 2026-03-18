-- Compound Marketing Agent SQLite Schema
-- Initialize with: sqlite3 marketing.db < init_db.sql

-- Company profile (includes perceptions)
CREATE TABLE IF NOT EXISTS company (
  id INTEGER PRIMARY KEY,
  name TEXT,
  url TEXT,
  positioning TEXT,
  primary_icp TEXT,
  secondary_icp TEXT,
  differentiators TEXT,
  perceptions TEXT,  -- JSON array of 3-5 perceptions
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Channels (includes autonomy level)
CREATE TABLE IF NOT EXISTS channels (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  platform TEXT NOT NULL,
  handle_or_url TEXT,
  api_credentials_env TEXT,
  data_source TEXT DEFAULT 'api',  -- 'api', 'csv'
  autonomy_level TEXT DEFAULT 'draft_only',  -- 'draft_only', 'auto_stage', 'auto_post'
  csv_sync_day TEXT,
  status TEXT DEFAULT 'active',
  last_fetched DATETIME,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Metrics (time-series)
CREATE TABLE IF NOT EXISTS metrics (
  id INTEGER PRIMARY KEY,
  channel_id INTEGER REFERENCES channels(id),
  date DATE NOT NULL,
  metric_name TEXT NOT NULL,
  value REAL NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(channel_id, date, metric_name)
);

-- XMR baselines (for signal detection)
CREATE TABLE IF NOT EXISTS xmr_baselines (
  id INTEGER PRIMARY KEY,
  channel_id INTEGER REFERENCES channels(id),
  metric_name TEXT NOT NULL,
  baseline_value REAL NOT NULL,
  upper_control_limit REAL NOT NULL,
  lower_control_limit REAL NOT NULL,
  calculated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(channel_id, metric_name)
);

-- Published content
CREATE TABLE IF NOT EXISTS content (
  id INTEGER PRIMARY KEY,
  channel_id INTEGER REFERENCES channels(id),
  external_id TEXT,
  content_text TEXT NOT NULL,
  content_url TEXT,
  published_at DATETIME,
  fetched_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  recommendation_id INTEGER REFERENCES recommendations(id),
  match_confidence REAL,  -- 0-1 confidence of attribution
  final_version TEXT  -- User-provided final version for CSV channels
);

-- Recommendations (includes GACC brief)
CREATE TABLE IF NOT EXISTS recommendations (
  id INTEGER PRIMARY KEY,
  channel_id INTEGER REFERENCES channels(id),
  type TEXT NOT NULL,  -- 'optimization', 'experiment', 'exploration'
  status TEXT DEFAULT 'pending',  -- 'pending', 'approved', 'rejected', 'published'
  gacc_goal TEXT,
  gacc_audience TEXT,
  gacc_channels TEXT,
  gacc_creative TEXT,
  customer_story TEXT,
  analysis TEXT NOT NULL,
  draft TEXT NOT NULL,
  expected_impact TEXT,
  signal_confidence TEXT,  -- 'high', 'medium', 'low'
  xmr_summary TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  approved_at DATETIME,
  published_at DATETIME,
  user_edits TEXT,
  rejection_reason TEXT
);

-- Learnings (specific + principles)
CREATE TABLE IF NOT EXISTS learnings (
  id INTEGER PRIMARY KEY,
  channel_id INTEGER,  -- NULL for cross-channel principles
  type TEXT NOT NULL,  -- 'specific', 'principle'
  summary TEXT NOT NULL,
  full_prose TEXT NOT NULL,
  hypothesis TEXT,
  result TEXT,
  performance_impact REAL,
  source_recommendation_id INTEGER REFERENCES recommendations(id),
  validated BOOLEAN DEFAULT FALSE,
  superseded_by INTEGER REFERENCES learnings(id),
  applied_count INTEGER DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Initiative balance tracking
CREATE TABLE IF NOT EXISTS initiative_balance (
  id INTEGER PRIMARY KEY,
  recommendation_id INTEGER REFERENCES recommendations(id),
  type TEXT NOT NULL,  -- 'optimization', 'experiment', 'exploration'
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Delivery config
CREATE TABLE IF NOT EXISTS delivery (
  id INTEGER PRIMARY KEY,
  method TEXT NOT NULL,  -- 'email', 'slack'
  frequency TEXT DEFAULT 'daily',
  email_address TEXT,
  slack_channel_id TEXT,
  delivery_time TEXT DEFAULT '07:00',
  timezone TEXT DEFAULT 'UTC',
  enabled BOOLEAN DEFAULT TRUE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Run history
CREATE TABLE IF NOT EXISTS runs (
  id INTEGER PRIMARY KEY,
  started_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  completed_at DATETIME,
  status TEXT,
  channels_processed TEXT,  -- JSON array
  channels_failed TEXT,  -- JSON array
  recommendation_id INTEGER REFERENCES recommendations(id),
  errors TEXT
);

-- Channel knowledge (self-expanding)
CREATE TABLE IF NOT EXISTS channel_knowledge (
  id INTEGER PRIMARY KEY,
  platform TEXT NOT NULL UNIQUE,
  api_documentation_url TEXT,
  has_read_api BOOLEAN,
  has_write_api BOOLEAN,
  api_cost TEXT,
  discovered_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  notes TEXT  -- Agent's notes on how to use this channel
);

-- Agent configuration (user-customizable settings)
CREATE TABLE IF NOT EXISTS config (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  description TEXT,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Quality rules (forbidden words, voice requirements)
CREATE TABLE IF NOT EXISTS quality_rules (
  id INTEGER PRIMARY KEY,
  rule_type TEXT NOT NULL,  -- 'forbidden_word', 'required_voice', 'hook_requirement'
  value TEXT NOT NULL,
  active BOOLEAN DEFAULT TRUE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Default configuration
INSERT OR IGNORE INTO config (key, value, description) VALUES
  ('initiative_optimization_pct', '70', 'Target percentage for optimization initiatives'),
  ('initiative_experiment_pct', '20', 'Target percentage for experiment initiatives'),
  ('initiative_exploration_pct', '10', 'Target percentage for exploration initiatives'),
  ('signal_threshold_high', '0.8', 'Confidence threshold for high signal'),
  ('signal_threshold_medium', '0.5', 'Confidence threshold for medium signal');

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_metrics_channel_date ON metrics(channel_id, date);
CREATE INDEX IF NOT EXISTS idx_recommendations_status ON recommendations(status);
CREATE INDEX IF NOT EXISTS idx_learnings_type ON learnings(type);
CREATE INDEX IF NOT EXISTS idx_initiative_balance_type ON initiative_balance(type);
CREATE INDEX IF NOT EXISTS idx_runs_status ON runs(status);
CREATE INDEX IF NOT EXISTS idx_quality_rules_type ON quality_rules(rule_type, active);
