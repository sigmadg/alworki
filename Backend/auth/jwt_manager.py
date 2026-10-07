#!/usr/bin/env python3
"""
Gestor de JWT para AlworkiAuto
Maneja la creación, validación y renovación de tokens JWT
"""

import jwt
import os
from datetime import datetime, timedelta
from functools import wraps
from flask import request, jsonify, current_app
import logging

logger = logging.getLogger(__name__)

class JWTManager:
    def __init__(self, app=None):
        self.app = app
        if app is not None:
            self.init_app(app)
    
    def init_app(self, app):
        """Inicializar la aplicación con JWT"""
        self.app = app
        # Configuración JWT
        app.config.setdefault('JWT_SECRET_KEY', os.environ.get('JWT_SECRET_KEY', 'alworki-auto-secret-key-2024'))
        app.config.setdefault('JWT_ACCESS_TOKEN_EXPIRES', timedelta(hours=24))
        app.config.setdefault('JWT_REFRESH_TOKEN_EXPIRES', timedelta(days=30))
        app.config.setdefault('JWT_ALGORITHM', 'HS256')
        
        self.secret_key = app.config['JWT_SECRET_KEY']
        self.access_expires = app.config['JWT_ACCESS_TOKEN_EXPIRES']
        self.refresh_expires = app.config['JWT_REFRESH_TOKEN_EXPIRES']
        self.algorithm = app.config['JWT_ALGORITHM']
    
    def generate_tokens(self, user_id, user_data=None):
        """Generar tokens de acceso y refresh"""
        try:
            now = datetime.utcnow()
            
            # Payload para access token
            access_payload = {
                'user_id': user_id,
                'type': 'access',
                'iat': now,
                'exp': now + self.access_expires,
                'jti': f"access_{user_id}_{now.timestamp()}"
            }
            
            # Agregar datos adicionales del usuario si se proporcionan
            if user_data:
                access_payload.update({
                    'email': user_data.get('email'),
                    'name': user_data.get('name'),
                    'role': user_data.get('role', 'user')
                })
            
            # Payload para refresh token (incluye claims del usuario para renovar access sin BD)
            refresh_payload = {
                'user_id': user_id,
                'type': 'refresh',
                'iat': now,
                'exp': now + self.refresh_expires,
                'jti': f"refresh_{user_id}_{now.timestamp()}"
            }
            if user_data:
                for key in ('email', 'name', 'role'):
                    val = user_data.get(key)
                    if val is not None:
                        refresh_payload[key] = val
            
            # Generar tokens
            access_token = jwt.encode(access_payload, self.secret_key, algorithm=self.algorithm)
            refresh_token = jwt.encode(refresh_payload, self.secret_key, algorithm=self.algorithm)
            
            logger.info(f"Tokens generados para usuario {user_id}")
            
            return {
                'access_token': access_token,
                'refresh_token': refresh_token,
                'expires_in': int(self.access_expires.total_seconds()),
                'token_type': 'Bearer'
            }
            
        except Exception as e:
            logger.error(f"Error generando tokens: {e}")
            return None
    
    def verify_token(self, token, token_type='access'):
        """Verificar y decodificar un token"""
        try:
            payload = jwt.decode(token, self.secret_key, algorithms=[self.algorithm])
            
            # Verificar tipo de token
            if payload.get('type') != token_type:
                logger.warning(f"Tipo de token incorrecto. Esperado: {token_type}, Recibido: {payload.get('type')}")
                return None

            # La expiración ya la valida jwt.decode
            return payload
            
        except jwt.ExpiredSignatureError:
            logger.warning("Token expirado")
            return None
        except jwt.InvalidTokenError as e:
            logger.warning(f"Token inválido: {e}")
            return None
        except Exception as e:
            logger.error(f"Error verificando token: {e}")
            return None
    
    def refresh_access_token(self, refresh_token):
        """Renovar access token usando refresh token"""
        try:
            payload = self.verify_token(refresh_token, 'refresh')
            if not payload:
                return None
            
            user_id = payload['user_id']
            
            # Generar nuevo access token
            now = datetime.utcnow()
            access_payload = {
                'user_id': user_id,
                'type': 'access',
                'iat': now,
                'exp': now + self.access_expires,
                'jti': f"access_{user_id}_{now.timestamp()}"
            }
            
            # Mantener datos del usuario del refresh token
            for key in ['email', 'name', 'role']:
                if key in payload:
                    access_payload[key] = payload[key]
            
            access_token = jwt.encode(access_payload, self.secret_key, algorithm=self.algorithm)
            
            logger.info(f"Access token renovado para usuario {user_id}")
            
            return {
                'access_token': access_token,
                'expires_in': int(self.access_expires.total_seconds()),
                'token_type': 'Bearer'
            }
            
        except Exception as e:
            logger.error(f"Error renovando token: {e}")
            return None
    
    def get_user_from_token(self, token):
        """Obtener información del usuario desde el token"""
        payload = self.verify_token(token)
        if payload:
            return {
                'user_id': payload.get('user_id'),
                'email': payload.get('email'),
                'name': payload.get('name'),
                'role': payload.get('role', 'user')
            }
        return None

# Instancia global del JWT Manager
jwt_manager = JWTManager()

def token_required(f):
    """Decorador para proteger rutas que requieren autenticación"""
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        
        # Obtener token del header Authorization
        auth_header = request.headers.get('Authorization')
        if auth_header:
            try:
                token = auth_header.split(" ")[1]  # Bearer <token>
            except IndexError:
                return jsonify({'error': 'Formato de token inválido'}), 401
        
        if not token:
            return jsonify({'error': 'Token de acceso requerido'}), 401
        
        try:
            # Verificar token
            payload = jwt_manager.verify_token(token)
            if not payload:
                return jsonify({'error': 'Token inválido o expirado'}), 401
            
            # Agregar información del usuario al contexto de la request
            request.current_user = {
                'user_id': payload.get('user_id'),
                'email': payload.get('email'),
                'name': payload.get('name'),
                'role': payload.get('role', 'user')
            }
            
        except Exception as e:
            logger.error(f"Error en autenticación: {e}")
            return jsonify({'error': 'Error de autenticación'}), 401
        
        return f(*args, **kwargs)
    
    return decorated

def admin_required(f):
    """Decorador para proteger rutas que requieren rol de administrador"""
    @wraps(f)
    def decorated(*args, **kwargs):
        if not hasattr(request, 'current_user') or request.current_user.get('role') != 'admin':
            return jsonify({'error': 'Acceso denegado. Se requiere rol de administrador'}), 403
        return f(*args, **kwargs)
    
    return decorated
