#!/usr/bin/env python3
"""
Servicio simplificado de Chatbot para AlworkiAuto
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import logging
from datetime import datetime
import json

# Configuración de logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Base de conocimiento simplificada
KNOWLEDGE_BASE = {
    "about": {
        "name": "AlworkiAuto",
        "description": "Plataforma de intercambio y compraventa de vehículos",
        "features": [
            "Intercambio de vehículos",
            "Compra y venta",
            "Evaluación de vehículos",
            "Sistema de reputación",
            "Chat de soporte"
        ]
    },
    "services": {
        "exchange": {
            "title": "Intercambio de Vehículos",
            "description": "Intercambia tu vehículo por otro de valor similar",
            "process": [
                "Registra tu vehículo",
                "Especifica tus preferencias",
                "Recibe ofertas de intercambio",
                "Negocia y acuerda el intercambio"
            ]
        },
        "buy_sell": {
            "title": "Compra y Venta",
            "description": "Compra o vende vehículos de forma segura",
            "process": [
                "Lista tu vehículo",
                "Establece el precio",
                "Recibe ofertas",
                "Cierra la venta"
            ]
        },
        "evaluation": {
            "title": "Evaluación de Vehículos",
            "description": "Obtén una evaluación profesional de tu vehículo",
            "features": [
                "Inspección técnica",
                "Valoración de mercado",
                "Reporte detallado"
            ]
        }
    },
    "account": {
        "registration": {
            "steps": [
                "Crear cuenta con email",
                "Verificar email",
                "Completar perfil",
                "Subir documentos"
            ],
            "required_docs": [
                "Identificación personal",
                "Licencia de conducir",
                "Documentos del vehículo"
            ]
        },
        "profile": {
            "fields": [
                "Nombre completo",
                "Email",
                "Teléfono",
                "Dirección",
                "Foto de perfil"
            ]
        }
    },
    "support": {
        "contact": {
            "email": "soporte@alworkiauto.com",
            "phone": "+1-800-ALWORKI",
            "hours": "Lunes a Viernes 9:00 AM - 6:00 PM"
        },
        "faq": {
            "common_questions": [
                "¿Cómo funciona el intercambio?",
                "¿Es seguro vender mi vehículo?",
                "¿Qué documentos necesito?",
                "¿Cómo se evalúa mi vehículo?"
            ]
        }
    }
}

def generate_response(query):
    """Generar respuesta basada en la consulta"""
    query_lower = query.lower()
    
    # Respuestas predefinidas
    if "hola" in query_lower or "buenos" in query_lower:
        return {
            "response": "¡Hola! Soy el asistente de AlworkiAuto. ¿En qué puedo ayudarte?",
            "confidence": True,
            "sources": ["greeting"]
        }
    
    elif "intercambio" in query_lower or "cambiar" in query_lower:
        return {
            "response": "El intercambio de vehículos en AlworkiAuto funciona de la siguiente manera: Primero registras tu vehículo con fotos y detalles, luego especificas qué tipo de vehículo buscas, recibes ofertas de otros usuarios interesados en intercambiar, y finalmente negocian los términos del intercambio. Es un proceso seguro y transparente.",
            "confidence": True,
            "sources": ["services.exchange"]
        }
    
    elif "comprar" in query_lower or "vender" in query_lower:
        return {
            "response": "Para comprar o vender vehículos en AlworkiAuto: Si quieres vender, listas tu vehículo con precio y fotos detalladas. Si quieres comprar, puedes buscar entre los vehículos disponibles y hacer ofertas. Todas las transacciones son seguras y verificadas.",
            "confidence": True,
            "sources": ["services.buy_sell"]
        }
    
    elif "cuenta" in query_lower or "registro" in query_lower:
        return {
            "response": "Para crear una cuenta en AlworkiAuto: 1) Ve a la página de registro, 2) Completa tu información personal, 3) Verifica tu email, 4) Sube los documentos requeridos (identificación, licencia, documentos del vehículo), 5) Completa tu perfil con foto. El proceso es rápido y seguro.",
            "confidence": True,
            "sources": ["account.registration"]
        }
    
    elif "evaluación" in query_lower or "valor" in query_lower:
        return {
            "response": "La evaluación de vehículos incluye una inspección técnica completa, valoración de mercado basada en datos actuales, y un reporte detallado con el estado del vehículo y su valor estimado. Esto te ayuda a establecer un precio justo.",
            "confidence": True,
            "sources": ["services.evaluation"]
        }
    
    elif "soporte" in query_lower or "ayuda" in query_lower:
        return {
            "response": "Nuestro equipo de soporte está disponible de lunes a viernes de 9:00 AM a 6:00 PM. Puedes contactarnos por email a soporte@alworkiauto.com o llamar al +1-800-ALWORKI. También tenemos una sección de FAQ con preguntas comunes.",
            "confidence": True,
            "sources": ["support.contact"]
        }
    
    elif "alworki" in query_lower or "plataforma" in query_lower:
        return {
            "response": "AlworkiAuto es una plataforma innovadora para el intercambio y compraventa de vehículos. Ofrecemos un sistema seguro, transparente y fácil de usar donde puedes intercambiar tu vehículo, comprar o vender con confianza.",
            "confidence": True,
            "sources": ["about"]
        }
    
    elif "documentos" in query_lower or "papeles" in query_lower:
        return {
            "response": "Los documentos requeridos para usar AlworkiAuto incluyen: identificación personal, licencia de conducir, y documentos del vehículo. Estos documentos son necesarios para verificar tu identidad y la propiedad del vehículo.",
            "confidence": True,
            "sources": ["account.registration.required_docs"]
        }
    
    elif "gracias" in query_lower:
        return {
            "response": "¡De nada! Estoy aquí para ayudarte. ¿Hay algo más en lo que pueda asistirte?",
            "confidence": True,
            "sources": ["greeting"]
        }
    
    else:
        return {
            "response": "Hola! Soy el asistente de AlworkiAuto. Puedo ayudarte con información sobre intercambios, compraventa, evaluación de vehículos, creación de cuentas y más. ¿En qué puedo ayudarte?",
            "confidence": False,
            "sources": ["general"]
        }

# Crear aplicación Flask
app = Flask(__name__)

# Configuración de CORS
CORS(app, resources={
    r"/*": {
        "origins": ["http://localhost:5173", "http://127.0.0.1:5173", "http://localhost:5174", "http://127.0.0.1:5174"],
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization"]
    }
})

@app.route('/health', methods=['GET'])
def health_check():
    """Endpoint de salud del servicio"""
    return jsonify({
        'service': 'chatbot',
        'status': 'healthy',
        'model': 'Simple Chatbot',
        'rag_enabled': True,
        'timestamp': datetime.utcnow().isoformat()
    })

@app.route('/status', methods=['GET'])
def get_status():
    """Obtener estado del chatbot"""
    return jsonify({
        'status': 'online',
        'model': 'Simple Chatbot',
        'timestamp': datetime.utcnow().isoformat()
    })

@app.route('/initialize', methods=['POST'])
def initialize():
    """Inicializar el chatbot"""
    return jsonify({
        'success': True,
        'message': 'Chatbot inicializado correctamente',
        'timestamp': datetime.utcnow().isoformat()
    })

@app.route('/chat', methods=['POST'])
def chat():
    """Endpoint para chat con el bot"""
    try:
        data = request.get_json()
        
        if not data or 'message' not in data:
            return jsonify({'error': 'Mensaje requerido'}), 400
        
        user_message = data['message'].strip()
        user_id = data.get('user_id', 'default')
        
        if not user_message:
            return jsonify({'error': 'Mensaje no puede estar vacío'}), 400
        
        logger.info(f"🤖 Mensaje recibido: {user_message}")
        
        # Generar respuesta
        result = generate_response(user_message)
        
        logger.info(f"🤖 Respuesta generada: {result['response'][:100]}...")
        
        return jsonify({
            'response': result['response'],
            'confidence': result['confidence'],
            'sources': result['sources'],
            'context_used': len(result['sources']),
            'timestamp': datetime.utcnow().isoformat()
        }), 200
        
    except Exception as e:
        logger.error(f"❌ Error en chat: {e}")
        return jsonify({
            'error': f'Error en el chat: {str(e)}',
            'response': 'Lo siento, estoy teniendo problemas técnicos. ¿Puedes intentar de nuevo?'
        }), 500

@app.route('/knowledge', methods=['GET'])
def get_knowledge_base():
    """Obtener información de la base de conocimiento"""
    return jsonify({
        'knowledge_base': KNOWLEDGE_BASE,
        'total_sections': len(KNOWLEDGE_BASE)
    })

@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Endpoint no encontrado'}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({'error': 'Error interno del servidor'}), 500

if __name__ == '__main__':
    logger.info("🚀 Iniciando servicio simplificado de chatbot...")
    logger.info("🌐 Servidor iniciando en puerto 5003...")
    app.run(host='0.0.0.0', port=5003, debug=True)

