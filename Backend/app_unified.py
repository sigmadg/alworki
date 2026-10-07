from flask import Flask, request, jsonify
from flask_cors import CORS
import sqlite3
from werkzeug.security import generate_password_hash, check_password_hash
import os
from datetime import datetime, timedelta
import secrets
from auth.jwt_manager import jwt_manager, token_required
import catalog_db
from database import get_auth_connection as get_db_auth_connection, is_postgres
import supabase_service

app = Flask(__name__)
# Orígenes del FrontEnd (web + WebView Capacitor). Añade más con variable CORS_ORIGINS (coma-separada).
_cors_default = [
    'http://localhost:5173',
    'http://127.0.0.1:5173',
    'http://localhost:3000',
    'capacitor://localhost',
    'ionic://localhost',
    'http://localhost',
    'https://localhost',
]
_cors_extra = [o.strip() for o in os.environ.get('CORS_ORIGINS', '').split(',') if o.strip()]
CORS(app, origins=_cors_default + _cors_extra)

def _app_secret() -> str:
    env = os.environ.get('SECRET_KEY') or os.environ.get('JWT_SECRET_KEY')
    if env:
        return env
    secret_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'instance', '.jwt_secret')
    os.makedirs(os.path.dirname(secret_path), exist_ok=True)
    if os.path.exists(secret_path):
        return open(secret_path, encoding='utf-8').read().strip()
    generated = secrets.token_urlsafe(48)
    with open(secret_path, 'w', encoding='utf-8') as fh:
        fh.write(generated)
    os.chmod(secret_path, 0o600)
    return generated


# Configuración
app.config['SECRET_KEY'] = _app_secret()
app.config['JWT_SECRET_KEY'] = app.config['SECRET_KEY']
app.config['DATABASE'] = 'instance/auth.db'

# Inicializar JWT Manager
jwt_manager.init_app(app)
catalog_db.init_db()

BASE_DIR = os.path.dirname(os.path.abspath(__file__))


def get_auth_db_path():
    return os.path.join(BASE_DIR, 'instance', 'auth.db')


def get_auth_connection_legacy():
    path = get_auth_db_path()
    os.makedirs(os.path.dirname(path), exist_ok=True)
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    return conn


def get_auth_connection():
    if is_postgres():
        return get_db_auth_connection()
    return get_auth_connection_legacy()


def init_auth_db():
    if is_postgres():
        return
    conn = get_auth_connection_legacy()
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL COLLATE NOCASE,
            password_hash TEXT NOT NULL,
            firstname TEXT DEFAULT '',
            lastname TEXT DEFAULT '',
            role TEXT DEFAULT 'user',
            created_at TEXT DEFAULT (datetime('now'))
        )
        """
    )
    conn.commit()
    conn.close()


init_auth_db()

# Datos de ejemplo para tarjetas
CARDS_DATA = [
    {
        "id": 1,
        "title": "Diseño Web Profesional",
        "description": "Creación de sitios web modernos y responsivos con las últimas tecnologías",
        "image_url": "background1.png",
        "category": "Desarrollo Web",
        "price": 1500,
        "rating": 4.8,
        "reviews_count": 24,
        "last_updated": "2024-01-15"
    },
    {
        "id": 2,
        "title": "Aplicación Móvil iOS",
        "description": "Desarrollo de aplicaciones nativas para iPhone y iPad con Swift",
        "image_url": "background2.png",
        "category": "Desarrollo Móvil",
        "price": 2500,
        "rating": 4.9,
        "reviews_count": 18,
        "last_updated": "2024-01-10"
    },
    {
        "id": 3,
        "title": "Consultoría de UX/UI",
        "description": "Optimización de experiencia de usuario y diseño de interfaces",
        "image_url": "background3.png",
        "category": "Diseño",
        "price": 800,
        "rating": 4.7,
        "reviews_count": 31,
        "last_updated": "2024-01-12"
    },
    {
        "id": 4,
        "title": "Sistema de E-commerce",
        "description": "Plataforma completa de comercio electrónico con pasarelas de pago",
        "image_url": "background4.png",
        "category": "Desarrollo Web",
        "price": 3000,
        "rating": 4.6,
        "reviews_count": 15,
        "last_updated": "2024-01-08"
    },
    {
        "id": 5,
        "title": "Aplicación Android",
        "description": "Desarrollo de apps nativas para dispositivos Android",
        "image_url": "background5.png",
        "category": "Desarrollo Móvil",
        "price": 2000,
        "rating": 4.5,
        "reviews_count": 22,
        "last_updated": "2024-01-14"
    }
]

# Datos de ejemplo para el feed de Instagram
INSTAGRAM_FEED_DATA = [
    {
        "id": 1,
        "user": {
            "id": 1,
            "name": "Tina Shah",
            "avatar": "users/1.jpg",
            "verified": True,
            "following": False
        },
        "image_url": "background1.png",
        "description": "¡Nuevo proyecto terminado! Diseño web moderno para una startup tecnológica. #webdesign #startup #tech",
        "likes": 1247,
        "comments": 89,
        "cost": 1500,
        "cost_type": "USD",
        "card_id": 1,
        "card_title": "Diseño Web Profesional",
        "location": "San Francisco, CA",
        "timestamp": "2024-01-15T10:30:00Z",
        "recommended": False,
        "saved": False,
        "showMenu": False
    },
    {
        "id": 2,
        "user": {
            "id": 2,
            "name": "María González",
            "avatar": "users/2.jpg",
            "verified": False,
            "following": False
        },
        "image_url": "background2.png",
        "description": "Aplicación móvil iOS para gestión de tareas. Interfaz intuitiva y funcionalidades avanzadas. #ios #mobile #app",
        "likes": 892,
        "comments": 45,
        "cost": 2500,
        "cost_type": "USD",
        "card_id": 2,
        "card_title": "Aplicación Móvil iOS",
        "location": "Miami, FL",
        "timestamp": "2024-01-14T15:45:00Z",
        "recommended": False,
        "saved": False,
        "showMenu": False
    },
    {
        "id": 3,
        "user": {
            "id": 3,
            "name": "Carlos López",
            "avatar": "users/3.jpg",
            "verified": True,
            "following": False
        },
        "image_url": "background3.png",
        "description": "Rediseño completo de UX/UI para plataforma de e-learning. Mejora significativa en engagement. #ux #ui #design",
        "likes": 1567,
        "comments": 123,
        "cost": 800,
        "cost_type": "USD",
        "card_id": 3,
        "card_title": "Consultoría de UX/UI",
        "location": "Austin, TX",
        "timestamp": "2024-01-13T09:15:00Z",
        "recommended": False,
        "saved": False,
        "showMenu": False
    },
    {
        "id": 4,
        "user": {
            "id": 4,
            "name": "Ana Rodríguez",
            "avatar": "users/4.jpg",
            "verified": False,
            "following": False
        },
        "image_url": "background4.png",
        "description": "Sistema de e-commerce con integración de múltiples pasarelas de pago. Escalable y seguro. #ecommerce #payment",
        "likes": 2034,
        "comments": 167,
        "cost": 3000,
        "cost_type": "USD",
        "card_id": 4,
        "card_title": "Sistema de E-commerce",
        "location": "Seattle, WA",
        "timestamp": "2024-01-12T14:20:00Z",
        "recommended": False,
        "saved": False,
        "showMenu": False
    },
    {
        "id": 5,
        "user": {
            "id": 5,
            "name": "David Kim",
            "avatar": "users/5.jpg",
            "verified": True,
            "following": False
        },
        "image_url": "background5.png",
        "description": "App Android para delivery de comida. Geolocalización en tiempo real y notificaciones push. #android #delivery",
        "likes": 1789,
        "comments": 98,
        "cost": 2000,
        "cost_type": "USD",
        "card_id": 5,
        "card_title": "Aplicación Android",
        "location": "Los Angeles, CA",
        "timestamp": "2024-01-11T11:30:00Z",
        "recommended": False,
        "saved": False,
        "showMenu": False
    }
]

# Datos de ejemplo para historias
INSTAGRAM_STORIES_DATA = [
    {
        "id": 1,
        "user": {
            "id": 1,
            "name": "Tina Shah",
            "avatar": "users/1.jpg",
            "verified": True
        },
        "story_type": "image",
        "media_url": "background1.png",
        "caption": "Nuevo proyecto de diseño web completado",
        "image_url": "background1.png",
        "card_id": 1,
        "card_title": "Diseño Web Profesional",
        "timestamp": "2024-01-15T10:30:00Z",
        "duration": 5,
        "viewed": False
    },
    {
        "id": 2,
        "user": {
            "id": 2,
            "name": "María González",
            "avatar": "users/2.jpg",
            "verified": False
        },
        "story_type": "image",
        "media_url": "background2.png",
        "caption": "Desarrollando app iOS con las últimas tecnologías",
        "image_url": "background2.png",
        "card_id": 2,
        "card_title": "Aplicación Móvil iOS",
        "timestamp": "2024-01-15T09:15:00Z",
        "duration": 5,
        "viewed": False
    },
    {
        "id": 3,
        "user": {
            "id": 3,
            "name": "Carlos López",
            "avatar": "users/3.jpg",
            "verified": True
        },
        "story_type": "image",
        "media_url": "background3.png",
        "caption": "Optimizando la experiencia de usuario",
        "image_url": "background3.png",
        "card_id": 3,
        "card_title": "Consultoría de UX/UI",
        "timestamp": "2024-01-15T08:45:00Z",
        "duration": 5,
        "viewed": True
    },
    {
        "id": 4,
        "user": {
            "id": 4,
            "name": "Ana Rodríguez",
            "avatar": "users/4.jpg",
            "verified": False
        },
        "story_type": "image",
        "media_url": "background4.png",
        "caption": "E-commerce con funcionalidades avanzadas",
        "image_url": "background4.png",
        "card_id": 4,
        "card_title": "Sistema de E-commerce",
        "timestamp": "2024-01-15T07:30:00Z",
        "duration": 5,
        "viewed": False
    },
    {
        "id": 5,
        "user": {
            "id": 5,
            "name": "David Kim",
            "avatar": "users/5.jpg",
            "verified": True
        },
        "story_type": "image",
        "media_url": "background5.png",
        "caption": "App Android nativa con Material Design",
        "image_url": "background5.png",
        "card_id": 5,
        "card_title": "Aplicación Android",
        "timestamp": "2024-01-15T06:20:00Z",
        "duration": 5,
        "viewed": False
    }
]

# Datos de ejemplo para perfiles de usuario
USER_PROFILES_DATA = {
    1: {
        "id": 1,
        "name": "Tina Shah",
        "verified": True,
        "avatar": "users/1.jpg",
        "contacts": 70,
        "professions": ["Pintor", "Carpintero", "Escultor"],
        "localContacts": 1243,
        "remoteContacts": 1243,
        "localAvailable": False,
        "remoteAvailable": True,
        "skills": [
            {"id": 1, "name": "Pintura al oleo"},
            {"id": 2, "name": "Escultura"},
            {"id": 3, "name": "Mesa"}
        ],
        "portfolio": [
            {
                "id": 1,
                "title": "Retrato al óleo",
                "description": "Retrato clásico en técnica tradicional",
                "image": "background1.png"
            },
            {
                "id": 2,
                "title": "Escultura moderna",
                "description": "Escultura abstracta en mármol",
                "image": "background2.png"
            },
            {
                "id": 3,
                "title": "Mesa artesanal",
                "description": "Mesa de madera con diseño único",
                "image": "background3.png"
            }
        ],
        "reviews": [
            {
                "id": 1,
                "user": {
                    "id": 2,
                    "name": "María González",
                    "avatar": "users/2.jpg",
                    "verified": False
                },
                "rating": 5,
                "date": "2024-01-15",
                "text": "Excelente trabajo en mi retrato. Muy profesional y talentoso."
            },
            {
                "id": 2,
                "user": {
                    "id": 3,
                    "name": "Carlos López",
                    "avatar": "users/3.jpg",
                    "verified": True
                },
                "rating": 4,
                "date": "2024-01-10",
                "text": "Gran artista, muy recomendado para proyectos artísticos."
            }
        ]
    }
}

# Endpoints para perfiles de usuario
@app.route('/api/users/me/profile', methods=['GET', 'PUT'])
@token_required
def my_profile_api():
    """Perfil del usuario autenticado (JWT)."""
    uid = request.current_user['user_id']
    if request.method == 'GET':
        profile = catalog_db.get_profile(uid) or catalog_db.ensure_profile(
            uid,
            request.current_user.get('name', ''),
            request.current_user.get('email', ''),
        )
        return jsonify(profile)

    data = request.get_json() or {}
    profile = catalog_db.update_profile_meta(uid, data)
    if not profile:
        return jsonify({'error': 'Usuario no encontrado'}), 404
    return jsonify(profile)


@app.route('/api/users/me/portfolio', methods=['POST'])
@token_required
def add_my_portfolio_item():
    """Publicar trabajo en el portafolio del usuario autenticado."""
    uid = request.current_user['user_id']
    data = request.get_json() or {}
    if not data.get('description') and not data.get('image_url'):
        return jsonify({'error': 'description o image_url requerido'}), 400
    profile = catalog_db.add_portfolio_item(uid, data)
    if not profile:
        return jsonify({'error': 'No se pudo guardar'}), 500
    return jsonify(profile), 201


@app.route('/api/users/me/identity/status', methods=['GET'])
@token_required
def my_identity_status():
    """Estado de verificación INE + biometría facial."""
    uid = request.current_user['user_id']
    return jsonify(catalog_db.get_identity_status(uid))


@app.route('/api/users/me/identity/verify', methods=['POST'])
@token_required
def my_identity_verify():
    """
    Verificar INE + selfie (multipart).
    Campos: ine_front, selfie, ine_back (opcional), curp (opcional).
    Motor open source: DeepFace + validación CURP.
    """
    from identity_verification import verify_identity_documents

    uid = request.current_user['user_id']
    ine_front = request.files.get('ine_front')
    selfie = request.files.get('selfie')
    if not ine_front or not selfie:
        return jsonify({'error': 'ine_front y selfie son requeridos'}), 400

    ine_back = request.files.get('ine_back')
    curp = request.form.get('curp', '').strip() or None

    try:
        result = verify_identity_documents(
            ine_front=ine_front.read(),
            selfie=selfie.read(),
            ine_back=ine_back.read() if ine_back else None,
            curp=curp,
        )
    except ValueError as e:
        return jsonify({'error': str(e)}), 400
    except RuntimeError as e:
        return jsonify({'error': str(e), 'hint': 'pip install -r requirements-identity.txt'}), 503

    status = catalog_db.save_identity_verification(uid, result)
    profile = catalog_db.get_profile(uid)
    return jsonify({
        **result,
        'identity_status': status,
        'profile': profile,
    })


@app.route('/api/users/<int:user_id>/profile', methods=['GET'])
def get_user_profile(user_id):
    """Obtener perfil de usuario por ID"""
    profile = catalog_db.get_profile(user_id)
    if profile:
        return jsonify(profile)
    return jsonify({'error': 'Usuario no encontrado'}), 404

@app.route('/api/users/<int:user_id>/profile/availability', methods=['PUT'])
def update_user_availability(user_id):
    """Actualizar disponibilidad del usuario"""
    data = request.get_json() or {}
    profile = catalog_db.update_availability(
        user_id,
        data.get('localAvailable'),
        data.get('remoteAvailable'),
    )
    if not profile:
        return jsonify({'error': 'Usuario no encontrado'}), 404
    return jsonify(profile)

@app.route('/api/users/<int:user_id>/profile/skills', methods=['POST'])
def add_user_skill(user_id):
    """Agregar habilidad al usuario"""
    data = request.get_json() or {}
    if not data.get('name'):
        return jsonify({'error': 'Nombre de habilidad requerido'}), 400
    skill = catalog_db.add_skill(user_id, data['name'])
    if not skill:
        return jsonify({'error': 'Usuario no encontrado'}), 404
    return jsonify(skill), 201


@app.route('/api/users/<int:user_id>/profile/skills/<int:skill_id>', methods=['PUT', 'DELETE'])
def manage_user_skill(user_id, skill_id):
    """Actualizar o eliminar habilidad"""
    if request.method == 'PUT':
        data = request.get_json() or {}
        if not data.get('name'):
            return jsonify({'error': 'name requerido'}), 400
        skill = catalog_db.update_skill(user_id, skill_id, data['name'])
        if not skill:
            return jsonify({'error': 'Habilidad no encontrada'}), 404
        return jsonify(skill)
    if catalog_db.remove_skill(user_id, skill_id):
        return jsonify({'message': 'Habilidad eliminada'})
    return jsonify({'error': 'Habilidad no encontrada'}), 404


@app.route('/api/users/<int:user_id>/profile/materials', methods=['POST'])
def add_user_material(user_id):
    data = request.get_json() or {}
    if not data.get('name'):
        return jsonify({'error': 'Nombre requerido'}), 400
    item = catalog_db.add_material(user_id, data['name'])
    if not item:
        return jsonify({'error': 'Usuario no encontrado'}), 404
    return jsonify(item), 201


@app.route('/api/users/<int:user_id>/profile/materials/<int:material_id>', methods=['PUT', 'DELETE'])
def manage_user_material(user_id, material_id):
    if request.method == 'PUT':
        data = request.get_json() or {}
        if not data.get('name'):
            return jsonify({'error': 'name requerido'}), 400
        item = catalog_db.update_material(user_id, material_id, data['name'])
        if not item:
            return jsonify({'error': 'Material no encontrado'}), 404
        return jsonify(item)
    if catalog_db.remove_material(user_id, material_id):
        return jsonify({'message': 'Material eliminado'})
    return jsonify({'error': 'Material no encontrado'}), 404

@app.route('/api/users/<int:user_id>/profile/share', methods=['POST'])
def share_user_profile(user_id):
    """Compartir perfil de usuario"""
    profile = catalog_db.get_profile(user_id)
    if not profile:
        return jsonify({'error': 'Usuario no encontrado'}), 404

    share_url = f"https://alworki.com/profile/{user_id}"

    return jsonify({
        'message': 'Perfil compartido exitosamente',
        'share_url': share_url,
        'profile': profile
    })

@app.route('/api/categories', methods=['GET'])
def get_categories():
    """Catálogo de oficios y categorías."""
    return jsonify(catalog_db.list_service_categories())

# Endpoints existentes para tarjetas
@app.route('/api/cards', methods=['GET', 'POST'])
def cards_collection():
    """Listar o crear tarjetas de servicio/favor."""
    if request.method == 'GET':
        return jsonify(catalog_db.list_cards())

    data = request.get_json() or {}
    if not data.get('title') or not data.get('description'):
        return jsonify({'error': 'title y description son requeridos'}), 400
    owner_id = None
    auth_header = request.headers.get('Authorization', '')
    if auth_header.startswith('Bearer '):
        payload = jwt_manager.verify_token(auth_header.split(' ', 1)[1])
        if payload:
            owner_id = payload.get('user_id')
    card = catalog_db.create_card(data, owner_user_id=owner_id)
    return jsonify(card), 201


@app.route('/api/cards/<int:card_id>', methods=['GET'])
def get_card(card_id):
    """Obtener una tarjeta específica"""
    card = catalog_db.get_card(card_id)
    if card:
        return jsonify(card)
    return jsonify({'error': 'Tarjeta no encontrada'}), 404

@app.route('/api/cards/search', methods=['GET'])
def search_cards():
    """Buscar profesionales por oficio, requisitos y cercanía."""
    query = request.args.get('q', '').strip()
    lat = request.args.get('lat', type=float)
    lng = request.args.get('lng', type=float)
    radius_km = request.args.get('radius_km', default=15.0, type=float)
    requirements = request.args.get('requirements') or request.args.get('requisitos')
    trade = request.args.get('trade', '').strip()
    require_all = request.args.get('require_all', '0') == '1'
    if not query and not trade and lat is None and not requirements:
        return jsonify(catalog_db.list_cards())
    return jsonify(
        catalog_db.search_cards(
            query,
            lat=lat,
            lng=lng,
            radius_km=radius_km,
            requirements=requirements,
            trade=trade,
            require_all=require_all,
        )
    )


@app.route('/api/jobs/match', methods=['GET'])
def match_jobs_api():
    """Carpintero más cercano que cumpla los requisitos del servicio."""
    query = request.args.get('q', '').strip()
    trade = request.args.get('trade', '').strip()
    requirements = request.args.get('requirements') or request.args.get('requisitos')
    lat = request.args.get('lat', type=float)
    lng = request.args.get('lng', type=float)
    radius_km = request.args.get('radius_km', default=15.0, type=float)
    require_all = request.args.get('require_all', '0') == '1'
    return jsonify(
        catalog_db.match_jobs(
            query=query,
            trade=trade,
            requirements=requirements,
            lat=lat,
            lng=lng,
            radius_km=radius_km,
            require_all=require_all,
        )
    )

# Endpoints para el feed de Instagram
@app.route('/api/feed', methods=['GET', 'POST'])
def feed_collection():
    """Feed social: listar o publicar."""
    if request.method == 'GET':
        auth_header = request.headers.get('Authorization', '')
        personalized = request.args.get('personalized', '1') != '0'
        if personalized and auth_header.startswith('Bearer '):
            payload = jwt_manager.verify_token(auth_header.split(' ', 1)[1])
            if payload and payload.get('user_id'):
                uid = int(payload['user_id'])
                proximity = request.args.get('proximity') == '1'
                lat = request.args.get('lat', type=float)
                lng = request.args.get('lng', type=float)
                radius = request.args.get('radius_km', default=15.0, type=float)
                return jsonify(
                    catalog_db.list_feed_personalized(
                        uid,
                        proximity_enabled=proximity,
                        center_lat=lat,
                        center_lng=lng,
                        radius_km=radius,
                    )
                )
        return jsonify(catalog_db.list_feed())

    auth_header = request.headers.get('Authorization', '')
    if not auth_header.startswith('Bearer '):
        return jsonify({'error': 'Token de acceso requerido'}), 401
    payload = jwt_manager.verify_token(auth_header.split(' ', 1)[1])
    if not payload:
        return jsonify({'error': 'Token inválido o expirado'}), 401
    data = request.get_json() or {}
    if not data.get('description'):
        return jsonify({'error': 'description es requerido'}), 400
    data['user'] = {
        'id': payload.get('user_id'),
        'name': payload.get('name', 'Usuario'),
        'avatar': 'users/user.jpg',
        'verified': False,
        'following': False,
    }
    post = catalog_db.create_feed_post(data)
    return jsonify(post), 201


@app.route('/api/suggestions/profiles', methods=['GET'])
@token_required
def profile_suggestions_api():
    """Perfiles sugeridos (ranking estilo Instagram)."""
    uid = request.current_user['user_id']
    limit = request.args.get('limit', default=12, type=int)
    return jsonify(catalog_db.list_profile_suggestions(uid, limit=limit))


@app.route('/api/feed/<int:post_id>/like', methods=['POST'])
@token_required
def like_feed_post(post_id):
    post = catalog_db.toggle_feed_like(post_id)
    if not post:
        return jsonify({'error': 'Post no encontrado'}), 404
    return jsonify(post)


@app.route('/api/feed/<int:post_id>/save', methods=['POST'])
@token_required
def save_feed_post(post_id):
    post = catalog_db.toggle_feed_save(post_id)
    if not post:
        return jsonify({'error': 'Post no encontrado'}), 404
    return jsonify(post)

@app.route('/api/feed/<int:post_id>', methods=['GET'])
def get_feed_post(post_id):
    """Obtener un post específico del feed"""
    post = catalog_db.get_feed_post(post_id)
    if post:
        return jsonify(post)
    return jsonify({'error': 'Post no encontrado'}), 404

@app.route('/api/feed/search', methods=['GET'])
def search_feed():
    """Buscar posts en el feed persistido."""
    query = request.args.get('q', '')
    return jsonify(catalog_db.search_feed(query))

@app.route('/api/feed/card/<int:card_id>', methods=['GET'])
def get_feed_by_card(card_id):
    """Obtener posts relacionados con una tarjeta específica"""
    card_posts = [post for post in catalog_db.list_feed() if post.get('card_id') == card_id]
    return jsonify(card_posts)

# Endpoints para historias
@app.route('/api/stories', methods=['GET', 'POST'])
def stories_collection():
    """Historias: listar o publicar (publicar requiere JWT)."""
    if request.method == 'GET':
        return jsonify(catalog_db.list_stories())
    auth_header = request.headers.get('Authorization', '')
    if not auth_header.startswith('Bearer '):
        return jsonify({'error': 'Token de acceso requerido'}), 401
    payload = jwt_manager.verify_token(auth_header.split(' ', 1)[1])
    if not payload:
        return jsonify({'error': 'Token inválido o expirado'}), 401
    data = request.get_json() or {}
    try:
        story = catalog_db.create_story(int(payload['user_id']), data)
    except ValueError as exc:
        return jsonify({'error': str(exc)}), 400
    return jsonify(story), 201

@app.route('/api/stories/<int:story_id>', methods=['GET'])
def get_story(story_id):
    """Obtener una historia específica"""
    story = catalog_db.get_story(story_id)
    if story:
        return jsonify(story)
    return jsonify({'error': 'Historia no encontrada'}), 404

@app.route('/api/stories/<int:story_id>/view', methods=['POST'])
def mark_story_viewed(story_id):
    """Marcar historia como vista"""
    if catalog_db.mark_story_viewed(story_id):
        return jsonify({'message': 'Historia marcada como vista'})
    return jsonify({'error': 'Historia no encontrada'}), 404


@app.route('/api/exchange', methods=['GET', 'POST'])
@token_required
def exchange_collection():
    uid = request.current_user['user_id']
    if request.method == 'GET':
        return jsonify(catalog_db.list_exchanges(uid))
    data = request.get_json() or {}
    if not data.get('title'):
        return jsonify({'error': 'title es requerido'}), 400
    try:
        item = catalog_db.create_exchange(uid, data)
    except ValueError as exc:
        return jsonify({'error': str(exc)}), 400
    return jsonify(item), 201


@app.route('/api/exchange/<int:exchange_id>', methods=['PATCH'])
@token_required
def exchange_update(exchange_id):
    uid = request.current_user['user_id']
    data = request.get_json() or {}
    status = data.get('status')
    if not status:
        return jsonify({'error': 'status es requerido'}), 400
    try:
        item = catalog_db.update_exchange_status(exchange_id, int(uid), str(status))
    except KeyError:
        return jsonify({'error': 'Intercambio no encontrado'}), 404
    except PermissionError as exc:
        return jsonify({'error': str(exc)}), 403
    except ValueError as exc:
        return jsonify({'error': str(exc)}), 400
    return jsonify(item)


@app.route('/api/projects', methods=['GET'])
@token_required
def list_projects_api():
    uid = request.current_user['user_id']
    return jsonify(catalog_db.list_projects(uid))


@app.route('/api/projects', methods=['POST'])
@token_required
def create_project_api():
    uid = request.current_user['user_id']
    data = request.get_json() or {}
    try:
        project = catalog_db.create_project(
            uid,
            data,
            publish_to_feed=bool(data.get('publishToFeed') or data.get('publish_to_feed')),
        )
    except ValueError as exc:
        return jsonify({'error': str(exc)}), 400
    return jsonify(project), 201


@app.route('/api/projects/<int:project_id>', methods=['GET'])
@token_required
def get_project_api(project_id):
    uid = request.current_user['user_id']
    try:
        project = catalog_db.get_project(project_id, uid)
    except PermissionError:
        return jsonify({'error': 'No tienes acceso a este proyecto'}), 403
    if not project:
        return jsonify({'error': 'Proyecto no encontrado'}), 404
    return jsonify(project)


@app.route('/api/projects/<int:project_id>', methods=['PATCH'])
@token_required
def update_project_api(project_id):
    uid = request.current_user['user_id']
    data = request.get_json() or {}
    status = data.get('deliveryStatus') or data.get('delivery_status') or data.get('status')
    if not status:
        return jsonify({'error': 'status es requerido'}), 400
    try:
        project = catalog_db.update_project_delivery(project_id, int(uid), str(status))
    except KeyError:
        return jsonify({'error': 'Proyecto no encontrado'}), 404
    except PermissionError as exc:
        return jsonify({'error': str(exc)}), 403
    except ValueError as exc:
        return jsonify({'error': str(exc)}), 400
    return jsonify(project)


@app.route('/api/projects/<int:project_id>/delivery', methods=['POST'])
@token_required
def submit_project_delivery_api(project_id):
    uid = request.current_user['user_id']
    data = request.get_json() or {}
    try:
        project = catalog_db.submit_project_delivery(project_id, int(uid), data)
    except KeyError:
        return jsonify({'error': 'Proyecto no encontrado'}), 404
    except PermissionError as exc:
        return jsonify({'error': str(exc)}), 403
    except ValueError as exc:
        return jsonify({'error': str(exc)}), 400
    return jsonify(project)


@app.route('/api/projects/<int:project_id>/follow', methods=['POST', 'DELETE'])
@token_required
def follow_project_api(project_id):
    uid = request.current_user['user_id']
    try:
        result = catalog_db.toggle_follow_project(uid, project_id)
    except KeyError:
        return jsonify({'error': 'Proyecto no encontrado'}), 404
    if request.method == 'DELETE' and result.get('followed'):
        result = catalog_db.toggle_follow_project(uid, project_id)
    if request.method == 'POST' and not result.get('followed'):
        result = catalog_db.toggle_follow_project(uid, project_id)
    return jsonify(result)


@app.route('/api/users/<int:user_id>/follow', methods=['POST', 'DELETE'])
@token_required
def follow_user_api(user_id):
    uid = request.current_user['user_id']
    try:
        result = catalog_db.toggle_follow_user(uid, user_id)
    except ValueError as exc:
        return jsonify({'error': str(exc)}), 400
    if request.method == 'DELETE' and result.get('following'):
        result = catalog_db.toggle_follow_user(uid, user_id)
    if request.method == 'POST' and not result.get('following'):
        result = catalog_db.toggle_follow_user(uid, user_id)
    return jsonify(result)


@app.route('/api/users/me/following', methods=['GET'])
@token_required
def my_following_api():
    uid = request.current_user['user_id']
    return jsonify({'ids': catalog_db.list_following_ids(uid)})


@app.route('/api/quotes', methods=['POST'])
def create_quote_api():
    """Crear cotización de servicio (flujo perfil proveedor)."""
    data = request.get_json() or {}
    required = ('provider_id', 'quote_date', 'time_slot')
    if not all(data.get(k) for k in required):
        return jsonify({'error': 'provider_id, quote_date y time_slot son requeridos'}), 400
    auth_header = request.headers.get('Authorization', '')
    if auth_header.startswith('Bearer '):
        payload = jwt_manager.verify_token(auth_header.split(' ', 1)[1])
        if payload:
            data['client_id'] = payload.get('user_id')
    quote = catalog_db.create_quote(data)
    if not quote:
        return jsonify({'error': 'Saldo insuficiente o pago rechazado'}), 402
    return jsonify(quote), 201


@app.route('/api/users/me/wallet', methods=['GET'])
@token_required
def get_wallet_api():
    uid = request.current_user['user_id']
    return jsonify(catalog_db.get_wallet(uid))


@app.route('/api/wallet/purchase-blue', methods=['POST'])
@token_required
def purchase_blue_coins_api():
    uid = request.current_user['user_id']
    data = request.get_json() or {}
    amount_mxn = data.get('amount_mxn')
    if amount_mxn is not None:
        result = catalog_db.purchase_blue_coins(uid, amount_mxn=int(amount_mxn))
    else:
        result = catalog_db.purchase_blue_coins(uid, amount=int(data.get('amount', 10)))
    return jsonify(result)


@app.route('/api/orders', methods=['GET'])
@token_required
def list_orders_api():
    uid = request.current_user['user_id']
    return jsonify(catalog_db.list_orders(uid))


@app.route('/api/orders/<tracking>', methods=['GET'])
@token_required
def get_order_api(tracking):
    uid = request.current_user['user_id']
    order = catalog_db.get_order(tracking, uid)
    if not order:
        return jsonify({'error': 'Orden no encontrada'}), 404
    if (
        not order.get('isClient')
        and not order.get('isProvider')
        and tracking != '1020405060'
    ):
        return jsonify({'error': 'Sin acceso a esta orden'}), 403
    return jsonify(order)


@app.route('/api/orders/<tracking>/delivery', methods=['POST'])
@token_required
def submit_delivery_api(tracking):
    uid = request.current_user['user_id']
    data = request.get_json() or {}
    if not data.get('message'):
        return jsonify({'error': 'message es requerido'}), 400
    order = catalog_db.submit_order_delivery(tracking, uid, data)
    if not order:
        return jsonify({'error': 'No autorizado o orden no encontrada'}), 403
    return jsonify(order)


@app.route('/api/reports', methods=['POST'])
def create_report_api():
    """Reportar problema con un servicio."""
    data = request.get_json() or {}
    if not data.get('tracking_number') or not data.get('action'):
        return jsonify({'error': 'tracking_number y action son requeridos'}), 400
    auth_header = request.headers.get('Authorization', '')
    if auth_header.startswith('Bearer '):
        payload = jwt_manager.verify_token(auth_header.split(' ', 1)[1])
        if payload:
            data['user_id'] = payload.get('user_id')
    report = catalog_db.create_report(data)
    return jsonify(report), 201


@app.route('/api/users/<int:user_id>/reviews', methods=['POST'])
def add_user_review(user_id):
    """Agregar reseña a un proveedor."""
    data = request.get_json() or {}
    if not data.get('text'):
        return jsonify({'error': 'text es requerido'}), 400
    auth_header = request.headers.get('Authorization', '')
    if auth_header.startswith('Bearer '):
        payload = jwt_manager.verify_token(auth_header.split(' ', 1)[1])
        if payload:
            data['user'] = {
                'id': payload.get('user_id'),
                'name': payload.get('name', 'Usuario'),
                'avatar': 'users/user.jpg',
                'verified': False,
                'following': False,
            }
    review = catalog_db.add_profile_review(user_id, data)
    if not review:
        return jsonify({'error': 'Usuario no encontrado'}), 404
    return jsonify(review), 201


@app.route('/api/notifications', methods=['GET'])
@token_required
def list_notifications_api():
    uid = request.current_user['user_id']
    return jsonify(catalog_db.list_notifications(uid))


@app.route('/api/notifications/<int:notif_id>', methods=['DELETE'])
@token_required
def delete_notification_api(notif_id):
    uid = request.current_user['user_id']
    if catalog_db.delete_notification(uid, notif_id):
        return jsonify({'message': 'Eliminada'})
    return jsonify({'error': 'No encontrada'}), 404


@app.route('/api/messages', methods=['GET'])
@token_required
def list_messages_api():
    uid = request.current_user['user_id']
    return jsonify(catalog_db.list_message_threads(uid))


@app.route('/api/messages/unread-count', methods=['GET'])
@token_required
def messages_unread_count_api():
    uid = request.current_user['user_id']
    return jsonify({'count': catalog_db.unread_message_count(uid)})


@app.route('/api/messages/<int:thread_id>', methods=['GET'])
@token_required
def get_message_thread_api(thread_id):
    thread = catalog_db.get_message_thread(thread_id)
    if not thread:
        return jsonify({'error': 'Conversación no encontrada'}), 404
    messages = catalog_db.get_thread_messages(thread_id)
    return jsonify({'thread': thread, 'messages': messages})


@app.route('/api/messages/<int:thread_id>', methods=['POST'])
@token_required
def send_message_api(thread_id):
    data = request.get_json() or {}
    body = (data.get('body') or '').strip()
    msg_type = (data.get('type') or 'text').strip()
    meta = data.get('meta')
    if msg_type == 'text' and not body:
        return jsonify({'error': 'body es requerido'}), 400
    if msg_type == 'quote' and not body:
        return jsonify({'error': 'body (monto) es requerido para cotización'}), 400
    msg = catalog_db.add_chat_message(thread_id, 'me', msg_type, body, meta)
    return jsonify(msg), 201


@app.route('/api/messages/with/<int:peer_id>', methods=['POST'])
@token_required
def get_or_create_thread_api(peer_id):
    uid = request.current_user['user_id']
    data = request.get_json() or {}
    thread = catalog_db.get_or_create_message_thread(
        uid,
        peer_id,
        peer_name=(data.get('name') or '').strip(),
        peer_avatar=(data.get('avatar') or 'users/user.jpg').strip(),
        peer_profession=(data.get('profession') or '').strip(),
    )
    return jsonify(thread)


@app.route('/api/contacts/requests', methods=['POST'])
@token_required
def create_contact_request_api():
    uid = request.current_user['user_id']
    data = request.get_json() or {}
    peer_id = data.get('peer_id')
    if peer_id is None:
        return jsonify({'error': 'peer_id es requerido'}), 400
    try:
        peer_id = int(peer_id)
    except (TypeError, ValueError):
        return jsonify({'error': 'peer_id inválido'}), 400
    subtitle = (data.get('subtitle') or '').strip()
    result = catalog_db.create_contact_request(uid, peer_id, subtitle)
    if not result:
        return jsonify({'error': 'No se pudo enviar la solicitud'}), 400
    return jsonify(result), 201


@app.route('/api/contacts', methods=['GET'])
@token_required
def list_contacts_api():
    uid = request.current_user['user_id']
    return jsonify(catalog_db.list_contacts(uid))


@app.route('/api/contacts/requests', methods=['GET'])
@token_required
def list_contact_requests_api():
    uid = request.current_user['user_id']
    return jsonify(catalog_db.list_contact_requests(uid))


@app.route('/api/contacts/requests/<int:request_id>/accept', methods=['POST'])
@token_required
def accept_contact_request_api(request_id):
    uid = request.current_user['user_id']
    result = catalog_db.respond_contact_request(request_id, uid, True)
    if not result:
        return jsonify({'error': 'Solicitud no encontrada'}), 404
    return jsonify(result)


@app.route('/api/contacts/requests/<int:request_id>/reject', methods=['POST'])
@token_required
def reject_contact_request_api(request_id):
    uid = request.current_user['user_id']
    result = catalog_db.respond_contact_request(request_id, uid, False)
    if not result:
        return jsonify({'error': 'Solicitud no encontrada'}), 404
    return jsonify(result)


@app.route('/api/contacts/blocked', methods=['GET'])
@token_required
def list_blocked_contacts_api():
    uid = request.current_user['user_id']
    return jsonify(catalog_db.list_blocked_contacts(uid))


@app.route('/api/contacts/blocked/<int:block_id>', methods=['DELETE'])
@token_required
def unblock_contact_api(block_id):
    uid = request.current_user['user_id']
    if catalog_db.unblock_contact(block_id, uid):
        return jsonify({'message': 'Contacto desbloqueado'})
    return jsonify({'error': 'No encontrado'}), 404


@app.route('/api/stories/card/<int:card_id>', methods=['GET'])
def get_stories_by_card(card_id):
    """Obtener historias relacionadas con una tarjeta específica"""
    card_stories = [
        story for story in INSTAGRAM_STORIES_DATA
        if story['card_id'] == card_id
    ]
    return jsonify(card_stories)

# Endpoints de autenticación existentes
@app.route('/api/auth/register', methods=['POST'])
def register():
    """Registrar usuario (Supabase Auth + Postgres o SQLite local)."""
    data = request.get_json()

    if not data or not data.get('email') or not data.get('password'):
        msg = 'Email y contraseña son requeridos'
        return jsonify({'error': msg, 'message': msg}), 400

    email_norm = (data.get('email') or '').strip().lower()
    password = data.get('password') or ''
    firstname = (data.get('firstname') or '').strip()
    lastname = (data.get('lastname') or '').strip()

    if len(password) < 6:
        msg = 'La contraseña debe tener al menos 6 caracteres'
        return jsonify({'error': msg, 'message': msg}), 400

    if not email_norm or '@' not in email_norm:
        msg = 'Correo electrónico no válido'
        return jsonify({'error': msg, 'message': msg}), 400

    if supabase_service.is_supabase_auth_enabled() or is_postgres():
        try:
            user = supabase_service.register_user(email_norm, password, firstname, lastname)
        except ValueError as exc:
            return jsonify({'error': str(exc), 'message': str(exc)}), 400
        except Exception:
            return jsonify({'error': 'Error al registrar usuario'}), 500
        return jsonify({
            'message': 'Usuario registrado exitosamente',
            'user': user,
        }), 201

    pwd_hash = generate_password_hash(password)
    conn = get_auth_connection_legacy()
    try:
        cur = conn.cursor()
        cur.execute(
            """
            INSERT INTO users (email, password_hash, firstname, lastname)
            VALUES (?, ?, ?, ?)
            """,
            (email_norm, pwd_hash, firstname, lastname),
        )
        conn.commit()
        user_id = cur.lastrowid
    except sqlite3.IntegrityError:
        conn.close()
        msg = 'El correo ya está registrado'
        return jsonify({'error': msg, 'message': msg}), 400
    conn.close()

    name = f"{firstname} {lastname}".strip() or email_norm.split('@')[0]
    catalog_db.ensure_profile(user_id, name, email_norm)

    return jsonify({
        'message': 'Usuario registrado exitosamente',
        'user': {
            'id': user_id,
            'email': email_norm,
            'firstname': firstname,
            'lastname': lastname,
        },
    }), 201


@app.route('/api/auth/login', methods=['POST'])
def login():
    """Iniciar sesión (Supabase o SQLite local)."""
    data = request.get_json()

    if not data or not data.get('email') or not data.get('password'):
        return jsonify({'error': 'Email y contraseña son requeridos'}), 401

    email_norm = (data.get('email') or '').strip().lower()
    password = data.get('password') or ''

    if supabase_service.is_supabase_auth_enabled() or is_postgres():
        try:
            user = supabase_service.login_user(email_norm, password)
        except ValueError:
            return jsonify({'error': 'Correo o contraseña incorrectos'}), 401
        except Exception:
            return jsonify({'error': 'Error en el login'}), 500

        user_data = {
            'email': user['email'],
            'name': user.get('name') or email_norm.split('@')[0],
            'role': user.get('role') or 'user',
        }
        try:
            tokens = jwt_manager.generate_tokens(user['id'], user_data)
            if not tokens:
                return jsonify({'error': 'Error generando tokens'}), 500
            payload = {
                'message': 'Login exitoso',
                'user': {
                    'id': user['id'],
                    'email': user['email'],
                    'firstname': user.get('firstname') or '',
                    'lastname': user.get('lastname') or '',
                    'name': user_data['name'],
                    'role': user_data['role'],
                },
                **tokens,
            }
            if user.get('supabase_access_token'):
                payload['supabase_access_token'] = user['supabase_access_token']
                payload['supabase_refresh_token'] = user.get('supabase_refresh_token')
            return jsonify(payload), 200
        except Exception:
            return jsonify({'error': 'Error en el login'}), 500

    conn = get_auth_connection_legacy()
    row = conn.execute(
        """
        SELECT id, email, password_hash, firstname, lastname, role
        FROM users WHERE email = ?
        """,
        (email_norm,),
    ).fetchone()
    conn.close()

    if not row or not check_password_hash(row['password_hash'], password):
        return jsonify({'error': 'Correo o contraseña incorrectos'}), 401

    name = f"{row['firstname'] or ''} {row['lastname'] or ''}".strip()
    if not name:
        name = (row['email'] or '').split('@')[0] or 'Usuario'

    user_data = {
        'email': row['email'],
        'name': name,
        'role': row['role'] or 'user',
    }

    try:
        tokens = jwt_manager.generate_tokens(row['id'], user_data)
        if not tokens:
            return jsonify({'error': 'Error generando tokens'}), 500

        return jsonify({
            'message': 'Login exitoso',
            'user': {
                'id': row['id'],
                'email': row['email'],
                'firstname': row['firstname'] or '',
                'lastname': row['lastname'] or '',
                'name': name,
                'role': user_data['role'],
            },
            **tokens,
        }), 200
    except Exception:
        return jsonify({'error': 'Error en el login'}), 500

@app.route('/api/auth/verify-token', methods=['GET'])
@token_required
def verify_token():
    """Verificar token JWT"""
    return jsonify({
        'valid': True,
        'user': request.current_user
    }), 200


@app.route('/api/auth/verify-session', methods=['GET'])
@token_required
def verify_session_alias():
    """Alias antiguo del front → misma respuesta que verify-token."""
    return jsonify({
        'valid': True,
        'user': request.current_user
    }), 200

@app.route('/api/auth/refresh-token', methods=['POST'])
def refresh_token():
    """Renovar access token"""
    data = request.get_json()
    
    if not data or 'refresh_token' not in data:
        return jsonify({'error': 'Refresh token requerido'}), 400
    
    try:
        new_tokens = jwt_manager.refresh_access_token(data['refresh_token'])
        
        if not new_tokens:
            return jsonify({'error': 'Refresh token inválido o expirado'}), 401
        
        return jsonify({
            'message': 'Token renovado exitosamente',
            **new_tokens
        }), 200
        
    except Exception as e:
        return jsonify({'error': 'Error renovando token'}), 500

@app.route('/api/auth/logout', methods=['POST'])
@token_required
def logout():
    """Cerrar sesión"""
    # Con JWT, el logout es principalmente del lado del cliente
    return jsonify({'message': 'Logout exitoso'}), 200

@app.route('/health', methods=['GET'])
def health_check():
    """Endpoint de salud del servicio principal"""
    return jsonify({
        'service': 'api-gateway',
        'status': 'healthy',
        'version': '1.0.0',
        'timestamp': datetime.utcnow().isoformat()
    })

@app.route('/')
def index():
    """Página principal con documentación de endpoints"""
    return jsonify({
        'message': 'API Gateway de Alworki',
        'version': '1.0.0',
        'endpoints': {
            'auth': {
                'register': 'POST /api/auth/register',
                'login': 'POST /api/auth/login'
            },
            'cards': {
                'all': 'GET /api/cards',
                'single': 'GET /api/cards/<id>',
                'search': 'GET /api/cards/search?q=<query>&requirements=&lat=&lng=',
                'match': 'GET /api/jobs/match?q=carpintero&requirements=muebles,madera'
            },
            'feed': {
                'all': 'GET /api/feed',
                'single': 'GET /api/feed/<id>',
                'search': 'GET /api/feed/search?q=<query>',
                'by_card': 'GET /api/feed/card/<card_id>'
            },
            'stories': {
                'all': 'GET /api/stories',
                'single': 'GET /api/stories/<id>',
                'view': 'POST /api/stories/<id>/view',
                'by_card': 'GET /api/stories/card/<card_id>'
            },
            'user_profiles': {
                'profile': 'GET /api/users/<id>/profile',
                'availability': 'PUT /api/users/<id>/profile/availability',
                'add_skill': 'POST /api/users/<id>/profile/skills',
                'remove_skill': 'DELETE /api/users/<id>/profile/skills/<skill_id>',
                'share': 'POST /api/users/<id>/profile/share'
            }
        }
    })

if __name__ == '__main__':
    debug = os.environ.get('FLASK_DEBUG', '0') == '1'
    host = os.environ.get('ALWORKI_BIND', '0.0.0.0')
    port = int(os.environ.get('ALWORKI_API_PORT', '5002'))
    app.run(debug=debug, host=host, port=port)
