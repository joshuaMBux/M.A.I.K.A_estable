import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'maika_database.db');
    return await openDatabase(
      path,
      version: 7, // v7: índices y restricción UNIQUE para versiculo
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
    await _insertInitialData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Drop old tables and recreate with new schema
      await _dropOldTables(db);
      await _createTables(db);
      await _insertInitialData(db);
    }

    if (oldVersion < 3) {
      await _ensureReadingPlanSeeded(db);
      await _ensureDevotionalsSeeded(db);
    }

    if (oldVersion < 4) {
      await _createChatTables(db);
    }

    if (oldVersion < 5) {
      await _ensureAudioSeeded(db);
    }

    if (oldVersion < 6) {
      // Add new audio fields for download management
      await db.execute('''
        ALTER TABLE audio_capitulo ADD COLUMN download_status TEXT DEFAULT 'REMOTE'
      ''');
      await db.execute('''
        ALTER TABLE audio_capitulo ADD COLUMN file_size_bytes INTEGER
      ''');
      await db.execute('''
        ALTER TABLE audio_capitulo ADD COLUMN checksum_hash TEXT
      ''');
    }

    if (oldVersion < 7) {
      await _ensureVersiculoIndexes(db);
    }
  }

  Future<void> _dropOldTables(Database db) async {
    await db.execute('DROP TABLE IF EXISTS favorito');
    await db.execute('DROP TABLE IF EXISTS historial_conversacion');
    await db.execute('DROP TABLE IF EXISTS pregunta_frecuente');
    await db.execute('DROP TABLE IF EXISTS versiculo');
    await db.execute('DROP TABLE IF EXISTS categoria');
    await db.execute('DROP TABLE IF EXISTS usuario');
  }

  Future<void> _createTables(Database db) async {
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');

    // Tabla Usuario
    await db.execute('''
      CREATE TABLE usuario (
        id_usuario INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        email TEXT,
        pwd TEXT,
        rol TEXT DEFAULT 'joven',
        fecha_nacimiento DATE
      )
    ''');

    // Tabla Libro
    await db.execute('''
      CREATE TABLE libro (
        id_libro INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        abreviatura TEXT,
        orden INTEGER
      )
    ''');

    // Tabla Versiculo
    await db.execute('''
      CREATE TABLE versiculo (
        id_versiculo INTEGER PRIMARY KEY AUTOINCREMENT,
        id_libro INTEGER NOT NULL,
        capitulo INTEGER NOT NULL,
        versiculo INTEGER NOT NULL,
        texto TEXT NOT NULL,
        version TEXT DEFAULT 'RVR1960',
        UNIQUE (id_libro, capitulo, versiculo),
        FOREIGN KEY (id_libro) REFERENCES libro(id_libro)
      )
    ''');

    await _ensureVersiculoIndexes(db);

    // Tabla Categoria
    await db.execute('''
      CREATE TABLE categoria (
        id_categoria INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL
      )
    ''');

    // Tabla Versiculo Categoria
    await db.execute('''
      CREATE TABLE versiculo_categoria (
        id_versiculo INTEGER NOT NULL,
        id_categoria INTEGER NOT NULL,
        PRIMARY KEY (id_versiculo, id_categoria),
        FOREIGN KEY (id_versiculo) REFERENCES versiculo(id_versiculo),
        FOREIGN KEY (id_categoria) REFERENCES categoria(id_categoria)
      )
    ''');

    // Tabla Favorito
    await db.execute('''
      CREATE TABLE favorito (
        id_favorito INTEGER PRIMARY KEY AUTOINCREMENT,
        id_usuario INTEGER NOT NULL,
        id_versiculo INTEGER NOT NULL,
        creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE (id_usuario, id_versiculo),
        FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario),
        FOREIGN KEY (id_versiculo) REFERENCES versiculo(id_versiculo)
      )
    ''');

    // Tabla Historial Conversacion
    await db.execute('''
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
      )
    ''');

    // Tabla Pregunta Frecuente
    await db.execute('''
      CREATE TABLE pregunta_frecuente (
        id_pregunta INTEGER PRIMARY KEY AUTOINCREMENT,
        pregunta TEXT NOT NULL,
        respuesta TEXT NOT NULL,
        categoria TEXT
      )
    ''');

    // Tabla Plan Lectura
    await db.execute('''
      CREATE TABLE plan_lectura (
        id_plan INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        descripcion TEXT,
        dias INTEGER
      )
    ''');

    // Tabla Plan Item
    await db.execute('''
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
      )
    ''');

    // Tabla Plan Progreso Usuario
    await db.execute('''
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
      )
    ''');

    // Tabla Devocional
    await db.execute('''
      CREATE TABLE devocional (
        id_devocional INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT,
        cuerpo TEXT,
        fecha DATE,
        autor TEXT,
        id_versiculo INTEGER,
        FOREIGN KEY (id_versiculo) REFERENCES versiculo(id_versiculo)
      )
    ''');

    // Tabla Audio Capitulo
    await db.execute('''
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
      )
    ''');

    // Tabla Actividad Usuario
    await db.execute('''
      CREATE TABLE actividad_usuario (
        id_actividad INTEGER PRIMARY KEY AUTOINCREMENT,
        id_usuario INTEGER,
        fecha DATE DEFAULT (DATE('now')),
        tipo TEXT,
        valor INTEGER DEFAULT 1,
        FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
      )
    ''');

    // Tabla Racha Usuario
    await db.execute('''
      CREATE TABLE racha_usuario (
        id_usuario INTEGER PRIMARY KEY,
        racha_actual INTEGER DEFAULT 0,
        ultima_fecha DATE,
        FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
      )
    ''');

    // Tabla Nota
    await db.execute('''
      CREATE TABLE nota (
        id_nota INTEGER PRIMARY KEY AUTOINCREMENT,
        id_usuario INTEGER,
        id_versiculo INTEGER,
        texto TEXT,
        creada_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario),
        FOREIGN KEY (id_versiculo) REFERENCES versiculo(id_versiculo)
      )
    ''');

    // Tabla Versiculo del Dia
    await db.execute('''
      CREATE TABLE versiculo_del_dia (
        fecha DATE PRIMARY KEY,
        id_versiculo INTEGER NOT NULL,
        fuente TEXT,
        tema TEXT,
        FOREIGN KEY (id_versiculo) REFERENCES versiculo(id_versiculo)
      )
    ''');

    // Tabla Quiz
    await db.execute('''
      CREATE TABLE quiz (
        id_quiz INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT,
        tema TEXT
      )
    ''');

    // Tabla Pregunta Quiz
    await db.execute('''
      CREATE TABLE pregunta_quiz (
        id_pregunta INTEGER PRIMARY KEY AUTOINCREMENT,
        id_quiz INTEGER,
        texto TEXT,
        FOREIGN KEY (id_quiz) REFERENCES quiz(id_quiz)
      )
    ''');

    // Tabla Opcion Quiz
    await db.execute('''
      CREATE TABLE opcion_quiz (
        id_opcion INTEGER PRIMARY KEY AUTOINCREMENT,
        id_pregunta INTEGER,
        texto TEXT,
        correcta BOOLEAN DEFAULT 0,
        FOREIGN KEY (id_pregunta) REFERENCES pregunta_quiz(id_pregunta)
      )
    ''');

    // Tabla Resultado Quiz
    await db.execute('''
      CREATE TABLE resultado_quiz (
        id_resultado INTEGER PRIMARY KEY AUTOINCREMENT,
        id_usuario INTEGER,
        id_quiz INTEGER,
        puntaje INTEGER,
        fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario),
        FOREIGN KEY (id_quiz) REFERENCES quiz(id_quiz)
      )
    ''');

    await _createChatTables(db);
  }

  Future<void> _insertInitialData(Database db) async {
    // Insertar libros de la Biblia
    await db.insert('libro', {
      'nombre': 'Génesis',
      'abreviatura': 'Gn',
      'orden': 1,
    });
    await db.insert('libro', {
      'nombre': 'Éxodo',
      'abreviatura': 'Ex',
      'orden': 2,
    });
    await db.insert('libro', {
      'nombre': 'Levítico',
      'abreviatura': 'Lv',
      'orden': 3,
    });
    await db.insert('libro', {
      'nombre': 'Números',
      'abreviatura': 'Nm',
      'orden': 4,
    });
    await db.insert('libro', {
      'nombre': 'Deuteronomio',
      'abreviatura': 'Dt',
      'orden': 5,
    });
    await db.insert('libro', {
      'nombre': 'Josué',
      'abreviatura': 'Jos',
      'orden': 6,
    });
    await db.insert('libro', {
      'nombre': 'Jueces',
      'abreviatura': 'Jue',
      'orden': 7,
    });
    await db.insert('libro', {
      'nombre': 'Rut',
      'abreviatura': 'Rt',
      'orden': 8,
    });
    await db.insert('libro', {
      'nombre': '1 Samuel',
      'abreviatura': '1S',
      'orden': 9,
    });
    await db.insert('libro', {
      'nombre': '2 Samuel',
      'abreviatura': '2S',
      'orden': 10,
    });
    await db.insert('libro', {
      'nombre': '1 Reyes',
      'abreviatura': '1R',
      'orden': 11,
    });
    await db.insert('libro', {
      'nombre': '2 Reyes',
      'abreviatura': '2R',
      'orden': 12,
    });
    await db.insert('libro', {
      'nombre': '1 Crónicas',
      'abreviatura': '1Cr',
      'orden': 13,
    });
    await db.insert('libro', {
      'nombre': '2 Crónicas',
      'abreviatura': '2Cr',
      'orden': 14,
    });
    await db.insert('libro', {
      'nombre': 'Esdras',
      'abreviatura': 'Esd',
      'orden': 15,
    });
    await db.insert('libro', {
      'nombre': 'Nehemías',
      'abreviatura': 'Neh',
      'orden': 16,
    });
    await db.insert('libro', {
      'nombre': 'Ester',
      'abreviatura': 'Est',
      'orden': 17,
    });
    await db.insert('libro', {
      'nombre': 'Job',
      'abreviatura': 'Job',
      'orden': 18,
    });
    await db.insert('libro', {
      'nombre': 'Salmos',
      'abreviatura': 'Sal',
      'orden': 19,
    });
    await db.insert('libro', {
      'nombre': 'Proverbios',
      'abreviatura': 'Pr',
      'orden': 20,
    });
    await db.insert('libro', {
      'nombre': 'Eclesiastés',
      'abreviatura': 'Ec',
      'orden': 21,
    });
    await db.insert('libro', {
      'nombre': 'Cantares',
      'abreviatura': 'Cnt',
      'orden': 22,
    });
    await db.insert('libro', {
      'nombre': 'Isaías',
      'abreviatura': 'Is',
      'orden': 23,
    });
    await db.insert('libro', {
      'nombre': 'Jeremías',
      'abreviatura': 'Jer',
      'orden': 24,
    });
    await db.insert('libro', {
      'nombre': 'Lamentaciones',
      'abreviatura': 'Lam',
      'orden': 25,
    });
    await db.insert('libro', {
      'nombre': 'Ezequiel',
      'abreviatura': 'Ez',
      'orden': 26,
    });
    await db.insert('libro', {
      'nombre': 'Daniel',
      'abreviatura': 'Dn',
      'orden': 27,
    });
    await db.insert('libro', {
      'nombre': 'Oseas',
      'abreviatura': 'Os',
      'orden': 28,
    });
    await db.insert('libro', {
      'nombre': 'Joel',
      'abreviatura': 'Jl',
      'orden': 29,
    });
    await db.insert('libro', {
      'nombre': 'Amós',
      'abreviatura': 'Am',
      'orden': 30,
    });
    await db.insert('libro', {
      'nombre': 'Abdías',
      'abreviatura': 'Abd',
      'orden': 31,
    });
    await db.insert('libro', {
      'nombre': 'Jonás',
      'abreviatura': 'Jon',
      'orden': 32,
    });
    await db.insert('libro', {
      'nombre': 'Miqueas',
      'abreviatura': 'Mi',
      'orden': 33,
    });
    await db.insert('libro', {
      'nombre': 'Nahum',
      'abreviatura': 'Nah',
      'orden': 34,
    });
    await db.insert('libro', {
      'nombre': 'Habacuc',
      'abreviatura': 'Hab',
      'orden': 35,
    });
    await db.insert('libro', {
      'nombre': 'Sofonías',
      'abreviatura': 'Sof',
      'orden': 36,
    });
    await db.insert('libro', {
      'nombre': 'Hageo',
      'abreviatura': 'Hg',
      'orden': 37,
    });
    await db.insert('libro', {
      'nombre': 'Zacarías',
      'abreviatura': 'Zac',
      'orden': 38,
    });
    await db.insert('libro', {
      'nombre': 'Malaquías',
      'abreviatura': 'Mal',
      'orden': 39,
    });
    await db.insert('libro', {
      'nombre': 'Mateo',
      'abreviatura': 'Mt',
      'orden': 40,
    });
    await db.insert('libro', {
      'nombre': 'Marcos',
      'abreviatura': 'Mc',
      'orden': 41,
    });
    await db.insert('libro', {
      'nombre': 'Lucas',
      'abreviatura': 'Lc',
      'orden': 42,
    });
    await db.insert('libro', {
      'nombre': 'Juan',
      'abreviatura': 'Jn',
      'orden': 43,
    });
    await db.insert('libro', {
      'nombre': 'Hechos',
      'abreviatura': 'Hch',
      'orden': 44,
    });
    await db.insert('libro', {
      'nombre': 'Romanos',
      'abreviatura': 'Ro',
      'orden': 45,
    });
    await db.insert('libro', {
      'nombre': '1 Corintios',
      'abreviatura': '1Co',
      'orden': 46,
    });
    await db.insert('libro', {
      'nombre': '2 Corintios',
      'abreviatura': '2Co',
      'orden': 47,
    });
    await db.insert('libro', {
      'nombre': 'Gálatas',
      'abreviatura': 'Gá',
      'orden': 48,
    });
    await db.insert('libro', {
      'nombre': 'Efesios',
      'abreviatura': 'Ef',
      'orden': 49,
    });
    await db.insert('libro', {
      'nombre': 'Filipenses',
      'abreviatura': 'Fil',
      'orden': 50,
    });
    await db.insert('libro', {
      'nombre': 'Colosenses',
      'abreviatura': 'Col',
      'orden': 51,
    });
    await db.insert('libro', {
      'nombre': '1 Tesalonicenses',
      'abreviatura': '1Ts',
      'orden': 52,
    });
    await db.insert('libro', {
      'nombre': '2 Tesalonicenses',
      'abreviatura': '2Ts',
      'orden': 53,
    });
    await db.insert('libro', {
      'nombre': '1 Timoteo',
      'abreviatura': '1Ti',
      'orden': 54,
    });
    await db.insert('libro', {
      'nombre': '2 Timoteo',
      'abreviatura': '2Ti',
      'orden': 55,
    });
    await db.insert('libro', {
      'nombre': 'Tito',
      'abreviatura': 'Tit',
      'orden': 56,
    });
    await db.insert('libro', {
      'nombre': 'Filemón',
      'abreviatura': 'Flm',
      'orden': 57,
    });
    await db.insert('libro', {
      'nombre': 'Hebreos',
      'abreviatura': 'He',
      'orden': 58,
    });
    await db.insert('libro', {
      'nombre': 'Santiago',
      'abreviatura': 'Stg',
      'orden': 59,
    });
    await db.insert('libro', {
      'nombre': '1 Pedro',
      'abreviatura': '1P',
      'orden': 60,
    });
    await db.insert('libro', {
      'nombre': '2 Pedro',
      'abreviatura': '2P',
      'orden': 61,
    });
    await db.insert('libro', {
      'nombre': '1 Juan',
      'abreviatura': '1Jn',
      'orden': 62,
    });
    await db.insert('libro', {
      'nombre': '2 Juan',
      'abreviatura': '2Jn',
      'orden': 63,
    });
    await db.insert('libro', {
      'nombre': '3 Juan',
      'abreviatura': '3Jn',
      'orden': 64,
    });
    await db.insert('libro', {
      'nombre': 'Judas',
      'abreviatura': 'Jud',
      'orden': 65,
    });
    await db.insert('libro', {
      'nombre': 'Apocalipsis',
      'abreviatura': 'Ap',
      'orden': 66,
    });

    // Insertar categorías
    await db.insert('categoria', {'nombre': 'Amor'});
    await db.insert('categoria', {'nombre': 'Fe'});
    await db.insert('categoria', {'nombre': 'Esperanza'});
    await db.insert('categoria', {'nombre': 'Sabiduría'});
    await db.insert('categoria', {'nombre': 'Salvación'});
    await db.insert('categoria', {'nombre': 'Gratitud'});
    await db.insert('categoria', {'nombre': 'Perdón'});
    await db.insert('categoria', {'nombre': 'Paz'});

    // Insertar versículos de ejemplo (Juan 3:16)
    await db.insert('versiculo', {
      'id_libro': 43, // Juan
      'capitulo': 3,
      'versiculo': 16,
      'texto':
          'Porque de tal manera amó Dios al mundo, que ha dado a su Hijo unigénito, para que todo aquel que en él cree, no se pierda, mas tenga vida eterna.',
      'version': 'RVR1960',
    });

    // Insertar versículo del día
    await db.insert('versiculo_del_dia', {
      'fecha': DateTime.now().toIso8601String().split('T')[0],
      'id_versiculo': 1,
      'fuente': 'Biblia RVR1960',
      'tema': 'Amor de Dios',
    });

    // Insertar preguntas frecuentes
    await db.insert('pregunta_frecuente', {
      'pregunta': '¿Qué es la fe?',
      'respuesta':
          'La fe es la certeza de lo que se espera, la convicción de lo que no se ve (Hebreos 11:1).',
      'categoria': 'Fe',
    });

    await db.insert('pregunta_frecuente', {
      'pregunta': '¿Cómo puedo encontrar paz?',
      'respuesta':
          'La paz de Dios, que sobrepasa todo entendimiento, guardará vuestros corazones y vuestros pensamientos en Cristo Jesús (Filipenses 4:7).',
      'categoria': 'Paz',
    });

    await db.insert('pregunta_frecuente', {
      'pregunta': '¿Qué dice la Biblia sobre el amor?',
      'respuesta':
          'El amor es sufrido, es benigno; el amor no tiene envidia, el amor no es jactancioso, no se envanece (1 Corintios 13:4).',
      'categoria': 'Amor',
    });

    // Insertar plan de lectura de ejemplo
    final johnPlanId = await db.insert('plan_lectura', {
      'nombre': 'Plan de 21 dias - Evangelio de Juan',
      'descripcion':
          'Lee un capitulo de Juan cada dia y profundiza en Jesucristo.',
      'dias': 21,
    });

    await _insertJohnReadingPlan(db, johnPlanId);

    await _insertInitialDevotionals(db);
    await _insertInitialAudioSamples(db);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  Future<void> _ensureReadingPlanSeeded(Database db) async {
    final existingPlan = await db.query(
      'plan_lectura',
      orderBy: 'id_plan ASC',
      limit: 1,
    );

    int planId;
    if (existingPlan.isEmpty) {
      planId = await db.insert('plan_lectura', {
        'nombre': 'Plan de 21 dias - Evangelio de Juan',
        'descripcion':
            'Lee un capitulo de Juan cada dia y profundiza en Jesucristo.',
        'dias': 21,
      });
    } else {
      planId = existingPlan.first['id_plan'] as int;
      await db.update(
        'plan_lectura',
        {
          'nombre': 'Plan de 21 dias - Evangelio de Juan',
          'descripcion':
              'Lee un capitulo de Juan cada dia y profundiza en Jesucristo.',
          'dias': 21,
        },
        where: 'id_plan = ?',
        whereArgs: [planId],
      );
    }

    final count =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM plan_item WHERE id_plan = ?',
            [planId],
          ),
        ) ??
        0;

    if (count < 21) {
      await db.delete('plan_item', where: 'id_plan = ?', whereArgs: [planId]);
      await _insertJohnReadingPlan(db, planId);
    }
  }

  Future<void> _ensureDevotionalsSeeded(Database db) async {
    final count =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM devocional'),
        ) ??
        0;

    if (count == 0) {
      await _insertInitialDevotionals(db);
    }
  }

  Future<void> _insertJohnReadingPlan(Database db, int planId) async {
    final johnEndVerses = [
      51,
      25,
      36,
      54,
      47,
      71,
      53,
      59,
      41,
      42,
      57,
      50,
      38,
      31,
      27,
      33,
      26,
      40,
      42,
      31,
      25,
    ];

    final johnComments = [
      'El Verbo hecho carne trae luz y vida.',
      'El primer milagro revela la gloria de Jesus.',
      'Dialogo con Nicodemo sobre nuevo nacimiento.',
      'Jesus transforma la vida de la mujer samaritana.',
      'El Hijo da vida y autoridad sobre el sabado.',
      'Jesus es el pan de vida para el mundo.',
      'Rios de agua viva para quienes creen.',
      'La luz del mundo ofrece libertad verdadera.',
      'Jesus abre los ojos tanto fisicos como espirituales.',
      'El buen pastor cuida y conoce a sus ovejas.',
      'Jesus es la resurreccion y la vida.',
      'La hora ha llegado: seguir a Jesus con entrega.',
      'El servicio humilde del Maestro en la cena.',
      'Caminar en paz confiando en las promesas de Jesus.',
      'Permanecer en la vid para llevar fruto verdadero.',
      'El Espiritu Santo fortalece en la tribulacion.',
      'La oracion sacerdotal de Jesus por sus seguidores.',
      'Prision y juicio: la fidelidad de Jesus.',
      'La cruz muestra el amor perfecto del Salvador.',
      'La tumba vacia anuncia nueva esperanza.',
      'Jesus restaura y envia a sus discipulos.',
    ];

    for (var day = 0; day < johnEndVerses.length; day++) {
      await db.insert('plan_item', {
        'id_plan': planId,
        'dia': day + 1,
        'id_libro': 43,
        'capitulo_inicio': day + 1,
        'versiculo_inicio': 1,
        'capitulo_fin': day + 1,
        'versiculo_fin': johnEndVerses[day],
        'comentario': johnComments[day],
      });
    }
  }

  Future<void> _insertInitialDevotionals(Database db) async {
    final today = DateTime.now();
    final seeds = [
      {
        'title': 'El amor de Dios',
        'body':
            'Dios nos ama tanto que envio a su Hijo para salvarnos. Deja que ese amor llene tu dia de esperanza.',
        'daysAgo': 0,
        'author': 'Maika',
        'verseId': 1,
      },
      {
        'title': 'Permanecer en la vid',
        'body':
            'Sin Jesus no podemos dar fruto. Permanece conectado a El mediante la oracion y la obediencia.',
        'daysAgo': 1,
        'author': 'Maika',
        'verseId': null,
      },
      {
        'title': 'Fuerza en la debilidad',
        'body':
            'Cuando te sientas debil recuerda que la gracia de Dios te sostiene. En tus limites El se fortalece.',
        'daysAgo': 2,
        'author': 'Maika',
        'verseId': null,
      },
      {
        'title': 'Paz en medio de la tormenta',
        'body':
            'Jesus sigue siendo Señor aun en medio de la tormenta. Confia en su voz que trae paz a tu corazon.',
        'daysAgo': 3,
        'author': 'Maika',
        'verseId': null,
      },
    ];

    for (final seed in seeds) {
      final date = today.subtract(Duration(days: seed['daysAgo'] as int));
      await db.insert('devocional', {
        'titulo': seed['title'],
        'cuerpo': seed['body'],
        'fecha': date.toIso8601String().split('T').first,
        'autor': seed['author'],
        'id_versiculo': seed['verseId'],
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _insertInitialAudioSamples(Database db) async {
    // Avoid duplicate seeds if already present
    final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM audio_capitulo'),
        ) ??
        0;
    if (count > 0) return;

    // Juan 1–3 (id_libro 43)
    await db.insert('audio_capitulo', {
      'id_libro': 43,
      'capitulo': 1,
      'url': 'https://example.com/audio/juan_1.mp3',
      'duracion_segundos': 420,
    });
    await db.insert('audio_capitulo', {
      'id_libro': 43,
      'capitulo': 2,
      'url': 'https://example.com/audio/juan_2.mp3',
      'duracion_segundos': 300,
    });
    await db.insert('audio_capitulo', {
      'id_libro': 43,
      'capitulo': 3,
      'url': 'https://example.com/audio/juan_3.mp3',
      'duracion_segundos': 360,
    });

    // Salmos 23 (id_libro 19)
    await db.insert('audio_capitulo', {
      'id_libro': 19,
      'capitulo': 23,
      'url': 'https://example.com/audio/salmos_23.mp3',
      'duracion_segundos': 180,
    });

    // Génesis 1 (id_libro 1)
    await db.insert('audio_capitulo', {
      'id_libro': 1,
      'capitulo': 1,
      'url': 'https://example.com/audio/genesis_1.mp3',
      'duracion_segundos': 480,
    });
  }

  Future<void> _ensureAudioSeeded(Database db) async {
    final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM audio_capitulo'),
        ) ??
        0;
    if (count == 0) {
      await _insertInitialAudioSamples(db);
    }
  }

  Future<void> _createChatTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS conversations (
        id TEXT PRIMARY KEY,
        title TEXT,
        updated_at INTEGER
      )
    ''');

    await db.execute('''
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
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS favorites (
        id TEXT PRIMARY KEY,
        message_id TEXT NOT NULL,
        note TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id, created_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_messages_status ON messages(status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_favorites_message ON favorites(message_id)',
    );
  }

  Future<void> _ensureVersiculoIndexes(Database db) async {
    // Índice único para garantizar que no haya duplicados de versículo
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_versiculo_unique
      ON versiculo(id_libro, capitulo, versiculo)
    ''');

    // Índice compuesto optimizado para lecturas por capítulo
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_versiculo_capitulo
      ON versiculo(id_libro, capitulo)
    ''');

    // Índice para búsquedas por texto
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_versiculo_texto
      ON versiculo(texto)
    ''');
  }
}
