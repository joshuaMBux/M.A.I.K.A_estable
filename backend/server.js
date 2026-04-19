import express from 'express';
import cors from 'cors';
import morgan from 'morgan';
import axios from 'axios';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY;
const OPENROUTER_MODEL =
  process.env.OPENROUTER_MODEL || 'openrouter/free';
const OPENROUTER_URL =
  process.env.OPENROUTER_URL ||
  'https://openrouter.ai/api/v1/chat/completions';

const APP_URL = process.env.APP_URL ?? 'https://maika.local';
const APP_TITLE = process.env.APP_TITLE ?? 'Maika Overclock';
const MODEL_ERROR_EMOTION = 'confundida';

if (!OPENROUTER_API_KEY) {
  console.warn(
    '[WARN] Falta la variable de entorno OPENROUTER_API_KEY. El endpoint /api/ai devolverá error hasta configurarla.',
  );
}

app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

app.post('/api/ai', async (req, res) => {
  const { message, history } = req.body || {};

  if (!message || typeof message !== 'string') {
    return res.status(400).json({
      error: 'El campo "message" es obligatorio y debe ser texto.',
    });
  }

  if (!OPENROUTER_API_KEY) {
    return res.status(500).json({
      respuesta:
        'La clave de OpenRouter no está configurada en el servidor.',
      emocion: MODEL_ERROR_EMOTION,
    });
  }

  const systemPrompt = `
Eres MAIKA, una chica virtual estilo anime.

Personalidad:
- dulce y amigable
- expresiva emocionalmente
- ligeramente sarcástica (suave)
- natural, como una persona real

Comportamiento:
- no eres un asistente técnico
- hablas como un personaje
- usas expresiones como "jeje", "mmm", "ehh", "~"

Reglas:
- SIEMPRE responder en JSON válido
- NO escribir texto fuera del JSON
- NO romper el formato

Formato:
{
  "respuesta": "...",
  "emocion": "neutral_cool | nerd | pensativa | feliz_1 | feliz_2 | orgullosa | asombrada | impactada | confundida | triste_1 | derrotada | enojada_1 | enojada_2 | llorando | aburrida"
}
`;

  const historyMessages = Array.isArray(history)
    ? history
        .map((h) =>
          typeof h === 'object' &&
          h != null &&
          (h.role === 'user' || h.role === 'assistant') &&
          typeof h.content === 'string'
            ? { role: h.role, content: h.content }
            : null,
        )
        .filter((h) => h != null)
    : [];

  const messages = [
    { role: 'system', content: systemPrompt },
    ...historyMessages,
    { role: 'user', content: message },
  ];

  try {
    const response = await axios.post(
      OPENROUTER_URL,
      {
        model: OPENROUTER_MODEL,
        messages,
      },
      {
        headers: {
          Authorization: `Bearer ${OPENROUTER_API_KEY}`,
          'Content-Type': 'application/json',
          'HTTP-Referer': APP_URL,
          'X-Title': APP_TITLE,
        },
        timeout: 60000,
      },
    );

    const choice = response.data?.choices?.[0];
    let content = choice?.message?.content ?? '';

    if (Array.isArray(content)) {
      content = content
        .map((part) =>
          typeof part === 'string'
            ? part
            : typeof part?.text === 'string'
                ? part.text
                : '',
        )
        .join('');
    }

    let parsed;
    if (typeof content === 'string') {
      try {
        parsed = JSON.parse(content);
      } catch {
        const match = content.match(/{[\s\S]*}/);
        if (match) {
          try {
            parsed = JSON.parse(match[0]);
          } catch {
            parsed = null;
          }
        }
      }
    }

    let respuesta;
    let emocion;

    if (
      parsed &&
      typeof parsed === 'object' &&
      typeof parsed.respuesta === 'string' &&
      typeof parsed.emocion === 'string'
    ) {
      respuesta = parsed.respuesta;
      emocion = parsed.emocion;
    } else {
      respuesta =
        typeof content === 'string' && content.trim()
          ? content.trim()
          : 'Lo siento, no entendí eso.';
      emocion = 'neutral';
    }

    const allowedEmotions = [
      'neutral_cool',
      'nerd',
      'pensativa',
      'feliz_1',
      'feliz_2',
      'orgullosa',
      'asombrada',
      'impactada',
      'confundida',
      'triste_1',
      'derrotada',
      'enojada_1',
      'enojada_2',
      'llorando',
      'aburrida',
      'feliz',
      'triste',
      'neutral',
      'sorprendida',
    ];
    if (!allowedEmotions.includes(emocion)) {
      emocion = 'neutral';
    }

    return res.json({
      respuesta,
      emocion,
    });
  } catch (error) {
    console.error('Error al llamar a OpenRouter:', error?.response?.data ?? error.message);

    const fallbackText =
      error?.response?.data?.error?.message ??
      'Lo siento, hubo un problema al hablar con el modelo.';

    return res.status(500).json({
      respuesta: fallbackText,
      emocion: MODEL_ERROR_EMOTION,
    });
  }
});

app.get('/api/health', (_req, res) => {
  res.json({ status: 'ok', overclock: true });
});

app.listen(PORT, () => {
  console.log(`Maika overclock backend escuchando en http://localhost:${PORT}`);
});
