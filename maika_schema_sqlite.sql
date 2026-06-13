-- Maika SQLite schema
-- Source: lib/core/database/database_helper.dart
-- Schema version: 9

PRAGMA foreign_keys = ON;

-- =====================
-- Tablas principales
-- =====================

CREATE TABLE usuario (
    id_usuario INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    email TEXT,
    pwd TEXT,
    rol TEXT DEFAULT 'joven',
    fecha_nacimiento DATE
);

CREATE TABLE libro (
    id_libro INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    abreviatura TEXT,
    orden INTEGER
);

CREATE TABLE versiculo (
    id_versiculo INTEGER PRIMARY KEY AUTOINCREMENT,
    id_libro INTEGER NOT NULL,
    capitulo INTEGER NOT NULL,
    versiculo INTEGER NOT NULL,
    texto TEXT NOT NULL,
    version TEXT DEFAULT 'RVR1960',
    UNIQUE (id_libro, capitulo, versiculo),
    FOREIGN KEY (id_libro) REFERENCES libro(id_libro)
);

CREATE TABLE categoria (
    id_categoria INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL
);

CREATE TABLE versiculo_categoria (
    id_versiculo INTEGER NOT NULL,
    id_categoria INTEGER NOT NULL,
    PRIMARY KEY (id_versiculo, id_categoria),
    FOREIGN KEY (id_versiculo) REFERENCES versiculo(id_versiculo),
    FOREIGN KEY (id_categoria) REFERENCES categoria(id_categoria)
);

CREATE TABLE favorito (
    id_favorito INTEGER PRIMARY KEY AUTOINCREMENT,
    id_usuario INTEGER NOT NULL,
    id_versiculo INTEGER NOT NULL,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (id_usuario, id_versiculo),
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario),
    FOREIGN KEY (id_versiculo) REFERENCES versiculo(id_versiculo)
);

CREATE TABLE historial_conversacion (
    id_historial INTEGER PRIMARY KEY AUTOINCREMENT,
    id_usuario INTEGER,
    texto_usuario TEXT,
    texto_bot TEXT,
    intent TEXT,
    entities_json TEXT,
    confidence REAL,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
);

CREATE TABLE pregunta_frecuente (
    id_pregunta INTEGER PRIMARY KEY AUTOINCREMENT,
    pregunta TEXT NOT NULL,
    respuesta TEXT NOT NULL,
    categoria TEXT
);

-- =====================
-- Lectura y contenido
-- =====================

CREATE TABLE plan_lectura (
    id_plan INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    descripcion TEXT,
    dias INTEGER
);

CREATE TABLE plan_item (
    id_item INTEGER PRIMARY KEY AUTOINCREMENT,
    id_plan INTEGER,
    dia INTEGER,
    id_libro INTEGER,
    capitulo_inicio INTEGER,
    versiculo_inicio INTEGER,
    capitulo_fin INTEGER,
    versiculo_fin INTEGER,
    comentario TEXT,
    FOREIGN KEY (id_plan) REFERENCES plan_lectura(id_plan)
);

CREATE TABLE plan_progreso_usuario (
    id_progreso INTEGER PRIMARY KEY AUTOINCREMENT,
    id_usuario INTEGER,
    id_plan INTEGER,
    dia INTEGER,
    completado BOOLEAN DEFAULT 0,
    completado_en TIMESTAMP,
    UNIQUE (id_usuario, id_plan, dia),
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario),
    FOREIGN KEY (id_plan) REFERENCES plan_lectura(id_plan)
);

CREATE TABLE devocional (
    id_devocional INTEGER PRIMARY KEY AUTOINCREMENT,
    titulo TEXT,
    cuerpo TEXT,
    fecha DATE,
    autor TEXT,
    id_versiculo INTEGER,
    FOREIGN KEY (id_versiculo) REFERENCES versiculo(id_versiculo)
);

CREATE TABLE audio_capitulo (
    id_audio INTEGER PRIMARY KEY AUTOINCREMENT,
    id_libro INTEGER,
    capitulo INTEGER,
    url TEXT,
    duracion_segundos INTEGER,
    local_path TEXT,
    download_status TEXT DEFAULT 'REMOTE',
    file_size_bytes INTEGER,
    checksum_hash TEXT,
    FOREIGN KEY (id_libro) REFERENCES libro(id_libro)
);

CREATE TABLE actividad_usuario (
    id_actividad INTEGER PRIMARY KEY AUTOINCREMENT,
    id_usuario INTEGER,
    fecha DATE DEFAULT (DATE('now')),
    tipo TEXT,
    valor INTEGER DEFAULT 1,
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
);

CREATE TABLE racha_usuario (
    id_usuario INTEGER PRIMARY KEY,
    racha_actual INTEGER DEFAULT 0,
    ultima_fecha DATE,
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
);

CREATE TABLE nota (
    id_nota INTEGER PRIMARY KEY AUTOINCREMENT,
    id_usuario INTEGER,
    id_versiculo INTEGER,
    texto TEXT,
    creada_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario),
    FOREIGN KEY (id_versiculo) REFERENCES versiculo(id_versiculo)
);

CREATE TABLE versiculo_del_dia (
    fecha DATE PRIMARY KEY,
    id_versiculo INTEGER NOT NULL,
    fuente TEXT,
    tema TEXT,
    FOREIGN KEY (id_versiculo) REFERENCES versiculo(id_versiculo)
);

-- =====================
-- Quiz
-- =====================

CREATE TABLE quiz (
    id_quiz INTEGER PRIMARY KEY AUTOINCREMENT,
    titulo TEXT,
    tema TEXT
);

CREATE TABLE pregunta_quiz (
    id_pregunta INTEGER PRIMARY KEY AUTOINCREMENT,
    id_quiz INTEGER,
    texto TEXT,
    FOREIGN KEY (id_quiz) REFERENCES quiz(id_quiz)
);

CREATE TABLE opcion_quiz (
    id_opcion INTEGER PRIMARY KEY AUTOINCREMENT,
    id_pregunta INTEGER,
    texto TEXT,
    correcta BOOLEAN DEFAULT 0,
    FOREIGN KEY (id_pregunta) REFERENCES pregunta_quiz(id_pregunta)
);

CREATE TABLE resultado_quiz (
    id_resultado INTEGER PRIMARY KEY AUTOINCREMENT,
    id_usuario INTEGER,
    id_quiz INTEGER,
    puntaje INTEGER,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario),
    FOREIGN KEY (id_quiz) REFERENCES quiz(id_quiz)
);

-- =====================
-- Actividad de minijuegos
-- =====================

CREATE TABLE IF NOT EXISTS game_activity (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    event_name TEXT NOT NULL,
    game TEXT NOT NULL,
    completed INTEGER,
    seconds_played INTEGER,
    fragments_collected INTEGER,
    created_at INTEGER NOT NULL
);

-- =====================
-- Gamificacion local
-- =====================

CREATE TABLE IF NOT EXISTS user_progress (
    user_id INTEGER PRIMARY KEY,
    xp_total INTEGER NOT NULL DEFAULT 0,
    level INTEGER NOT NULL DEFAULT 1,
    coins INTEGER NOT NULL DEFAULT 0,
    updated_at INTEGER,
    FOREIGN KEY (user_id) REFERENCES usuario(id_usuario) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS reward_transaction (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    event_key TEXT NOT NULL UNIQUE,
    action_type TEXT NOT NULL,
    xp_delta INTEGER NOT NULL DEFAULT 0,
    coins_delta INTEGER NOT NULL DEFAULT 0,
    metadata_json TEXT,
    created_at INTEGER NOT NULL,
    FOREIGN KEY (user_id) REFERENCES usuario(id_usuario) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS user_achievement (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    achievement_key TEXT NOT NULL,
    unlocked_at INTEGER NOT NULL,
    UNIQUE (user_id, achievement_key),
    FOREIGN KEY (user_id) REFERENCES usuario(id_usuario) ON DELETE CASCADE
);

-- =====================
-- Chat
-- =====================

CREATE TABLE IF NOT EXISTS conversations (
    id TEXT PRIMARY KEY,
    title TEXT,
    updated_at INTEGER
);

CREATE TABLE IF NOT EXISTS messages (
    id TEXT PRIMARY KEY,
    conversation_id TEXT NOT NULL,
    sender TEXT,
    text TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    type TEXT NOT NULL,
    status TEXT NOT NULL,
    content_type TEXT NOT NULL,
    image_url TEXT,
    list_items TEXT,
    chips TEXT,
    metadata TEXT,
    generated INTEGER DEFAULT 0,
    FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS favorites (
    id TEXT PRIMARY KEY,
    message_id TEXT NOT NULL,
    note TEXT,
    created_at INTEGER NOT NULL,
    FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE
);

-- =====================
-- Indices
-- =====================

CREATE UNIQUE INDEX IF NOT EXISTS idx_versiculo_unique
ON versiculo(id_libro, capitulo, versiculo);

CREATE INDEX IF NOT EXISTS idx_versiculo_capitulo
ON versiculo(id_libro, capitulo);

CREATE INDEX IF NOT EXISTS idx_versiculo_texto
ON versiculo(texto);

CREATE INDEX IF NOT EXISTS idx_reward_transaction_user
ON reward_transaction(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_reward_transaction_action
ON reward_transaction(user_id, action_type);

CREATE INDEX IF NOT EXISTS idx_user_achievement_user
ON user_achievement(user_id, unlocked_at DESC);

CREATE INDEX IF NOT EXISTS idx_messages_conversation
ON messages(conversation_id, created_at);

CREATE INDEX IF NOT EXISTS idx_messages_status
ON messages(status);

CREATE INDEX IF NOT EXISTS idx_favorites_message
ON favorites(message_id);
