"""
Configuración central para todos los microservicios
"""

import os
from dataclasses import dataclass
from typing import Dict, Any

@dataclass
class DatabaseConfig:
    """Configuración de la base de datos"""
    uri: str = 'sqlite:///auth.db'
    track_modifications: bool = False

@dataclass
class MailConfig:
    """Configuración del servicio de correo"""
    server: str = 'smtp.gmail.com'
    port: int = 587
    use_tls: bool = True
    username: str = 'tucorreo@gmail.com'
    password: str = 'tucontraseña'

@dataclass
class SecurityConfig:
    """Configuración de seguridad"""
    secret_key: str = 'tu-clave-secreta-aqui'
    session_timeout_hours: int = 24

@dataclass
class ServiceConfig:
    """Configuración de cada microservicio"""
    name: str
    port: int
    host: str = '0.0.0.0'
    debug: bool = True
    cors_origins: list = None

class Config:
    """Configuración principal de la aplicación"""
    
    def __init__(self):
        self.database = DatabaseConfig()
        self.mail = MailConfig()
        self.security = SecurityConfig()
        
        # Configuración de microservicios
        self.services = {
            'auth': ServiceConfig(
                name='auth-service',
                port=5000,
                cors_origins=["http://localhost:3000", "http://localhost:5173", "http://127.0.0.1:5173"]
            ),
            'cards': ServiceConfig(
                name='cards-service',
                port=5001,
                cors_origins=["http://localhost:3000", "http://localhost:5173", "http://127.0.0.1:5173"]
            ),
            'profile': ServiceConfig(
                name='profile-service',
                port=5003,
                cors_origins=["http://localhost:3000", "http://localhost:5173", "http://127.0.0.1:5173"]
            ),
            'chatbot': ServiceConfig(
                name='chatbot-service',
                port=5005,
                cors_origins=["http://localhost:3000", "http://localhost:5173", "http://127.0.0.1:5173"]
            ),
            'transaction': ServiceConfig(
                name='transaction-service',
                port=5004,
                cors_origins=["http://localhost:3000", "http://localhost:5173", "http://127.0.0.1:5173"]
            ),
            'api': ServiceConfig(
                name='api-gateway',
                port=5002,
                cors_origins=["http://localhost:3000", "http://localhost:5173", "http://127.0.0.1:5173"]
            )
        }
    
    def get_service_config(self, service_name: str) -> ServiceConfig:
        """Obtener configuración de un servicio específico"""
        return self.services.get(service_name)
    
    def get_all_services(self) -> Dict[str, ServiceConfig]:
        """Obtener configuración de todos los servicios"""
        return self.services
    
    def to_dict(self) -> Dict[str, Any]:
        """Convertir configuración a diccionario"""
        return {
            'database': {
                'uri': self.database.uri,
                'track_modifications': self.database.track_modifications
            },
            'mail': {
                'server': self.mail.server,
                'port': self.mail.port,
                'use_tls': self.mail.use_tls,
                'username': self.mail.username,
                'password': self.mail.password
            },
            'security': {
                'secret_key': self.security.secret_key,
                'session_timeout_hours': self.security.session_timeout_hours
            },
            'services': {
                name: {
                    'name': config.name,
                    'port': config.port,
                    'host': config.host,
                    'debug': config.debug,
                    'cors_origins': config.cors_origins
                }
                for name, config in self.services.items()
            }
        }

# Instancia global de configuración
config = Config()
