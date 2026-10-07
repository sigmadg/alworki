"""
Microservicio de Autenticación
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_mail import Mail, Message
import sys
import os

# Agregar el directorio raíz al path para importar módulos
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from config.config import config
from utils.database import db_manager, User, Session
from auth.jwt_manager import jwt_manager, token_required

def create_auth_service():
    """Crear y configurar el servicio de autenticación"""
    
    app = Flask(__name__)
    
    # Configuración del servicio
    service_config = config.get_service_config('auth')
    
    # Configuración de la aplicación
    app.config['SQLALCHEMY_DATABASE_URI'] = config.database.uri
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = config.database.track_modifications
    app.config['SECRET_KEY'] = config.security.secret_key
    
    # Configuración de CORS
    CORS(app, resources={
        r"/*": {
            "origins": service_config.cors_origins,
            "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
            "allow_headers": ["Content-Type", "Authorization"]
        }
    })
    
    # Configuración de Flask-Mail
    app.config['MAIL_SERVER'] = config.mail.server
    app.config['MAIL_PORT'] = config.mail.port
    app.config['MAIL_USE_TLS'] = config.mail.use_tls
    app.config['MAIL_USERNAME'] = config.mail.username
    app.config['MAIL_PASSWORD'] = config.mail.password
    mail = Mail(app)
    
    # Inicializar base de datos
    db_manager.init_app(app)
    
    # Inicializar JWT Manager
    jwt_manager.init_app(app)
    
    @app.route('/register', methods=['POST'])
    def register():
        """Endpoint para registro de usuarios"""
        data = request.get_json()
        
        # Validar que todos los campos estén presentes
        if not data or not all(key in data for key in ['firstname', 'lastname', 'email', 'password']):
            return jsonify({'error': 'Faltan campos obligatorios'}), 400
        
        # Verificar si el correo electrónico ya está registrado
        existing_user = db_manager.get_user_by_email(data['email'])
        if existing_user:
            return jsonify({'error': 'El correo electrónico ya está registrado'}), 400
        
        try:
            # Crear un nuevo usuario
            new_user = db_manager.create_user(
                firstname=data['firstname'],
                lastname=data['lastname'],
                email=data['email'],
                password=data['password']
            )
            
            # Enviar correo electrónico de bienvenida (opcional)
            try:
                msg = Message(
                    subject='Bienvenido a nuestra plataforma',
                    sender=config.mail.username,
                    recipients=[data['email']]
                )
                msg.body = f'Hola {data["firstname"]},\n\n¡Bienvenido a nuestra plataforma! Gracias por registrarte.'
                mail.send(msg)
            except Exception as e:
                print(f'Error enviando el correo: {e}')
            
            return jsonify({'message': 'Usuario registrado exitosamente'}), 201
            
        except Exception as e:
            return jsonify({'error': 'Error al registrar usuario'}), 500
    
    @app.route('/login', methods=['POST'])
    def login():
        """Endpoint para login de usuarios"""
        data = request.get_json()
        
        # Validar que todos los campos estén presentes
        if not data or not all(key in data for key in ['email', 'password']):
            return jsonify({'error': 'Faltan campos obligatorios'}), 400
        
        # Buscar al usuario por su correo electrónico
        user = db_manager.get_user_by_email(data['email'])
        
        # Verificar si el usuario existe y si la contraseña es correcta
        if user and user.check_password(data['password']):
            try:
                # Generar tokens JWT
                user_data = {
                    'email': user.email,
                    'name': f"{user.firstname} {user.lastname}",
                    'role': getattr(user, 'role', 'user')
                }
                
                tokens = jwt_manager.generate_tokens(user.id, user_data)
                
                if not tokens:
                    return jsonify({'error': 'Error generando tokens'}), 500
                
                # Devolver una respuesta exitosa con tokens
                return jsonify({
                    'message': 'Inicio de sesión exitoso',
                    'user': {
                        'id': user.id,
                        'firstname': user.firstname,
                        'lastname': user.lastname,
                        'email': user.email,
                        'name': user_data['name'],
                        'role': user_data['role']
                    },
                    **tokens
                }), 200
                
            except Exception as e:
                return jsonify({'error': 'Error al generar tokens'}), 500
        else:
            return jsonify({'error': 'Credenciales inválidas'}), 401
    
    @app.route('/verify-token', methods=['GET'])
    @token_required
    def verify_token():
        """Endpoint para verificar token JWT"""
        return jsonify({
            'message': 'Token válido',
            'user': request.current_user
        }), 200
    
    @app.route('/refresh-token', methods=['POST'])
    def refresh_token():
        """Endpoint para renovar access token"""
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
    
    @app.route('/logout', methods=['POST'])
    @token_required
    def logout():
        """Endpoint para logout"""
        # Con JWT, el logout es principalmente del lado del cliente
        # El token se invalida simplemente no enviándolo en futuras requests
        return jsonify({
            'message': 'Sesión cerrada exitosamente'
        }), 200
    
    @app.route('/health', methods=['GET'])
    def health_check():
        """Endpoint de health check"""
        return jsonify({
            'status': 'OK', 
            'service': 'auth-service',
            'message': 'Servicio de autenticación funcionando correctamente'
        }), 200
    
    return app

def run_auth_service():
    """Ejecutar el servicio de autenticación"""
    app = create_auth_service()
    service_config = config.get_service_config('auth')
    
    print(f"🚀 Iniciando servicio de autenticación en http://{service_config.host}:{service_config.port}")
    
    app.run(
        host=service_config.host,
        port=service_config.port,
        debug=service_config.debug
    )

if __name__ == '__main__':
    run_auth_service()
