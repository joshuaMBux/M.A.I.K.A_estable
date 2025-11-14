# 🧪 Testing de la API de Rasa - Maika App

Este documento explica cómo probar la conexión entre tu aplicación Flutter y tu modelo de Rasa.

## 📋 Requisitos Previos

1. **Servidor de Rasa ejecutándose**
   - Rasa debe estar corriendo en `http://localhost:5005`
   - El webhook debe estar habilitado en `/webhooks/rest/webhook`

2. **Aplicación Flutter**
   - Todas las dependencias instaladas
   - Aplicación ejecutándose en un dispositivo/emulador

## 🚀 Cómo Probar la API

### 1. Acceder a la Pantalla de Testing

1. Ejecuta la aplicación Flutter
2. Navega a la pestaña "Test" en la barra de navegación inferior
3. Verás la pantalla de testing de Rasa API

### 2. Verificar el Estado de la Conexión

La pantalla de testing muestra automáticamente:
- ✅ **Estado de conexión**: Verde si está conectado, rojo si hay error
- 📡 **URL configurada**: La URL actual de Rasa
- ⚠️ **Errores**: Si hay problemas de conexión

### 3. Probar la Conexión

**Botón "Probar Conexión"**
- Envía un mensaje de prueba a Rasa
- Verifica que el servidor responda correctamente
- Actualiza el estado de conexión

### 4. Enviar Mensajes de Prueba

**Mensajes Individuales:**
1. Escribe un mensaje en el campo de texto
2. Presiona el botón de enviar o Enter
3. Observa la respuesta de Rasa

**Mensajes Automáticos:**
- Presiona "Enviar Tests" para ejecutar una serie de mensajes predefinidos
- Útil para probar diferentes tipos de respuestas

## 🔧 Configuración

### URLs de Rasa

Puedes configurar diferentes URLs en `lib/core/constants/rasa_config.dart`:

```dart
static const String localRasaUrl = 'http://localhost:5005/webhooks/rest/webhook';
static const String dockerRasaUrl = 'http://localhost:5005/webhooks/rest/webhook';
static const String cloudRasaUrl = 'https://your-rasa-instance.com/webhooks/rest/webhook';
```

### Configuración de Timeouts

```dart
static const Duration connectionTimeout = Duration(seconds: 10);
static const Duration responseTimeout = Duration(seconds: 30);
```

### Logging

El sistema incluye logging detallado:
- 🌐 **Requests**: Muestra las peticiones enviadas
- 📥 **Responses**: Muestra las respuestas recibidas
- ❌ **Errors**: Muestra errores detallados

## 🐛 Solución de Problemas

### Error: "Connection refused"
- **Causa**: Rasa no está ejecutándose
- **Solución**: Inicia el servidor de Rasa con `rasa run`

### Error: "HTTP Error: 404"
- **Causa**: URL incorrecta o webhook no configurado
- **Solución**: Verifica la URL y configuración del webhook

### Error: "Timeout"
- **Causa**: Rasa tarda mucho en responder
- **Solución**: Aumenta el timeout en la configuración

### Error: "Invalid JSON"
- **Causa**: Rasa devuelve respuesta malformada
- **Solución**: Verifica la configuración de Rasa

## 📊 Información de Debugging

La pantalla de testing muestra:
- **Estado de conexión en tiempo real**
- **Último error ocurrido**
- **URL actual configurada**
- **Logs detallados en la consola**

## 🔄 Flujo de Testing Recomendado

1. **Verificar Rasa está corriendo**
   ```bash
   rasa run
   ```

2. **Abrir la app y ir a la pestaña Test**

3. **Probar conexión básica**
   - Presionar "Probar Conexión"
   - Verificar que aparezca ✅ Conectado

4. **Enviar mensajes de prueba**
   - Usar "Enviar Tests" para mensajes automáticos
   - Probar mensajes personalizados

5. **Verificar respuestas**
   - Las respuestas deben aparecer en el chat
   - Revisar logs en la consola para debugging

## 📝 Logs de Ejemplo

```
🌐 API Request to: http://localhost:5005/webhooks/rest/webhook
📤 Request body: {"sender":"test_user","message":"hola"}
📥 Response status: 200
📥 Response body: [{"recipient_id":"test_user","text":"¡Hola! ¿En qué puedo ayudarte?"}]
```

## 🎯 Próximos Pasos

Una vez que la conexión funcione correctamente:
1. Integra el chat en la pantalla principal
2. Configura manejo de errores más robusto
3. Implementa persistencia de conversaciones
4. Agrega funcionalidades específicas de tu modelo de Rasa

## 📞 Soporte

Si tienes problemas:
1. Revisa los logs en la consola
2. Verifica la configuración de Rasa
3. Comprueba que la URL sea correcta
4. Asegúrate de que Rasa esté ejecutándose 