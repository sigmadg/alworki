"""
Microservicio de Perfil de Usuario
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import sys
import os
import jwt
from datetime import datetime, timedelta
from functools import wraps

# Agregar el directorio raíz al path para importar módulos
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from config.config import config
from utils.database import db_manager, User, UserProfile

def create_profile_service():
    """Crear y configurar el servicio de perfil de usuario"""
    
    app = Flask(__name__)
    
    # Configuración del servicio
    service_config = config.get_service_config('profile')
    
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
    
    def token_required(f):
        """Decorador para verificar token JWT"""
        @wraps(f)
        def decorated(*args, **kwargs):
            token = None
            
            # Obtener token del header Authorization
            if 'Authorization' in request.headers:
                auth_header = request.headers['Authorization']
                try:
                    token = auth_header.split(" ")[1]  # Bearer <token>
                except IndexError:
                    return jsonify({'error': 'Token inválido'}), 401
            
            if not token:
                return jsonify({'error': 'Token requerido'}), 401
            
            try:
                # Decodificar token
                data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
                current_user = db_manager.get_user_by_id(data['user_id'])
                
                if not current_user:
                    return jsonify({'error': 'Usuario no encontrado'}), 401
                
            except jwt.ExpiredSignatureError:
                return jsonify({'error': 'Token expirado'}), 401
            except jwt.InvalidTokenError:
                return jsonify({'error': 'Token inválido'}), 401
            
            return f(current_user, *args, **kwargs)
        
        return decorated
    
    @app.route('/health', methods=['GET'])
    def health_check():
        """Endpoint de salud del servicio"""
        return jsonify({
            'service': 'profile',
            'status': 'healthy',
            'timestamp': datetime.utcnow().isoformat()
        })
    
    @app.route('/profile', methods=['GET'])
    @token_required
    def get_profile(current_user):
        """Obtener perfil del usuario actual"""
        try:
            profile = db_manager.get_user_profile(current_user.id)
            
            if not profile:
                return jsonify({'error': 'Perfil no encontrado'}), 404
            
            # Incrementar vistas del perfil
            db_manager.increment_profile_views(current_user.id)
            
            # Combinar datos del usuario y perfil
            user_data = {
                'id': current_user.id,
                'firstname': current_user.firstname,
                'lastname': current_user.lastname,
                'email': current_user.email,
                'created_at': current_user.created_at.isoformat(),
                'updated_at': current_user.updated_at.isoformat(),
                'is_active': current_user.is_active,
                'is_verified': current_user.is_verified
            }
            
            profile_data = profile.to_dict()
            
            return jsonify({
                'user': user_data,
                'profile': profile_data
            }), 200
            
        except Exception as e:
            return jsonify({'error': f'Error al obtener perfil: {str(e)}'}), 500
    
    @app.route('/profile/<int:user_id>', methods=['GET'])
    def get_public_profile(user_id):
        """Obtener perfil público de un usuario"""
        try:
            user = db_manager.get_user_by_id(user_id)
            if not user:
                return jsonify({'error': 'Usuario no encontrado'}), 404
            
            profile = db_manager.get_user_profile(user_id)
            if not profile:
                return jsonify({'error': 'Perfil no encontrado'}), 404
            
            # Incrementar vistas del perfil
            db_manager.increment_profile_views(user_id)
            
            # Datos públicos del usuario
            user_data = {
                'id': user.id,
                'firstname': user.firstname,
                'lastname': user.lastname,
                'created_at': user.created_at.isoformat()
            }
            
            # Datos públicos del perfil (excluir información sensible)
            public_profile = {
                'avatar_url': profile.avatar_url,
                'bio': profile.bio,
                'profession': profile.profession,
                'company': profile.company,
                'country': profile.country,
                'city': profile.city,
                'website': profile.website,
                'linkedin_url': profile.linkedin_url,
                'github_url': profile.github_url,
                'profile_views': profile.profile_views,
                'projects_completed': profile.projects_completed,
                'rating_average': profile.rating_average,
                'total_reviews': profile.total_reviews
            }
            
            return jsonify({
                'user': user_data,
                'profile': public_profile
            }), 200
            
        except Exception as e:
            return jsonify({'error': f'Error al obtener perfil público: {str(e)}'}), 500
    
    @app.route('/profile', methods=['PUT'])
    @token_required
    def update_profile(current_user):
        """Actualizar perfil del usuario"""
        try:
            data = request.get_json()
            
            if not data:
                return jsonify({'error': 'Datos requeridos'}), 400
            
            # Validar campos opcionales
            allowed_fields = [
                'avatar_url', 'bio', 'phone', 'date_of_birth', 'gender',
                'country', 'city', 'address', 'postal_code', 'profession',
                'company', 'website', 'linkedin_url', 'github_url',
                'language', 'timezone', 'notification_email', 'notification_push'
            ]
            
            # Filtrar solo campos permitidos
            profile_data = {k: v for k, v in data.items() if k in allowed_fields}
            
            # Validar fecha de nacimiento
            if 'date_of_birth' in profile_data and profile_data['date_of_birth']:
                try:
                    datetime.strptime(profile_data['date_of_birth'], '%Y-%m-%d')
                except ValueError:
                    return jsonify({'error': 'Formato de fecha inválido. Use YYYY-MM-DD'}), 400
            
            # Validar género
            if 'gender' in profile_data and profile_data['gender']:
                if profile_data['gender'] not in ['male', 'female', 'other']:
                    return jsonify({'error': 'Género inválido'}), 400
            
            # Validar idioma
            if 'language' in profile_data and profile_data['language']:
                if profile_data['language'] not in ['es', 'en']:
                    return jsonify({'error': 'Idioma inválido'}), 400
            
            # Actualizar perfil
            updated_profile = db_manager.update_user_profile(current_user.id, profile_data)
            
            return jsonify({
                'message': 'Perfil actualizado exitosamente',
                'profile': updated_profile.to_dict()
            }), 200
            
        except Exception as e:
            return jsonify({'error': f'Error al actualizar perfil: {str(e)}'}), 500
    
    @app.route('/profile/avatar', methods=['POST'])
    @token_required
    def upload_avatar(current_user):
        """Subir avatar del usuario"""
        try:
            if 'avatar' not in request.files:
                return jsonify({'error': 'Archivo de avatar requerido'}), 400
            
            file = request.files['avatar']
            
            if file.filename == '':
                return jsonify({'error': 'Archivo no seleccionado'}), 400
            
            # Validar tipo de archivo
            allowed_extensions = {'png', 'jpg', 'jpeg', 'gif'}
            if not ('.' in file.filename and 
                   file.filename.rsplit('.', 1)[1].lower() in allowed_extensions):
                return jsonify({'error': 'Tipo de archivo no permitido'}), 400
            
            # Validar tamaño (máximo 5MB)
            if len(file.read()) > 5 * 1024 * 1024:
                return jsonify({'error': 'Archivo demasiado grande. Máximo 5MB'}), 400
            
            file.seek(0)  # Resetear posición del archivo
            
            # Generar nombre único para el archivo
            timestamp = datetime.utcnow().strftime('%Y%m%d_%H%M%S')
            filename = f"avatar_{current_user.id}_{timestamp}.{file.filename.rsplit('.', 1)[1].lower()}"
            
            # Guardar archivo (en producción, usar un servicio de almacenamiento como S3)
            upload_folder = os.path.join(os.path.dirname(__file__), '..', 'uploads', 'avatars')
            os.makedirs(upload_folder, exist_ok=True)
            
            file_path = os.path.join(upload_folder, filename)
            file.save(file_path)
            
            # URL del avatar (en producción, usar CDN)
            avatar_url = f"/uploads/avatars/{filename}"
            
            # Actualizar perfil con la nueva URL del avatar
            profile_data = {'avatar_url': avatar_url}
            updated_profile = db_manager.update_user_profile(current_user.id, profile_data)
            
            return jsonify({
                'message': 'Avatar subido exitosamente',
                'avatar_url': avatar_url
            }), 200
            
        except Exception as e:
            return jsonify({'error': f'Error al subir avatar: {str(e)}'}), 500
    
    @app.route('/profile/stats', methods=['PUT'])
    @token_required
    def update_stats(current_user):
        """Actualizar estadísticas del usuario"""
        try:
            data = request.get_json()
            
            if not data:
                return jsonify({'error': 'Datos requeridos'}), 400
            
            # Validar campos
            projects_completed = data.get('projects_completed')
            rating_average = data.get('rating_average')
            total_reviews = data.get('total_reviews')
            
            # Validar tipos de datos
            if projects_completed is not None and not isinstance(projects_completed, int):
                return jsonify({'error': 'projects_completed debe ser un número entero'}), 400
            
            if rating_average is not None:
                try:
                    rating_average = float(rating_average)
                    if not (0 <= rating_average <= 5):
                        return jsonify({'error': 'rating_average debe estar entre 0 y 5'}), 400
                except ValueError:
                    return jsonify({'error': 'rating_average debe ser un número'}), 400
            
            if total_reviews is not None and not isinstance(total_reviews, int):
                return jsonify({'error': 'total_reviews debe ser un número entero'}), 400
            
            # Actualizar estadísticas
            db_manager.update_user_stats(
                current_user.id,
                projects_completed=projects_completed,
                rating_average=rating_average,
                total_reviews=total_reviews
            )
            
            return jsonify({'message': 'Estadísticas actualizadas exitosamente'}), 200
            
        except Exception as e:
            return jsonify({'error': f'Error al actualizar estadísticas: {str(e)}'}), 500
    
    @app.route('/profile/search', methods=['GET'])
    def search_profiles():
        """Buscar perfiles de usuarios"""
        try:
            # Parámetros de búsqueda
            query = request.args.get('q', '').strip()
            profession = request.args.get('profession', '').strip()
            country = request.args.get('country', '').strip()
            city = request.args.get('city', '').strip()
            page = int(request.args.get('page', 1))
            per_page = min(int(request.args.get('per_page', 10)), 50)  # Máximo 50 por página
            
            if not query and not profession and not country and not city:
                return jsonify({'error': 'Al menos un parámetro de búsqueda es requerido'}), 400
            
            # Construir consulta
            from sqlalchemy import or_, and_
            
            query_conditions = []
            
            if query:
                query_conditions.append(
                    or_(
                        User.firstname.ilike(f'%{query}%'),
                        User.lastname.ilike(f'%{query}%'),
                        UserProfile.bio.ilike(f'%{query}%'),
                        UserProfile.profession.ilike(f'%{query}%'),
                        UserProfile.company.ilike(f'%{query}%')
                    )
                )
            
            if profession:
                query_conditions.append(UserProfile.profession.ilike(f'%{profession}%'))
            
            if country:
                query_conditions.append(UserProfile.country.ilike(f'%{country}%'))
            
            if city:
                query_conditions.append(UserProfile.city.ilike(f'%{city}%'))
            
            # Ejecutar consulta
            results = db_manager.session.query(User, UserProfile).join(UserProfile).filter(
                and_(*query_conditions),
                User.is_active == True
            ).paginate(
                page=page,
                per_page=per_page,
                error_out=False
            )
            
            # Formatear resultados
            profiles = []
            for user, profile in results.items:
                profiles.append({
                    'user': {
                        'id': user.id,
                        'firstname': user.firstname,
                        'lastname': user.lastname,
                        'created_at': user.created_at.isoformat()
                    },
                    'profile': {
                        'avatar_url': profile.avatar_url,
                        'bio': profile.bio,
                        'profession': profile.profession,
                        'company': profile.company,
                        'country': profile.country,
                        'city': profile.city,
                        'profile_views': profile.profile_views,
                        'projects_completed': profile.projects_completed,
                        'rating_average': profile.rating_average,
                        'total_reviews': profile.total_reviews
                    }
                })
            
            return jsonify({
                'profiles': profiles,
                'pagination': {
                    'page': page,
                    'per_page': per_page,
                    'total': results.total,
                    'pages': results.pages,
                    'has_next': results.has_next,
                    'has_prev': results.has_prev
                }
            }), 200
            
        except Exception as e:
            return jsonify({'error': f'Error en la búsqueda: {str(e)}'}), 500
    
    @app.route('/profile/delete', methods=['DELETE'])
    @token_required
    def delete_profile(current_user):
        """Eliminar perfil del usuario (marcar como inactivo)"""
        try:
            # Marcar usuario como inactivo en lugar de eliminarlo
            current_user.is_active = False
            current_user.updated_at = datetime.utcnow()
            
            db_manager.session.commit()
            
            return jsonify({'message': 'Perfil eliminado exitosamente'}), 200
            
        except Exception as e:
            return jsonify({'error': f'Error al eliminar perfil: {str(e)}'}), 500
    
    return app

if __name__ == '__main__':
    app = create_profile_service()
    app.run(host='0.0.0.0', port=5003, debug=True)
