# 🎯 Microservicio de Perfil de Usuario - AlworkiAuto

## 📋 Descripción

El microservicio de perfil de usuario proporciona funcionalidades completas para la gestión de perfiles de usuarios en la plataforma AlworkiAuto. Incluye operaciones CRUD, búsqueda, estadísticas y gestión de avatares.

## 🏗️ Arquitectura

### Componentes

- **Profile Service** (Puerto 5003): Microservicio principal
- **API Gateway** (Puerto 5002): Punto de entrada unificado
- **Database**: SQLite con SQLAlchemy ORM
- **Authentication**: JWT tokens

### Modelos de Datos

#### User (Usuario)
```python
{
    "id": 1,
    "firstname": "Juan",
    "lastname": "Pérez",
    "email": "juan@example.com",
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:30:00Z",
    "is_active": true,
    "is_verified": false
}
```

#### UserProfile (Perfil de Usuario)
```python
{
    "id": 1,
    "user_id": 1,
    "avatar_url": "/uploads/avatars/avatar_1.jpg",
    "bio": "Desarrollador web apasionado...",
    "phone": "+34 600 123 456",
    "date_of_birth": "1990-05-15",
    "gender": "male",
    "country": "España",
    "city": "Madrid",
    "address": "Calle Principal 123",
    "postal_code": "28001",
    "profession": "Desarrollador Full Stack",
    "company": "TechCorp",
    "website": "https://juanperez.dev",
    "linkedin_url": "https://linkedin.com/in/juanperez",
    "github_url": "https://github.com/juanperez",
    "language": "es",
    "timezone": "Europe/Madrid",
    "notification_email": true,
    "notification_push": false,
    "profile_views": 150,
    "projects_completed": 15,
    "rating_average": 4.8,
    "total_reviews": 23,
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:30:00Z"
}
```

## 🚀 Instalación y Configuración

### 1. Instalar dependencias
```bash
cd Backend
pip install -r requirements.txt
```

### 2. Ejecutar todos los microservicios
```bash
python run_microservices.py
```

### 3. Ejecutar solo el servicio de perfil
```bash
python services/profile_service.py
```

### 4. Probar el servicio
```bash
python test_profile_service.py
```

## 📡 Endpoints

### Base URL
- **API Gateway**: `http://localhost:5002`
- **Profile Service**: `http://localhost:5003`

### Autenticación
Todos los endpoints protegidos requieren un token JWT en el header:
```
Authorization: Bearer <token>
```

### Endpoints Disponibles

#### 1. Obtener Perfil Actual
```http
GET /api/profile
Authorization: Bearer <token>
```

**Respuesta:**
```json
{
    "user": {
        "id": 1,
        "firstname": "Juan",
        "lastname": "Pérez",
        "email": "juan@example.com",
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-15T10:30:00Z",
        "is_active": true,
        "is_verified": false
    },
    "profile": {
        "id": 1,
        "user_id": 1,
        "avatar_url": "/uploads/avatars/avatar_1.jpg",
        "bio": "Desarrollador web apasionado...",
        // ... resto de campos del perfil
    }
}
```

#### 2. Actualizar Perfil
```http
PUT /api/profile
Authorization: Bearer <token>
Content-Type: application/json

{
    "bio": "Nueva descripción",
    "profession": "Desarrollador Full Stack",
    "company": "Nueva Empresa",
    "country": "España",
    "city": "Barcelona",
    "phone": "+34 600 123 456",
    "website": "https://miwebsite.com",
    "linkedin_url": "https://linkedin.com/in/mi-perfil",
    "github_url": "https://github.com/mi-usuario",
    "language": "es",
    "notification_email": true,
    "notification_push": false
}
```

**Respuesta:**
```json
{
    "message": "Perfil actualizado exitosamente",
    "profile": {
        // Datos actualizados del perfil
    }
}
```

#### 3. Subir Avatar
```http
POST /api/profile/avatar
Authorization: Bearer <token>
Content-Type: multipart/form-data

avatar: <archivo>
```

**Respuesta:**
```json
{
    "message": "Avatar subido exitosamente",
    "avatar_url": "/uploads/avatars/avatar_1_20240115_103000.jpg"
}
```

#### 4. Actualizar Estadísticas
```http
PUT /api/profile/stats
Authorization: Bearer <token>
Content-Type: application/json

{
    "projects_completed": 15,
    "rating_average": 4.8,
    "total_reviews": 23
}
```

**Respuesta:**
```json
{
    "message": "Estadísticas actualizadas exitosamente"
}
```

#### 5. Buscar Perfiles
```http
GET /api/profile/search?q=desarrollador&profession=Desarrollador&country=España&page=1&per_page=10
```

**Respuesta:**
```json
{
    "profiles": [
        {
            "user": {
                "id": 1,
                "firstname": "Juan",
                "lastname": "Pérez",
                "created_at": "2024-01-15T10:30:00Z"
            },
            "profile": {
                "avatar_url": "/uploads/avatars/avatar_1.jpg",
                "bio": "Desarrollador web...",
                "profession": "Desarrollador Full Stack",
                "company": "TechCorp",
                "country": "España",
                "city": "Madrid",
                "profile_views": 150,
                "projects_completed": 15,
                "rating_average": 4.8,
                "total_reviews": 23
            }
        }
    ],
    "pagination": {
        "page": 1,
        "per_page": 10,
        "total": 25,
        "pages": 3,
        "has_next": true,
        "has_prev": false
    }
}
```

#### 6. Obtener Perfil Público
```http
GET /api/profile/{user_id}
```

**Respuesta:**
```json
{
    "user": {
        "id": 1,
        "firstname": "Juan",
        "lastname": "Pérez",
        "created_at": "2024-01-15T10:30:00Z"
    },
    "profile": {
        "avatar_url": "/uploads/avatars/avatar_1.jpg",
        "bio": "Desarrollador web...",
        "profession": "Desarrollador Full Stack",
        "company": "TechCorp",
        "country": "España",
        "city": "Madrid",
        "website": "https://juanperez.dev",
        "linkedin_url": "https://linkedin.com/in/juanperez",
        "github_url": "https://github.com/juanperez",
        "profile_views": 150,
        "projects_completed": 15,
        "rating_average": 4.8,
        "total_reviews": 23
    }
}
```

#### 7. Eliminar Perfil
```http
DELETE /api/profile/delete
Authorization: Bearer <token>
```

**Respuesta:**
```json
{
    "message": "Perfil eliminado exitosamente"
}
```

## 🔍 Parámetros de Búsqueda

### Búsqueda de Perfiles
- `q`: Texto de búsqueda (nombre, bio, profesión, empresa)
- `profession`: Filtrar por profesión
- `country`: Filtrar por país
- `city`: Filtrar por ciudad
- `page`: Número de página (default: 1)
- `per_page`: Elementos por página (default: 10, máximo: 50)

### Ejemplos de Búsqueda
```bash
# Buscar desarrolladores en España
GET /api/profile/search?q=desarrollador&country=España

# Buscar diseñadores en Madrid
GET /api/profile/search?profession=Diseñador&city=Madrid

# Buscar por nombre o descripción
GET /api/profile/search?q=Juan Pérez
```

## 🔐 Validaciones

### Campos del Perfil
- **date_of_birth**: Formato YYYY-MM-DD
- **gender**: 'male', 'female', 'other'
- **language**: 'es', 'en'
- **rating_average**: Entre 0 y 5
- **phone**: Formato internacional recomendado

### Avatar
- **Tipos permitidos**: PNG, JPG, JPEG, GIF
- **Tamaño máximo**: 5MB
- **Ubicación**: `/uploads/avatars/`

## 📊 Estadísticas Automáticas

El servicio mantiene automáticamente:
- **profile_views**: Incrementa cada vez que se accede al perfil
- **updated_at**: Se actualiza automáticamente en cada modificación

## 🛠️ Desarrollo

### Estructura de Archivos
```
Backend/
├── services/
│   ├── profile_service.py      # Microservicio principal
│   ├── api_gateway.py          # API Gateway
│   └── auth_service.py         # Servicio de autenticación
├── utils/
│   └── database.py             # Modelos y gestor de BD
├── config/
│   └── config.py               # Configuración central
├── uploads/
│   └── avatars/                # Avatares subidos
├── run_microservices.py        # Script de ejecución
├── test_profile_service.py     # Script de pruebas
└── requirements.txt            # Dependencias
```

### Agregar Nuevos Campos

1. **Modificar modelo** en `utils/database.py`:
```python
class UserProfile(db.Model):
    # Agregar nuevo campo
    new_field = db.Column(db.String(100))
```

2. **Actualizar método `to_dict()`**:
```python
def to_dict(self):
    return {
        # ... campos existentes
        'new_field': self.new_field,
    }
```

3. **Actualizar `allowed_fields`** en el servicio:
```python
allowed_fields = [
    # ... campos existentes
    'new_field'
]
```

4. **Ejecutar migración**:
```bash
flask db migrate -m "Add new_field to UserProfile"
flask db upgrade
```

## 🧪 Pruebas

### Ejecutar Pruebas Automáticas
```bash
python test_profile_service.py
```

### Pruebas Manuales con curl

#### 1. Obtener perfil
```bash
curl -X GET "http://localhost:5002/api/profile" \
  -H "Authorization: Bearer <token>"
```

#### 2. Actualizar perfil
```bash
curl -X PUT "http://localhost:5002/api/profile" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "bio": "Nueva descripción",
    "profession": "Desarrollador Full Stack"
  }'
```

#### 3. Buscar perfiles
```bash
curl -X GET "http://localhost:5002/api/profile/search?q=desarrollador"
```

## 🚨 Manejo de Errores

### Códigos de Estado HTTP
- `200`: Operación exitosa
- `201`: Recurso creado
- `400`: Datos inválidos
- `401`: No autorizado
- `404`: Recurso no encontrado
- `500`: Error interno del servidor

### Respuestas de Error
```json
{
    "error": "Descripción del error"
}
```

## 🔧 Configuración

### Variables de Entorno
```bash
# Base de datos
DATABASE_URI=sqlite:///auth.db

# Seguridad
SECRET_KEY=tu-clave-secreta-aqui

# Servicios
AUTH_SERVICE_PORT=5000
CARDS_SERVICE_PORT=5001
PROFILE_SERVICE_PORT=5003
API_GATEWAY_PORT=5002
```

### Configuración de CORS
```python
cors_origins = [
    "http://localhost:3000",
    "http://localhost:5173",
    "http://127.0.0.1:5173"
]
```

## 📈 Monitoreo

### Health Check
```http
GET /health
```

**Respuesta:**
```json
{
    "service": "profile",
    "status": "healthy",
    "timestamp": "2024-01-15T10:30:00Z"
}
```

### Métricas Disponibles
- Tiempo de respuesta
- Número de peticiones
- Errores por endpoint
- Uso de memoria

## 🔄 Integración con Frontend

### Ejemplo de Uso en Vue.js
```javascript
// Obtener perfil
const getProfile = async () => {
  try {
    const response = await fetch('/api/profile', {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    const data = await response.json();
    return data;
  } catch (error) {
    console.error('Error obteniendo perfil:', error);
  }
};

// Actualizar perfil
const updateProfile = async (profileData) => {
  try {
    const response = await fetch('/api/profile', {
      method: 'PUT',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(profileData)
    });
    const data = await response.json();
    return data;
  } catch (error) {
    console.error('Error actualizando perfil:', error);
  }
};
```

## 🤝 Contribución

1. Fork el repositorio
2. Crea una rama para tu feature
3. Implementa los cambios
4. Ejecuta las pruebas
5. Crea un Pull Request

## 📄 Licencia

Este proyecto está bajo la licencia MIT.

---

**Desarrollado para AlworkiAuto** 🚀

