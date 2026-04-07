CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  is_premium BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS questions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  exam TEXT NOT NULL,
  subject TEXT NOT NULL,
  topic TEXT NOT NULL,
  year INT NOT NULL,
  difficulty INT NOT NULL DEFAULT 1,
  question TEXT NOT NULL,
  options JSONB NOT NULL,
  correct_answer TEXT NOT NULL,
  explanation TEXT NOT NULL,
  weightage DOUBLE PRECISION NOT NULL DEFAULT 1.0
);

CREATE TABLE IF NOT EXISTS attempts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id),
  question_id UUID NOT NULL REFERENCES questions(id),
  topic TEXT NOT NULL,
  is_correct BOOLEAN NOT NULL,
  time_taken DOUBLE PRECISION NOT NULL,
  skipped BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS topic_stats (
  user_id UUID NOT NULL REFERENCES users(id),
  topic TEXT NOT NULL,
  accuracy DOUBLE PRECISION NOT NULL DEFAULT 0.0,
  avg_time DOUBLE PRECISION NOT NULL DEFAULT 0.0,
  attempts INT NOT NULL DEFAULT 0,
  PRIMARY KEY (user_id, topic)
);

CREATE INDEX IF NOT EXISTS ix_questions_exam ON questions(exam);
CREATE INDEX IF NOT EXISTS ix_questions_topic ON questions(topic);
CREATE INDEX IF NOT EXISTS ix_questions_year ON questions(year);
CREATE INDEX IF NOT EXISTS ix_questions_exam_topic_year ON questions(exam, topic, year);
