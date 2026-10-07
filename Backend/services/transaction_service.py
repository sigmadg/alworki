"""
Servicio de Transacciones y Operaciones
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import sys
import os
import json
from datetime import datetime
from functools import wraps

# Agregar el directorio raíz al path para importar módulos
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from config.config import config
from utils.database import db_manager, Transaction, UserOperation, UserActivity

def create_transaction_service():
    """Crear y configurar el servicio de transacciones"""
    
    app = Flask(__name__)
    
    # Configuración del servicio
    service_config = config.get_service_config('transaction')
    
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
    
    # Inicializar base de datos
    db_manager.init_app(app)
    
    @app.route('/health', methods=['GET'])
    def health_check():
        """Endpoint de salud del servicio"""
        return jsonify({
            'service': 'transaction',
            'status': 'healthy',
            'timestamp': datetime.utcnow().isoformat()
        })
    
    @app.route('/transactions', methods=['POST'])
    def create_transaction():
        """Crear una nueva transacción"""
        try:
            data = request.get_json()
            
            if not data:
                return jsonify({'error': 'Datos requeridos'}), 400
            
            # Validar campos requeridos
            required_fields = ['user_id', 'transaction_type']
            for field in required_fields:
                if field not in data:
                    return jsonify({'error': f'Campo {field} requerido'}), 400
            
            # Crear transacción
            transaction = db_manager.create_transaction(
                user_id=data['user_id'],
                transaction_type=data['transaction_type'],
                vehicle_id=data.get('vehicle_id'),
                amount=data.get('amount'),
                currency=data.get('currency', 'USD'),
                description=data.get('description'),
                metadata=json.dumps(data.get('metadata', {})) if data.get('metadata') else None
            )
            
            return jsonify({
                'message': 'Transacción creada exitosamente',
                'transaction': transaction.to_dict()
            }), 201
            
        except Exception as e:
            return jsonify({'error': f'Error al crear transacción: {str(e)}'}), 500
    
    @app.route('/transactions/<int:user_id>', methods=['GET'])
    def get_user_transactions(user_id):
        """Obtener transacciones de un usuario"""
        try:
            limit = request.args.get('limit', 50, type=int)
            transactions = db_manager.get_user_transactions(user_id, limit)
            
            return jsonify({
                'transactions': [t.to_dict() for t in transactions],
                'total': len(transactions)
            }), 200
            
        except Exception as e:
            return jsonify({'error': f'Error al obtener transacciones: {str(e)}'}), 500
    
    @app.route('/operations', methods=['POST'])
    def log_operation():
        """Registrar una operación del usuario"""
        try:
            data = request.get_json()
            
            if not data:
                return jsonify({'error': 'Datos requeridos'}), 400
            
            # Validar campos requeridos
            required_fields = ['user_id', 'operation_type']
            for field in required_fields:
                if field not in data:
                    return jsonify({'error': f'Campo {field} requerido'}), 400
            
            # Registrar operación
            operation = db_manager.log_user_operation(
                user_id=data['user_id'],
                operation_type=data['operation_type'],
                operation_data=json.dumps(data.get('operation_data', {})) if data.get('operation_data') else None,
                ip_address=request.remote_addr,
                user_agent=request.headers.get('User-Agent'),
                success=data.get('success', True),
                error_message=data.get('error_message')
            )
            
            return jsonify({
                'message': 'Operación registrada exitosamente',
                'operation': operation.to_dict()
            }), 201
            
        except Exception as e:
            return jsonify({'error': f'Error al registrar operación: {str(e)}'}), 500
    
    @app.route('/operations/<int:user_id>', methods=['GET'])
    def get_user_operations(user_id):
        """Obtener operaciones de un usuario"""
        try:
            limit = request.args.get('limit', 100, type=int)
            operations = db_manager.get_user_operations(user_id, limit)
            
            return jsonify({
                'operations': [o.to_dict() for o in operations],
                'total': len(operations)
            }), 200
            
        except Exception as e:
            return jsonify({'error': f'Error al obtener operaciones: {str(e)}'}), 500
    
    @app.route('/activities', methods=['POST'])
    def log_activity():
        """Registrar una actividad del usuario"""
        try:
            data = request.get_json()
            
            if not data:
                return jsonify({'error': 'Datos requeridos'}), 400
            
            # Validar campos requeridos
            required_fields = ['user_id', 'activity_type']
            for field in required_fields:
                if field not in data:
                    return jsonify({'error': f'Campo {field} requerido'}), 400
            
            # Registrar actividad
            activity = db_manager.log_user_activity(
                user_id=data['user_id'],
                activity_type=data['activity_type'],
                activity_data=json.dumps(data.get('activity_data', {})) if data.get('activity_data') else None,
                page_url=data.get('page_url'),
                session_id=data.get('session_id')
            )
            
            return jsonify({
                'message': 'Actividad registrada exitosamente',
                'activity': activity.to_dict()
            }), 201
            
        except Exception as e:
            return jsonify({'error': f'Error al registrar actividad: {str(e)}'}), 500
    
    @app.route('/activities/<int:user_id>', methods=['GET'])
    def get_user_activities(user_id):
        """Obtener actividades de un usuario"""
        try:
            limit = request.args.get('limit', 200, type=int)
            activities = db_manager.get_user_activities(user_id, limit)
            
            return jsonify({
                'activities': [a.to_dict() for a in activities],
                'total': len(activities)
            }), 200
            
        except Exception as e:
            return jsonify({'error': f'Error al obtener actividades: {str(e)}'}), 500
    
    @app.route('/history/<int:user_id>', methods=['GET'])
    def get_user_history_summary(user_id):
        """Obtener resumen del historial del usuario"""
        try:
            history = db_manager.get_user_history_summary(user_id)
            return jsonify(history), 200
            
        except Exception as e:
            return jsonify({'error': f'Error al obtener historial: {str(e)}'}), 500
    
    return app

if __name__ == '__main__':
    app = create_transaction_service()
    app.run(host='0.0.0.0', port=5004, debug=True)
