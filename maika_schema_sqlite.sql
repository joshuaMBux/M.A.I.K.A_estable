PRAGMA foreign_keys = ON;

-- =====================
-- TABLAS PRINCIPALES
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
    FOREIGN KEY (id_libro) REFERENCES libro(id_libro)
);

CREATE INDEX idx_versiculo_ref ON versiculo(id_libro, capitulo, versiculo);

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
-- TABLAS DE APRENDIZAJE Y GAMIFICACIÓN
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
-- TABLAS DE QUIZ / TEST
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
