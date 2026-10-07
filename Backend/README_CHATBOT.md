# 🤖 Chatbot Inteligente con RAG - AlworkiAuto

## 📋 Descripción

El microservicio de chatbot inteligente proporciona soporte automatizado usando **RAG (Retrieval-Augmented Generation)** con el modelo **Gemma 3 3B** de Google. El bot puede responder preguntas basándose en una base de conocimiento específica de la plataforma AlworkiAuto.

## 🏗️ Arquitectura

### Componentes

- **Chatbot Service** (Puerto 5004): Microservicio principal
- **API Gateway** (Puerto 5002): Punto de entrada unificado
- **Gemma 3 3B**: Modelo de lenguaje de Google
- **RAG System**: Sistema de recuperación y generación aumentada
- **FAISS**: Índice de búsqueda semántica
- **Sentence Transformers**: Modelo de embeddings

### Tecnologías

- **Modelo de Lenguaje**: Google Gemma 3 3B
- **Embeddings**: Sentence Transformers (all-MiniLM-L6-v2)
- **Búsqueda Vectorial**: FAISS
- **Framework**: Flask + Python
- **Autenticación**: JWT tokens

## 🚀 Instalación y Configuración

### 1. Instalar dependencias
```bash
cd Backend
pip install -r requirements.txt
```

### 2. Verificar requisitos del sistema
- **RAM**: Mínimo 8GB (recomendado 16GB)
- **GPU**: Opcional (acelera la inferencia)
- **Espacio**: ~5GB para modelos

### 3. Ejecutar todos los microservicios
```bash
python run_microservices.py
```

### 4. Ejecutar solo el chatbot
```bash
python services/chatbot_service.py
```

### 5. Probar el chatbot
```bash
python test_chatbot_service.py
```

## 📡 Endpoints

### Base URL
- **API Gateway**: `http://localhost:5002`
- **Chatbot Service**: `http://localhost:5004`

### Autenticación
Todos los endpoints requieren un token JWT en el header:
```
Authorization: Bearer <token>
```

### Endpoints Disponibles

#### 1. Chat Básico
```http
POST /api/chatbot/chat
Authorization: Bearer <token>
Content-Type: application/json

{
    "message": "¿Cómo crear una cuenta?"
}
```

**Respuesta:**
```json
{
    "response": "Para crear una cuenta en AlworkiAuto, sigue estos pasos:\n1. Ve a la página de registro\n2. Completa el formulario con tu información personal\n3. Verifica tu email\n4. Inicia sesión con tus credenciales",
    "confidence": true,
    "sources": ["cuenta"],
    "timestamp": "2024-01-15T10:30:00Z"
}
```

#### 2. Chat con Streaming
```http
POST /api/chatbot/chat/stream
Authorization: Bearer <token>
Content-Type: application/json

{
    "message": "¿Cuáles son las políticas de privacidad?"
}
```

**Respuesta:**
```json
{
    "response": "Nuestras políticas de privacidad incluyen...",
    "response_parts": [
        "Nuestras políticas de privacidad incluyen",
        "Protección de datos personales",
        "No compartimos información con terceros"
    ],
    "confidence": true,
    "sources": ["legal"],
    "timestamp": "2024-01-15T10:30:00Z"
}
```

#### 3. Enviar Feedback
```http
POST /api/chatbot/feedback
Authorization: Bearer <token>
Content-Type: application/json

{
    "message_id": "msg_123",
    "rating": 5,
    "comment": "Excelente respuesta, muy útil"
}
```

**Respuesta:**
```json
{
    "message": "Feedback guardado correctamente"
}
```

#### 4. Obtener Base de Conocimiento
```http
GET /api/chatbot/knowledge
```

**Respuesta:**
```json
{
    "knowledge_base": [
        {
            "question": "¿Cómo crear una cuenta?",
            "answer": "Para crear una cuenta...",
            "category": "cuenta"
        }
    ],
    "total_items": 10
}
```

#### 5. Agregar Conocimiento
```http
POST /api/chatbot/knowledge
Authorization: Bearer <token>
Content-Type: application/json

{
    "question": "¿Cómo funciona X?",
    "answer": "X funciona de la siguiente manera...",
    "category": "general"
}
```

## 🔍 Base de Conocimiento

### Categorías Disponibles

- **cuenta**: Creación y gestión de cuentas
- **intercambio**: Funcionamiento del intercambio de servicios
- **soporte**: Reportes y soporte técnico
- **legal**: Políticas y términos legales
- **calificaciones**: Sistema de calificaciones
- **comunicacion**: Problemas de comunicación
- **perfil**: Gestión de perfiles
- **servicios**: Tipos de servicios disponibles
- **seguridad**: Medidas de seguridad

### Estructura de Conocimiento

```json
{
    "question": "Pregunta del usuario",
    "answer": "Respuesta detallada",
    "category": "categoría"
}
```

## 🤖 Funcionamiento del RAG

### 1. **Recuperación (Retrieval)**
- El usuario envía una pregunta
- Se convierte la pregunta a embedding vectorial
- Se busca en la base de conocimiento usando FAISS
- Se recuperan los documentos más relevantes

### 2. **Generación (Generation)**
- Se construye un prompt con el contexto recuperado
- Se envía al modelo Gemma 3 3B
- Se genera una respuesta contextualizada
- Se devuelve la respuesta al usuario

### 3. **Proceso Completo**
```
Usuario → Embedding → Búsqueda FAISS → Contexto → Gemma 3 3B → Respuesta
```

## 📊 Métricas y Monitoreo

### Logs de Interacción
```json
{
    "timestamp": "2024-01-15T10:30:00Z",
    "user_id": 123,
    "user_message": "¿Cómo crear una cuenta?",
    "response": "Para crear una cuenta...",
    "relevant_docs": 2,
    "confidence": true
}
```

### Feedback de Usuarios
```json
{
    "user_id": 123,
    "message_id": "msg_123",
    "rating": 5,
    "comment": "Excelente respuesta",
    "timestamp": "2024-01-15T10:30:00Z"
}
```

## 🔧 Configuración Avanzada

### Variables de Entorno
```bash
# Modelo de lenguaje
MODEL_NAME=google/gemma-2-3b

# Modelo de embeddings
EMBEDDING_MODEL=all-MiniLM-L6-v2

# Configuración de búsqueda
TOP_K_RESULTS=3
SIMILARITY_THRESHOLD=0.3

# Configuración de generación
MAX_LENGTH=512
TEMPERATURE=0.7
```

### Personalización del Modelo

#### Cambiar Modelo de Lenguaje
```python
# En chatbot_service.py
self.model_name = "microsoft/DialoGPT-large"  # Modelo alternativo
```

#### Cambiar Modelo de Embeddings
```python
# En chatbot_service.py
self.embedding_model = SentenceTransformer('paraphrase-MiniLM-L3-v2')
```

#### Ajustar Parámetros de Búsqueda
```python
# Umbral de similitud
if score > 0.5:  # Más estricto
    relevant_docs.append(...)

# Número de resultados
scores, indices = self.index.search(query_embedding, top_k=5)
```

## 🧪 Pruebas

### Pruebas Automáticas
```bash
python test_chatbot_service.py
```

### Pruebas Manuales con curl

#### 1. Chat básico
```bash
curl -X POST "http://localhost:5002/api/chatbot/chat" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"message": "¿Cómo crear una cuenta?"}'
```

#### 2. Chat con streaming
```bash
curl -X POST "http://localhost:5002/api/chatbot/chat/stream" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"message": "¿Cuáles son las políticas de privacidad?"}'
```

#### 3. Obtener base de conocimiento
```bash
curl -X GET "http://localhost:5002/api/chatbot/knowledge"
```

## 🔄 Integración con Frontend

### Ejemplo de Uso en Vue.js
```javascript
// Chat básico
const chatWithBot = async (message) => {
  try {
    const response = await fetch('/api/chatbot/chat', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ message })
    });
    
    const data = await response.json();
    return data;
  } catch (error) {
    console.error('Error en chat:', error);
  }
};

// Chat con streaming
const chatWithStreaming = async (message) => {
  try {
    const response = await fetch('/api/chatbot/chat/stream', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ message })
    });
    
    const data = await response.json();
    
    // Mostrar respuesta progresivamente
    data.response_parts.forEach((part, index) => {
      setTimeout(() => {
        displayMessage(part);
      }, index * 100);
    });
    
    return data;
  } catch (error) {
    console.error('Error en chat streaming:', error);
  }
};

// Enviar feedback
const sendFeedback = async (messageId, rating, comment) => {
  try {
    const response = await fetch('/api/chatbot/feedback', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        message_id: messageId,
        rating: rating,
        comment: comment
      })
    });
    
    return await response.json();
  } catch (error) {
    console.error('Error enviando feedback:', error);
  }
};
```

## 🚨 Manejo de Errores

### Códigos de Estado HTTP
- `200`: Operación exitosa
- `400`: Datos inválidos
- `401`: No autorizado
- `500`: Error interno del servidor

### Respuestas de Error
```json
{
    "error": "Descripción del error"
}
```

### Errores Comunes

#### Modelo no disponible
```json
{
    "error": "Modelo de lenguaje no disponible, usando respaldo"
}
```

#### Memoria insuficiente
```json
{
    "error": "Memoria insuficiente para cargar el modelo"
}
```

#### Base de conocimiento vacía
```json
{
    "error": "Base de conocimiento no disponible"
}
```

## 📈 Optimización

### Rendimiento
- **Modelo en GPU**: Acelera la inferencia
- **Batching**: Procesar múltiples consultas
- **Caching**: Cachear respuestas frecuentes
- **Compresión**: Modelos cuantizados

### Escalabilidad
- **Load Balancing**: Múltiples instancias
- **Queue System**: Cola de procesamiento
- **Database**: Base de conocimiento en BD
- **CDN**: Distribución de contenido

## 🔒 Seguridad

### Medidas Implementadas
- **Autenticación JWT**: Verificación de usuarios
- **Rate Limiting**: Límite de consultas
- **Input Validation**: Validación de entrada
- **Logging**: Registro de interacciones
- **Error Handling**: Manejo seguro de errores

### Privacidad
- **No almacenamiento**: No se guardan conversaciones
- **Anonimización**: Logs sin datos personales
- **GDPR Compliance**: Cumplimiento de regulaciones

## 🤝 Contribución

### Agregar Nuevo Conocimiento
1. Editar `knowledge_base` en `chatbot_service.py`
2. Agregar pregunta y respuesta
3. Asignar categoría apropiada
4. Reconstruir índice FAISS

### Mejorar el Modelo
1. Fine-tuning con datos específicos
2. Ajustar hiperparámetros
3. Evaluar con métricas
4. Desplegar nueva versión

## 📄 Licencia

Este proyecto está bajo la licencia MIT.

---

**Desarrollado para AlworkiAuto** 🚀

*Chatbot inteligente con RAG y Gemma 3 3B*
