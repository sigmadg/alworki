"""
API Gateway - Coordinador de microservicios
"""

from flask import Flask, request, jsonify, Response
from flask_cors import CORS
import requests
import sys
import os
from datetime import datetime

# Agregar el directorio raíz al path para importar módulos
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from config.config import config

def create_api_gateway():
    """Crear y configurar el API Gateway"""
    
    app = Flask(__name__)
    
    # Configuración del servicio
    service_config = config.get_service_config('api')
    
    # Configuración de CORS
    CORS(app, resources={
        r"/*": {
            "origins": service_config.cors_origins,
            "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
            "allow_headers": ["Content-Type", "Authorization"]
        }
    })
    
    # Configuración de servicios
    SERVICES = {
        'auth': f"http://localhost:{config.get_service_config('auth').port}",
        'cards': f"http://localhost:{config.get_service_config('cards').port}",
        'profile': f"http://localhost:{config.get_service_config('profile').port}",
        'chatbot': f"http://localhost:{config.get_service_config('chatbot').port}"
    }
    
    def forward_request(service_name: str, path: str = '', method: str = None, data: dict = None, headers: dict = None):
        """Reenviar petición a un servicio específico"""
        if service_name not in SERVICES:
            return jsonify({'error': f'Servicio {service_name} no encontrado'}), 404
        
        service_url = SERVICES[service_name]
        target_url = f"{service_url}/{path.lstrip('/')}"
        
        # Headers por defecto
        default_headers = {
            'Content-Type': 'application/json'
        }
        if headers:
            default_headers.update(headers)
        
        try:
            if method == 'GET':
                response = requests.get(target_url, headers=default_headers)
            elif method == 'POST':
                response = requests.post(target_url, json=data, headers=default_headers)
            elif method == 'PUT':
                response = requests.put(target_url, json=data, headers=default_headers)
            elif method == 'DELETE':
                response = requests.delete(target_url, headers=default_headers)
            else:
                return jsonify({'error': 'Método HTTP no soportado'}), 405
            
            return response.json(), response.status_code
            
        except requests.exceptions.ConnectionError:
            return jsonify({'error': f'Servicio {service_name} no disponible'}), 503
        except Exception as e:
            return jsonify({'error': f'Error al comunicarse con {service_name}: {str(e)}'}), 500
    
    # Rutas de autenticación
    @app.route('/auth/<path:subpath>', methods=['GET', 'POST', 'PUT', 'DELETE'])
    def auth_proxy(subpath):
        """Proxy para el servicio de autenticación"""
        return forward_request(
            'auth', 
            subpath, 
            method=request.method,
            data=request.get_json() if request.is_json else None,
            headers=dict(request.headers)
        )
    
    # Rutas de tarjetas
    @app.route('/cards/<path:subpath>', methods=['GET', 'POST', 'PUT', 'DELETE'])
    def cards_proxy(subpath):
        """Proxy para el servicio de tarjetas"""
        return forward_request(
            'cards', 
            subpath, 
            method=request.method,
            data=request.get_json() if request.is_json else None,
            headers=dict(request.headers)
        )
    
    # Rutas de perfil
    @app.route('/profile/<path:subpath>', methods=['GET', 'POST', 'PUT', 'DELETE'])
    def profile_proxy(subpath):
        """Proxy para el servicio de perfil"""
        return forward_request(
            'profile', 
            subpath, 
            method=request.method,
            data=request.get_json() if request.is_json else None,
            headers=dict(request.headers)
        )
    
    # Rutas de chatbot
    @app.route('/chatbot/<path:subpath>', methods=['GET', 'POST', 'PUT', 'DELETE'])
    def chatbot_proxy(subpath):
        """Proxy para el servicio de chatbot"""
        return forward_request(
            'chatbot', 
            subpath, 
            method=request.method,
            data=request.get_json() if request.is_json else None,
            headers=dict(request.headers)
        )
    
    # Rutas directas para compatibilidad
    @app.route('/register', methods=['POST'])
    def register():
        """Registro de usuarios"""
        return forward_request(
            'auth', 
            'register', 
            method='POST',
            data=request.get_json()
        )
    
    @app.route('/login', methods=['POST'])
    def login():
        """Login de usuarios"""
        return forward_request(
            'auth', 
            'login', 
            method='POST',
            data=request.get_json()
        )
    
    @app.route('/api/cards', methods=['GET'])
    def get_cards():
        """Obtener tarjetas"""
        return forward_request(
            'cards', 
            'cards', 
            method='GET'
        )
    
    @app.route('/api/cards/search', methods=['GET'])
    def search_cards():
        """Buscar tarjetas"""
        return forward_request(
            'cards', 
            f'cards/search?{request.query_string.decode()}', 
            method='GET'
        )
    
    # Rutas de perfil para compatibilidad
    @app.route('/api/profile', methods=['GET'])
    def get_profile():
        """Obtener perfil del usuario actual"""
        return forward_request(
            'profile', 
            'profile', 
            method='GET',
            headers=dict(request.headers)
        )
    
    @app.route('/api/profile', methods=['PUT'])
    def update_profile():
        """Actualizar perfil del usuario"""
        return forward_request(
            'profile', 
            'profile', 
            method='PUT',
            data=request.get_json(),
            headers=dict(request.headers)
        )
    
    @app.route('/api/profile/avatar', methods=['POST'])
    def upload_avatar():
        """Subir avatar del usuario"""
        return forward_request(
            'profile', 
            'profile/avatar', 
            method='POST',
            headers=dict(request.headers)
        )
    
    @app.route('/api/profile/search', methods=['GET'])
    def search_profiles():
        """Buscar perfiles de usuarios"""
        return forward_request(
            'profile', 
            f'profile/search?{request.query_string.decode()}', 
            method='GET'
        )
    
    # Rutas de chatbot para compatibilidad
    @app.route('/api/chatbot/chat', methods=['POST'])
    def chatbot_chat():
        """Chat con el bot inteligente"""
        return forward_request(
            'chatbot', 
            'chat', 
            method='POST',
            data=request.get_json(),
            headers=dict(request.headers)
        )
    
    @app.route('/api/chatbot/chat/stream', methods=['POST'])
    def chatbot_chat_stream():
        """Chat con streaming"""
        return forward_request(
            'chatbot', 
            'chat/stream', 
            method='POST',
            data=request.get_json(),
            headers=dict(request.headers)
        )
    
    @app.route('/api/chatbot/feedback', methods=['POST'])
    def chatbot_feedback():
        """Enviar feedback del chat"""
        return forward_request(
            'chatbot', 
            'chat/feedback', 
            method='POST',
            data=request.get_json(),
            headers=dict(request.headers)
        )
    
    @app.route('/api/chatbot/knowledge', methods=['GET'])
    def get_chatbot_knowledge():
        """Obtener base de conocimiento del chatbot"""
        return forward_request(
            'chatbot', 
            'chat/knowledge', 
            method='GET'
        )
    
    @app.route('/health', methods=['GET'])
    def health_check():
        """Verificar salud de todos los servicios"""
        services_status = {}
        
        for service_name, service_url in SERVICES.items():
            try:
                response = requests.get(f"{service_url}/health", timeout=5)
                services_status[service_name] = {
                    'status': 'healthy' if response.status_code == 200 else 'unhealthy',
                    'response_time': response.elapsed.total_seconds()
                }
            except Exception as e:
                services_status[service_name] = {
                    'status': 'unavailable',
                    'error': str(e)
                }
        
        return jsonify({
            'gateway': 'healthy',
            'services': services_status,
            'timestamp': datetime.utcnow().isoformat()
        })
    
    @app.route('/health/<service_name>', methods=['GET'])
    def service_health_check(service_name):
        """Verificar salud de un servicio específico"""
        if service_name not in SERVICES:
            return jsonify({'error': 'Servicio no encontrado'}), 404
        
        try:
            response = requests.get(f"{SERVICES[service_name]}/health", timeout=5)
            return response.json(), response.status_code
        except Exception as e:
            return jsonify({'error': f'Error verificando servicio: {str(e)}'}), 500
    
    @app.route('/api', methods=['GET'])
    def api_info():
        """Información de la API"""
        return jsonify({
            'name': 'AlworkiAuto API Gateway',
            'version': '1.0.0',
            'services': {
                'auth': {
                    'register': 'POST /register',
                    'login': 'POST /login'
                },
                'cards': {
                    'get_cards': 'GET /api/cards',
                    'search': 'GET /api/cards/search?q=<query>'
                },
                'profile': {
                    'get_profile': 'GET /api/profile',
                    'update_profile': 'PUT /api/profile',
                    'upload_avatar': 'POST /api/profile/avatar',
                    'search_profiles': 'GET /api/profile/search?q=<query>'
                },
                'chatbot': {
                    'chat': 'POST /api/chatbot/chat',
                    'chat_stream': 'POST /api/chatbot/chat/stream',
                    'feedback': 'POST /api/chatbot/feedback',
                    'knowledge': 'GET /api/chatbot/knowledge'
                },
                'health': {
                    'gateway': 'GET /health',
                    'service': 'GET /health/<service_name>'
                }
            }
        })
    
    return app

if __name__ == '__main__':
    app = create_api_gateway()
    app.run(host='0.0.0.0', port=5002, debug=True)
