import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _sendEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      // Correo de soporte del desarrollador.
      path: 'josuemoya46@gmail.com',
      query: 'subject=Ayuda%20con%20Maika',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayuda y soporte')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: const [
          ExpansionTile(
            title: Text('¿Cómo inicio una conversación con Maika?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '1. Ve a la pestaña "Chat".\n'
                  '2. Escribe tu pregunta o tema (por ejemplo: "explícame Juan 3:16" o "ayúdame a organizar mi plan de lectura").\n'
                  '3. Pulsa el botón de enviar.\n\n'
                  'Maika responderá en la misma conversación. Puedes seguir preguntando en el mismo hilo para mantener el contexto, '
                  'o empezar un nuevo tema simplemente cambiando de pregunta.',
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: Text('¿Cómo guardo un mensaje como favorito?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Cuando veas un mensaje importante (por ejemplo, una explicación que te gustó o un versículo clave):\n'
                  '- Toca el ícono de estrella en la tarjeta de chat.\n'
                  '- El mensaje quedará guardado en la sección de "Favoritos" para que puedas revisarlo más adelante sin perderlo.\n\n'
                  'También puedes marcar como favorito el versículo del día desde la tarjeta principal.',
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: Text('¿Cómo personalizo mi avatar y el fondo de perfil?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '1. Abre la pestaña de "Perfil".\n'
                  '2. Toca tu foto de perfil para cambiar el avatar: podrás tomar una foto o elegir una de la galería.\n'
                  '3. Toca el área del fondo (la tarjeta grande detrás del avatar) para cambiar la imagen de fondo.\n'
                  '4. Si quieres volver al estado inicial, puedes eliminar la foto o el fondo desde las mismas opciones.\n\n'
                  'Las imágenes se guardan localmente en tu dispositivo, no se suben a ningún servidor.',
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: Text('¿Dónde veo mis métricas de los minijuegos?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '1. En el menú principal ve a la sección de "Juegos".\n'
                  '2. Entra en "Estadísticas de minijuegos".\n'
                  '3. Allí verás, por cada juego:\n'
                  '   - Cuántas sesiones has jugado.\n'
                  '   - La duración media de cada partida.\n'
                  '   - Cuántos fragmentos o puntos sueles conseguir.\n'
                  '   - El porcentaje de partidas completadas.\n\n'
                  'Estos datos se guardan en tu dispositivo y te ayudan a ver tu progreso y constancia con los juegos bíblicos.',
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: Text('¿Cómo funciona el plan de lectura bíblica?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'El plan de lectura organiza capítulos y pasajes para cada día:\n'
                  '- Maika carga el plan desde una fuente de datos (API bíblica / base local) y lo muestra por días.\n'
                  '- En la pantalla "Plan de lectura" verás tu progreso, los días completados y las lecturas pendientes.\n'
                  '- Cuando termines las lecturas de un día, marca la casilla "Hecho" para actualizar tu progreso.\n\n'
                  'Si algo falla al cargar el plan, puedes pulsar el botón "Reintentar" para que Maika vuelva a solicitar los datos.',
                ),
              ),
            ],
          ),
          ExpansionTile(
            title:
                Text('¿Cómo configuro notificaciones y el modo "No molestar"?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '1. Desde tu perfil, entra en "Configuración" y luego en "Notificaciones".\n'
                  '2. Activa o desactiva:\n'
                  '   - Notificaciones generales.\n'
                  '   - Recordatorio del versículo del día.\n'
                  '   - Recordatorio del plan de lectura.\n'
                  '3. Activa "Modo No molestar" si quieres silenciar recordatorios por la noche o en horarios específicos.\n\n'
                  'En futuras versiones, estas opciones podrán integrarse con notificaciones locales del sistema para recordarte tus lecturas.',
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: Text('¿Qué pasa con mis datos y mi privacidad?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Maika guarda en el dispositivo algunas preferencias, como:\n'
                  '- Tema (claro/oscuro).\n'
                  '- Idioma y tamaño de texto.\n'
                  '- Preferencias de notificaciones.\n'
                  '- Avatar y fondo de perfil.\n\n'
                  'Si quieres volver al estado inicial, en la pantalla de "Privacidad" puedes usar la opción "Limpiar datos locales". '
                  'Eso borrará los ajustes visuales y de configuración guardados, pero no tu sesión de usuario.',
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: _sendEmail,
          icon: const Icon(Icons.email_outlined),
          label: const Text('Contactar soporte'),
        ),
      ),
    );
  }
}
