import 'package:flutter/material.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'Todas';
  String _searchQuery = '';

  final List<String> _categories = [
    'Todas',
    'Amor',
    'Fe',
    'Esperanza',
    'Sabiduría',
    'Salvación',
    'Gratitud',
    'Perdón',
    'Paz',
  ];

  // Base de datos de versículos reales
  final List<Map<String, String>> _allVerses = [
    // Amor
    {
      'text':
          'Porque de tal manera amó Dios al mundo, que ha dado a su Hijo unigénito, para que todo aquel que en él cree, no se pierda, mas tenga vida eterna.',
      'reference': 'Juan 3:16',
      'category': 'Amor',
    },
    {
      'text':
          'El amor es sufrido, es benigno; el amor no tiene envidia, el amor no es jactancioso, no se envanece.',
      'reference': '1 Corintios 13:4',
      'category': 'Amor',
    },
    {
      'text':
          'Y nosotros hemos conocido y creído el amor que Dios tiene para con nosotros. Dios es amor; y el que permanece en amor, permanece en Dios, y Dios en él.',
      'reference': '1 Juan 4:16',
      'category': 'Amor',
    },
    // Fe
    {
      'text':
          'Es, pues, la fe la certeza de lo que se espera, la convicción de lo que no se ve.',
      'reference': 'Hebreos 11:1',
      'category': 'Fe',
    },
    {
      'text':
          'Porque por gracia sois salvos por medio de la fe; y esto no de vosotros, pues es don de Dios.',
      'reference': 'Efesios 2:8',
      'category': 'Fe',
    },
    {
      'text':
          'Pero sin fe es imposible agradar a Dios; porque es necesario que el que se acerca a Dios crea que le hay, y que es galardonador de los que le buscan.',
      'reference': 'Hebreos 11:6',
      'category': 'Fe',
    },
    // Esperanza
    {
      'text':
          'Porque yo sé los pensamientos que tengo acerca de vosotros, dice Jehová, pensamientos de paz, y no de mal, para daros el fin que esperáis.',
      'reference': 'Jeremías 29:11',
      'category': 'Esperanza',
    },
    {
      'text':
          'Pero los que esperan a Jehová tendrán nuevas fuerzas; levantarán alas como las águilas; correrán, y no se cansarán; caminarán, y no se fatigarán.',
      'reference': 'Isaías 40:31',
      'category': 'Esperanza',
    },
    // Sabiduría
    {
      'text':
          'Confía en Jehová con todo tu corazón, y no te apoyes en tu propia prudencia. Reconócelo en todos tus caminos, y él enderezará tus veredas.',
      'reference': 'Proverbios 3:5-6',
      'category': 'Sabiduría',
    },
    {
      'text':
          'Y si alguno de vosotros tiene falta de sabiduría, pídala a Dios, el cual da a todos abundantemente y sin reproche, y le será dada.',
      'reference': 'Santiago 1:5',
      'category': 'Sabiduría',
    },
    {
      'text':
          'El principio de la sabiduría es el temor de Jehová; buen entendimiento tienen todos los que practican sus mandamientos.',
      'reference': 'Salmos 111:10',
      'category': 'Sabiduría',
    },
    // Salvación
    {
      'text':
          'Porque no envió Dios a su Hijo al mundo para condenar al mundo, sino para que el mundo sea salvo por él.',
      'reference': 'Juan 3:17',
      'category': 'Salvación',
    },
    {
      'text':
          'Que si confesares con tu boca que Jesús es el Señor, y creyeres en tu corazón que Dios le levantó de los muertos, serás salvo.',
      'reference': 'Romanos 10:9',
      'category': 'Salvación',
    },
    // Gratitud
    {
      'text':
          'Dad gracias en todo, porque esta es la voluntad de Dios para con vosotros en Cristo Jesús.',
      'reference': '1 Tesalonicenses 5:18',
      'category': 'Gratitud',
    },
    {
      'text':
          'Entrad por sus puertas con acción de gracias, por sus atrios con alabanza; alabadle, bendecid su nombre.',
      'reference': 'Salmos 100:4',
      'category': 'Gratitud',
    },
    // Perdón
    {
      'text':
          'Si confesamos nuestros pecados, él es fiel y justo para perdonar nuestros pecados, y limpiarnos de toda maldad.',
      'reference': '1 Juan 1:9',
      'category': 'Perdón',
    },
    {
      'text':
          'Antes sed benignos unos con otros, misericordiosos, perdonándoos unos a otros, como Dios también os perdonó a vosotros en Cristo.',
      'reference': 'Efesios 4:32',
      'category': 'Perdón',
    },
    // Paz
    {
      'text':
          'La paz os dejo, mi paz os doy; yo no os la doy como el mundo la da. No se turbe vuestro corazón, ni tenga miedo.',
      'reference': 'Juan 14:27',
      'category': 'Paz',
    },
    {
      'text':
          'Por nada estéis afanosos, sino sean conocidas vuestras peticiones delante de Dios en toda oración y ruego, con acción de gracias.',
      'reference': 'Filipenses 4:6',
      'category': 'Paz',
    },
    {
      'text':
          'Jehová es mi pastor; nada me faltará. En lugares de delicados pastos me hará descansar; junto a aguas de reposo me pastoreará.',
      'reference': 'Salmos 23:1-2',
      'category': 'Paz',
    },
  ];

  // Filtrar versículos según categoría y búsqueda
  List<Map<String, String>> get _filteredVerses {
    var verses = _allVerses;

    // Filtrar por categoría
    if (_selectedCategory != 'Todas') {
      verses = verses.where((v) => v['category'] == _selectedCategory).toList();
    }

    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      verses =
          verses.where((v) {
            final text = v['text']!.toLowerCase();
            final reference = v['reference']!.toLowerCase();
            final query = _searchQuery.toLowerCase();
            return text.contains(query) || reference.contains(query);
          }).toList();
    }

    return verses;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Stack(
        children: [
          // Fondo con gradiente sutil
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
              ),
            ),
          ),

          // Contenido principal
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF6B46C1,
                            ).withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.explore,
                            color: Color(0xFF6B46C1),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Explorar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Descubre versículos por categoría',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Barra de búsqueda
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      key: const ValueKey('search_bible_verses'),
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      autofillHints: const [AutofillHints.name],
                      decoration: InputDecoration(
                        hintText: 'Buscar versículos...',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          onPressed: () => _searchController.clear(),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Filtros de categoría
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = category == _selectedCategory;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? const Color(0xFF6B46C1)
                                        : Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? const Color(0xFF6B46C1)
                                          : Colors.white.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Lista de versículos
                  Expanded(
                    child:
                        _filteredVerses.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No se encontraron versículos',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.6,
                                      ),
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              itemCount: _filteredVerses.length,
                              itemBuilder: (context, index) {
                                return _buildVerseCard(
                                  context,
                                  _filteredVerses[index],
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerseCard(BuildContext context, Map<String, String> verse) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B46C1).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color(0xFF6B46C1).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  verse['category']!,
                  style: const TextStyle(
                    color: Color(0xFF6B46C1),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(17.5),
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.favorite_border,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 18,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            verse['text']!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            verse['reference']!,
            style: const TextStyle(
              color: Color(0xFF6B46C1),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
