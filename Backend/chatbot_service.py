#!/usr/bin/env python3
"""
Microservicio de Chatbot con LLM y RAG
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import logging
from datetime import datetime
from services.chatbot_service import chatbot_service

# Configuración de logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def create_chatbot_app():
    """Crear aplicación Flask para el chatbot"""
    
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
            'model': 'Gemma 3 3B (simulated)',
            'rag_enabled': True,
            'timestamp': datetime.utcnow().isoformat()
        })
    
    @app.route('/status', methods=['GET'])
    def get_status():
        """Obtener estado del chatbot"""
        try:
            status = chatbot_service.get_status()
            return jsonify({
                'status': status,
                'model': chatbot_service.model,
                'timestamp': datetime.utcnow().isoformat()
            }), 200
        except Exception as e:
            logger.error(f"❌ Error obteniendo estado: {e}")
            return jsonify({
                'status': 'error',
                'error': str(e)
            }), 500
    
    @app.route('/initialize', methods=['POST'])
    def initialize():
        """Inicializar el chatbot"""
        try:
            success = chatbot_service.initialize()
            return jsonify({
                'success': success,
                'message': 'Chatbot inicializado correctamente' if success else 'Error inicializando chatbot',
                'timestamp': datetime.utcnow().isoformat()
            }), 200 if success else 500
        except Exception as e:
            logger.error(f"❌ Error en inicialización: {e}")
            return jsonify({
                'success': False,
                'error': str(e)
            }), 500
    
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
            
            # Procesar mensaje con el chatbot
            result = chatbot_service.process_message(user_message, user_id)
            
            logger.info(f"🤖 Respuesta generada: {result['response'][:100]}...")
            
            return jsonify({
                'response': result['response'],
                'confidence': result['confidence'],
                'sources': result['sources'],
                'context_used': result['context_used'],
                'timestamp': datetime.utcnow().isoformat()
            }), 200
            
        except Exception as e:
            logger.error(f"❌ Error en chat: {e}")
            return jsonify({
                'error': f'Error en el chat: {str(e)}',
                'response': 'Lo siento, estoy teniendo problemas técnicos. ¿Puedes intentar de nuevo?'
            }), 500
    
    @app.route('/chat/history', methods=['GET'])
    def get_chat_history():
        """Obtener historial de chat de un usuario"""
        try:
            user_id = request.args.get('user_id', 'default')
            
            if user_id in chatbot_service.conversation_history:
                history = chatbot_service.conversation_history[user_id]
                return jsonify({
                    'history': history,
                    'total_messages': len(history)
                }), 200
            else:
                return jsonify({
                    'history': [],
                    'total_messages': 0
                }), 200
                
        except Exception as e:
            logger.error(f"❌ Error obteniendo historial: {e}")
            return jsonify({'error': str(e)}), 500
    
    @app.route('/chat/clear', methods=['POST'])
    def clear_chat_history():
        """Limpiar historial de chat de un usuario"""
        try:
            data = request.get_json()
            user_id = data.get('user_id', 'default')
            
            if user_id in chatbot_service.conversation_history:
                del chatbot_service.conversation_history[user_id]
            
            return jsonify({
                'message': 'Historial limpiado correctamente',
                'timestamp': datetime.utcnow().isoformat()
            }), 200
            
        except Exception as e:
            logger.error(f"❌ Error limpiando historial: {e}")
            return jsonify({'error': str(e)}), 500
    
    @app.route('/knowledge', methods=['GET'])
    def get_knowledge_base():
        """Obtener información de la base de conocimiento"""
        try:
            return jsonify({
                'knowledge_base': chatbot_service.knowledge_base,
                'total_sections': len(chatbot_service.knowledge_base)
            }), 200
            
        except Exception as e:
            logger.error(f"❌ Error obteniendo base de conocimiento: {e}")
            return jsonify({'error': str(e)}), 500
    
    @app.errorhandler(404)
    def not_found(error):
        return jsonify({'error': 'Endpoint no encontrado'}), 404
    
    @app.errorhandler(500)
    def internal_error(error):
        return jsonify({'error': 'Error interno del servidor'}), 500
    
    return app

if __name__ == '__main__':
    logger.info("🚀 Iniciando microservicio de chatbot...")
    
    # Crear aplicación
    app = create_chatbot_app()
    
    # Inicializar chatbot
    logger.info("🤖 Inicializando chatbot...")
    success = chatbot_service.initialize()
    
    if success:
        logger.info("✅ Chatbot inicializado correctamente")
    else:
        logger.warning("⚠️ Chatbot inicializado en modo fallback")
    
    # Ejecutar aplicación
    logger.info("🌐 Servidor iniciando en puerto 5003...")
    app.run(host='0.0.0.0', port=5003, debug=True)
