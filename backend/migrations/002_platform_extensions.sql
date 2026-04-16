-- Platform extensions for doubts, study rooms, and realtime collaboration.

CREATE TABLE IF NOT EXISTS doubts (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id),
    subject VARCHAR(128) NOT NULL,
    chapter VARCHAR(128) NOT NULL,
    question_type VARCHAR(32) NOT NULL,
    question_text TEXT NOT NULL,
    image_url TEXT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS ix_doubts_user_id ON doubts(user_id);
CREATE INDEX IF NOT EXISTS ix_doubts_subject ON doubts(subject);
CREATE INDEX IF NOT EXISTS ix_doubts_status ON doubts(status);
CREATE INDEX IF NOT EXISTS ix_doubts_created_at ON doubts(created_at);

CREATE TABLE IF NOT EXISTS doubt_responses (
    id UUID PRIMARY KEY,
    doubt_id UUID NOT NULL REFERENCES doubts(id),
    responder_id UUID NULL REFERENCES users(id),
    responder_type VARCHAR(32) NOT NULL DEFAULT 'mentor',
    answer_text TEXT NOT NULL,
    helpful_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS ix_doubt_responses_doubt_id ON doubt_responses(doubt_id);
CREATE INDEX IF NOT EXISTS ix_doubt_responses_responder_id ON doubt_responses(responder_id);
CREATE INDEX IF NOT EXISTS ix_doubt_responses_created_at ON doubt_responses(created_at);

CREATE TABLE IF NOT EXISTS study_rooms (
    id UUID PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    exam VARCHAR(32) NOT NULL,
    created_by UUID NOT NULL REFERENCES users(id),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS ix_study_rooms_exam ON study_rooms(exam);
CREATE INDEX IF NOT EXISTS ix_study_rooms_created_by ON study_rooms(created_by);
CREATE INDEX IF NOT EXISTS ix_study_rooms_is_active ON study_rooms(is_active);
CREATE INDEX IF NOT EXISTS ix_study_rooms_created_at ON study_rooms(created_at);

CREATE TABLE IF NOT EXISTS room_messages (
    id UUID PRIMARY KEY,
    room_id UUID NOT NULL REFERENCES study_rooms(id),
    user_id UUID NOT NULL REFERENCES users(id),
    message TEXT NOT NULL,
    timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS ix_room_messages_room_id ON room_messages(room_id);
CREATE INDEX IF NOT EXISTS ix_room_messages_user_id ON room_messages(user_id);
CREATE INDEX IF NOT EXISTS ix_room_messages_timestamp ON room_messages(timestamp);
