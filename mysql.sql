CREATE DATABASE maika_app CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE maika_app;

CREATE TABLE usuario (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    pwd TEXT,
    rol VARCHAR(50) DEFAULT 'joven',
    fecha_nacimiento DATE
);

CREATE TABLE libro (
    id_libro INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100),
    abreviatura VARCHAR(20),
    orden INT
);

CREATE TABLE versiculo (
    id_versiculo INT AUTO_INCREMENT PRIMARY KEY,
    id_libro INT NOT NULL,
    capitulo INT,
    versiculo INT,
    texto TEXT,
    version VARCHAR(20) DEFAULT 'RVR1960',
    FOREIGN KEY (id_libro) REFERENCES libro(id_libro)
);

CREATE INDEX idx_versiculo_ref ON versiculo(id_libro, capitulo, versiculo);

CREATE TABLE categoria (
    id_categoria INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50)
);

CREATE TABLE versiculo_categoria (
    id_versiculo INT,
    id_categoria INT,
    PRIMARY KEY (id_versiculo, id_categoria),
    FOREIGN KEY (id_versiculo) REFERENCES versiculo(id_versiculo),
    FOREIGN KEY (id_categoria) REFERENCES categoria(id_categoria)
);

CREATE TABLE favorito (
    id_favorito INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT,
    id_versiculo INT,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (id_usuario, id_versiculo),
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario),
    FOREIGN KEY (id_versiculo) REFERENCES versiculo(id_versiculo)
);

CREATE TABLE historial_conversacion (
    id_historial INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT,
    texto_usuario TEXT,
    texto_bot TEXT,
    intent VARCHAR(100),
    entities_json JSON,
    confidence FLOAT,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
);

CREATE TABLE pregunta_frecuente (
    id_pregunta INT AUTO_INCREMENT PRIMARY KEY,
    pregunta TEXT,
    respuesta TEXT,
    categoria VARCHAR(50)
);

CREATE TABLE plan_lectura (
    id_plan INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100),
    descripcion TEXT,
    dias INT
);

CREATE TABLE plan_item (
    id_item INT AUTO_INCREMENT PRIMARY KEY,
    id_plan INT,
    dia INT,
    id_libro INT,
    capitulo_inicio INT,
    versiculo_inicio INT,
    capitulo_fin INT,
    versiculo_fin INT,
    comentario TEXT,
    FOREIGN KEY (id_plan) REFERENCES plan_lectura(id_plan)
);

CREATE TABLE plan_progreso_usuario (
    id_progreso INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT,
    id_plan INT,
    dia INT,
    completado BOOLEAN DEFAULT 0,
    completado_en TIMESTAMP,
    UNIQUE (id_usuario, id_plan, dia),
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario),
    FOREIGN KEY (id_plan) REFERENCES plan_lectura(id_plan)
);

CREATE TABLE devocional (
    id_devocional INT AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(100),
    cuerpo TEXT,
    fecha DATE,
    autor VARCHAR(100),
    id_versiculo INT,
    FOREIGN KEY (id_versiculo) REFERENCES versiculo(id_versiculo)
);

CREATE TABLE audio_capitulo (
    id_audio INT AUTO_INCREMENT PRIMARY KEY,
    id_libro INT,
    capitulo INT,
    url TEXT,
    duracion_segundos INT,
    local_path TEXT,
    FOREIGN KEY (id_libro) REFERENCES libro(id_libro)
);

CREATE TABLE actividad_usuario (
    id_actividad INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT,
    fecha DATE,
    tipo VARCHAR(50),
    valor INT DEFAULT 1,
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
);

CREATE TABLE racha_usuario (
    id_usuario INT PRIMARY KEY,
    racha_actual INT DEFAULT 0,
    ultima_fecha DATE,
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
);

CREATE TABLE nota (
    id_nota INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT,
    id_versiculo INT,
    texto TEXT,
    creada_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario),
    FOREIGN KEY (id_versiculo) REFERENCES versiculo(id_versiculo)
);

CREATE TABLE versiculo_del_dia (
    fecha DATE PRIMARY KEY,
    id_versiculo INT,
    fuente VARCHAR(100),
    tema VARCHAR(100),
    FOREIGN KEY (id_versiculo) REFERENCES versiculo(id_versiculo)
);

CREATE TABLE quiz (
    id_quiz INT AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(100),
    tema VARCHAR(50)
);

CREATE TABLE pregunta_quiz (
    id_pregunta INT AUTO_INCREMENT PRIMARY KEY,
    id_quiz INT,
    texto TEXT,
    FOREIGN KEY (id_quiz) REFERENCES quiz(id_quiz)
);

CREATE TABLE opcion_quiz (
    id_opcion INT AUTO_INCREMENT PRIMARY KEY,
    id_pregunta INT,
    texto TEXT,
    correcta BOOLEAN DEFAULT 0,
    FOREIGN KEY (id_pregunta) REFERENCES pregunta_quiz(id_pregunta)
);

CREATE TABLE resultado_quiz (
    id_resultado INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT,
    id_quiz INT,
    puntaje INT,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario),
    FOREIGN KEY (id_quiz) REFERENCES quiz(id_quiz)
);
