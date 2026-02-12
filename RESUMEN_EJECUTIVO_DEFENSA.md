# ⚡ RESUMEN EJECUTIVO - DEFENSA RÁPIDA
## Lo que DEBES saber en 5 minutos

---

## 🎯 TU PROYECTO EN 30 SEGUNDOS

**Maika** es un asistente bíblico inteligente que usa **IA conversacional (Rasa)** para ayudar a usuarios a encontrar y entender versículos bíblicos de forma personalizada. Construido con **Flutter** y **Clean Architecture**, funciona en múltiples plataformas con modo offline.

---

## 🏗️ ARQUITECTURA (Pregunta #1 más común)

```
3 CAPAS:
1. Presentation → UI + BLoC (Estado)
2. Domain → Lógica de negocio
3. Data → SQLite + API
```

**¿Por qué?** Separación de responsabilidades, testeable, escalable

---

## 💻 TECNOLOGÍAS CLAVE

| Tecnología | Propósito | Por qué |
|------------|-----------|---------|
| **Flutter** | Frontend | Multiplataforma, rápido |
| **Rasa** | IA | NLP conversacional |
| **SQLite** | BD | Local, rápida, offline |
| **BLoC** | Estado | Predecible, testeable |
| **GetIt** | DI | Desacoplamiento |

---

## 🔥 FUNCIONALIDADES PRINCIPALES

1. **Chat con IA** - Conversación natural sobre la Biblia
2. **Explorar** - 20 versículos, búsqueda + filtros
3. **Favoritos** - Guardar versículos (backend funciona)
4. **Modo Offline** - Funciona sin internet
5. **Planes de Lectura** - Seguimiento diario

---

## 📊 BASE DE DATOS

**20 tablas** en 4 grupos:
- Core: usuario, versiculo, libro, categoria
- Interacción: favorito, historial, nota
- Aprendizaje: plan_lectura, devocional
- Gamificación: actividad, racha

**Optimizaciones:**
- Índices en búsquedas frecuentes
- Foreign keys para integridad
- Consultas preparadas

---

## 🤖 RASA (IA)

**Flujo:**
1. Usuario escribe → App envía POST
2. Rasa procesa (NLU) → Identifica intención
3. Rasa responde → App muestra

**Ventaja:** Entiende lenguaje natural, no necesitas saber referencias exactas

---

## 💡 LÍNEAS DE CÓDIGO MÁS IMPORTANTES

### 1. Inicialización
```dart
void main() async {
  await di.init();  // Inyección de dependencias
  runApp(const MaikaApp());
}
```

### 2. Enviar Mensaje (BLoC)
```dart
on<ChatMessageSubmitted>(_onMessageSubmitted);
// Maneja eventos → Llama UseCase → Emite estado
```

### 3. Llamada a Rasa
```dart
await _dio.post(RasaConfig.currentRasaUrl,
  data: {'sender': sender, 'message': message}
);
```

### 4. Guardar Favorito
```dart
await db.update('messages',
  {'is_favorite': isFavorite ? 1 : 0},
  where: 'id = ?'
);
```

---

## 🎬 PARA LA DEMO

### Flujo recomendado (5 min):
1. **Login** (30s)
2. **Home** - Mostrar dashboard (30s)
3. **Explorar** - Filtrar "Esperanza" + buscar "amor" (2min) ⭐
4. **Chat** - 3 preguntas a Maika (2min) ⭐⭐⭐
5. **Cierre** - Explicar arquitectura (1min)

### ⚠️ EVITAR:
- NO mostrar pantalla de Favoritos (solo tiene mock)
- NO entrar en detalles técnicos complejos sin que pregunten

---

## 🎯 RESPUESTAS RÁPIDAS

### "¿Por qué Clean Architecture?"
> Separación de responsabilidades, testeable, escalable

### "¿Por qué Flutter?"
> Multiplataforma, performance nativa, hot reload

### "¿Cómo funciona offline?"
> SQLite local + mensajes pendientes que se sincronizan

### "¿Qué hace diferente a Maika?"
> IA conversacional que entiende contexto emocional, no solo busca versículos

### "¿Cuál fue el mayor desafío?"
> Integración con Rasa en múltiples plataformas

---

## 🚨 SI ALGO FALLA EN LA DEMO

1. **Mantén la calma**
2. **Explica qué debería pasar**
3. **Muestra screenshots de respaldo**
4. **Continúa con confianza**

---

## 💪 FRASES PODEROSAS

**Inicio:**
> "Maika democratiza el acceso al conocimiento bíblico mediante IA conversacional"

**Arquitectura:**
> "Implementé Clean Architecture para garantizar mantenibilidad y escalabilidad"

**IA:**
> "Rasa permite que usuarios pregunten en lenguaje natural, sin conocer referencias exactas"

**Cierre:**
> "Este proyecto demuestra que la IA puede ser una herramienta de crecimiento espiritual"

---

## ✅ CHECKLIST ÚLTIMO MINUTO

- [ ] App funcionando
- [ ] Maika.png se ve bien
- [ ] Explorar funciona (búsqueda + filtros)
- [ ] Chat responde (o tienes plan B)
- [ ] Respiras profundo
- [ ] Sonríes

---

## 🎓 RECUERDA

**Tú conoces este proyecto mejor que nadie.**
**Has trabajado duro.**
**Vas a defender algo valioso.**

**¡CONFÍA EN TI! 🚀**
