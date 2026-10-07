"""
Módulo de base de datos compartido para microservicios
"""

from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from datetime import datetime, timedelta
import uuid
from werkzeug.security import generate_password_hash, check_password_hash
from typing import List, Dict

# Instancia global de SQLAlchemy
db = SQLAlchemy()
migrate = Migrate()

class User(db.Model):
    """Modelo de Usuario"""
    id = db.Column(db.Integer, primary_key=True)
    firstname = db.Column(db.String(80), nullable=False)
    lastname = db.Column(db.String(80), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password = db.Column(db.String(120), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    is_active = db.Column(db.Boolean, default=True)
    is_verified = db.Column(db.Boolean, default=False)
    
    # Relación con el perfil
    profile = db.relationship('UserProfile', backref='user', uselist=False, cascade='all, delete-orphan')

    def __repr__(self):
        return f'<User {self.email}>'

    def set_password(self, password: str):
        """Establecer contraseña hasheada"""
        self.password = generate_password_hash(password, method='pbkdf2:sha256')

    def check_password(self, password: str) -> bool:
        """Verificar contraseña"""
        return check_password_hash(self.password, password)

class UserProfile(db.Model):
    """Modelo de Perfil de Usuario"""
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False, unique=True)
    
    # Información personal
    avatar_url = db.Column(db.String(500))
    bio = db.Column(db.Text)
    phone = db.Column(db.String(20))
    date_of_birth = db.Column(db.Date)
    gender = db.Column(db.String(10))  # 'male', 'female', 'other'
    
    # Ubicación
    country = db.Column(db.String(100))
    city = db.Column(db.String(100))
    address = db.Column(db.Text)
    postal_code = db.Column(db.String(20))
    
    # Información profesional
    profession = db.Column(db.String(100))
    company = db.Column(db.String(100))
    website = db.Column(db.String(200))
    linkedin_url = db.Column(db.String(200))
    github_url = db.Column(db.String(200))
    
    # Preferencias
    language = db.Column(db.String(10), default='es')  # 'es', 'en'
    timezone = db.Column(db.String(50))
    notification_email = db.Column(db.Boolean, default=True)
    notification_push = db.Column(db.Boolean, default=True)
    
    # Estadísticas
    profile_views = db.Column(db.Integer, default=0)
    projects_completed = db.Column(db.Integer, default=0)
    rating_average = db.Column(db.Float, default=0.0)
    total_reviews = db.Column(db.Integer, default=0)
    
    # Metadatos
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def __repr__(self):
        return f'<UserProfile {self.user_id}>'
    
    def to_dict(self):
        """Convertir perfil a diccionario"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'avatar_url': self.avatar_url,
            'bio': self.bio,
            'phone': self.phone,
            'date_of_birth': self.date_of_birth.isoformat() if self.date_of_birth else None,
            'gender': self.gender,
            'country': self.country,
            'city': self.city,
            'address': self.address,
            'postal_code': self.postal_code,
            'profession': self.profession,
            'company': self.company,
            'website': self.website,
            'linkedin_url': self.linkedin_url,
            'github_url': self.github_url,
            'language': self.language,
            'timezone': self.timezone,
            'notification_email': self.notification_email,
            'notification_push': self.notification_push,
            'profile_views': self.profile_views,
            'projects_completed': self.projects_completed,
            'rating_average': self.rating_average,
            'total_reviews': self.total_reviews,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat()
        }

class Session(db.Model):
    """Modelo de Sesión"""
    id = db.Column(db.String(36), primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    session_date = db.Column(db.DateTime, default=datetime.utcnow)
    expires_at = db.Column(db.DateTime, nullable=False)
    status = db.Column(db.String(20), default='ACTIVE')

    def __repr__(self):
        return f'<Session {self.id}>'

    @classmethod
    def create_session(cls, user_id: int, timeout_hours: int = 24) -> str:
        """Crear una nueva sesión"""
        session_id = str(uuid.uuid4())
        expires_at = datetime.utcnow() + timedelta(hours=timeout_hours)
        
        session = cls(
            id=session_id,
            user_id=user_id,
            expires_at=expires_at
        )
        
        db.session.add(session)
        db.session.commit()
        
        return session_id

    def is_expired(self) -> bool:
        """Verificar si la sesión ha expirado"""
        return datetime.utcnow() > self.expires_at

    def deactivate(self):
        """Desactivar sesión"""
        self.status = 'INACTIVE'
        db.session.commit()

class Transaction(db.Model):
    """Modelo de Transacción"""
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    transaction_type = db.Column(db.String(50), nullable=False)  # 'buy', 'sell', 'exchange'
    vehicle_id = db.Column(db.String(100))  # ID del vehículo involucrado
    amount = db.Column(db.Float)  # Monto de la transacción
    currency = db.Column(db.String(10), default='USD')
    status = db.Column(db.String(20), default='pending')  # 'pending', 'completed', 'cancelled'
    description = db.Column(db.Text)
    transaction_metadata = db.Column(db.Text)  # JSON string con datos adicionales
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relación con el usuario
    user = db.relationship('User', backref='transactions')
    
    def __repr__(self):
        return f'<Transaction {self.id}: {self.transaction_type}>'
    
    def to_dict(self):
        """Convertir transacción a diccionario"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'transaction_type': self.transaction_type,
            'vehicle_id': self.vehicle_id,
            'amount': self.amount,
            'currency': self.currency,
            'status': self.status,
            'description': self.description,
            'metadata': self.metadata,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat()
        }

class UserOperation(db.Model):
    """Modelo de Operación del Usuario"""
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    operation_type = db.Column(db.String(50), nullable=False)  # 'login', 'profile_update', 'vehicle_list', 'search', etc.
    operation_data = db.Column(db.Text)  # JSON string con datos de la operación
    ip_address = db.Column(db.String(45))
    user_agent = db.Column(db.Text)
    success = db.Column(db.Boolean, default=True)
    error_message = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relación con el usuario
    user = db.relationship('User', backref='operations')
    
    def __repr__(self):
        return f'<UserOperation {self.id}: {self.operation_type}>'
    
    def to_dict(self):
        """Convertir operación a diccionario"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'operation_type': self.operation_type,
            'operation_data': self.operation_data,
            'ip_address': self.ip_address,
            'user_agent': self.user_agent,
            'success': self.success,
            'error_message': self.error_message,
            'created_at': self.created_at.isoformat()
        }

class UserActivity(db.Model):
    """Modelo de Actividad del Usuario"""
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    activity_type = db.Column(db.String(50), nullable=False)  # 'page_view', 'button_click', 'form_submit', etc.
    activity_data = db.Column(db.Text)  # JSON string con datos de la actividad
    page_url = db.Column(db.String(500))
    session_id = db.Column(db.String(100))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relación con el usuario
    user = db.relationship('User', backref='activities')
    
    def __repr__(self):
        return f'<UserActivity {self.id}: {self.activity_type}>'
    
    def to_dict(self):
        """Convertir actividad a diccionario"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'activity_type': self.activity_type,
            'activity_data': self.activity_data,
            'page_url': self.page_url,
            'session_id': self.session_id,
            'created_at': self.created_at.isoformat()
        }

class DatabaseManager:
    """Gestor de base de datos"""
    
    def __init__(self, app=None):
        if app:
            self.init_app(app)
    
    def init_app(self, app):
        """Inicializar la aplicación con la base de datos"""
        db.init_app(app)
        migrate.init_app(app, db)
        
        with app.app_context():
            db.create_all()
    
    def get_user_by_email(self, email: str) -> User:
        """Obtener usuario por email"""
        return User.query.filter_by(email=email).first()
    
    def get_user_by_id(self, user_id: int) -> User:
        """Obtener usuario por ID"""
        return User.query.get(user_id)
    
    def create_user(self, firstname: str, lastname: str, email: str, password: str) -> User:
        """Crear nuevo usuario"""
        user = User(
            firstname=firstname,
            lastname=lastname,
            email=email
        )
        user.set_password(password)
        
        db.session.add(user)
        db.session.commit()
        
        # Crear perfil automáticamente
        profile = UserProfile(user_id=user.id)
        db.session.add(profile)
        db.session.commit()
        
        return user
    
    def get_user_profile(self, user_id: int) -> UserProfile:
        """Obtener perfil de usuario"""
        return UserProfile.query.filter_by(user_id=user_id).first()
    
    def update_user_profile(self, user_id: int, profile_data: dict) -> UserProfile:
        """Actualizar perfil de usuario"""
        profile = self.get_user_profile(user_id)
        if not profile:
            profile = UserProfile(user_id=user_id)
            db.session.add(profile)
        
        # Actualizar campos permitidos
        allowed_fields = [
            'avatar_url', 'bio', 'phone', 'date_of_birth', 'gender',
            'country', 'city', 'address', 'postal_code', 'profession',
            'company', 'website', 'linkedin_url', 'github_url',
            'language', 'timezone', 'notification_email', 'notification_push'
        ]
        
        for field in allowed_fields:
            if field in profile_data:
                setattr(profile, field, profile_data[field])
        
        # Convertir string de fecha si existe
        if 'date_of_birth' in profile_data and profile_data['date_of_birth']:
            try:
                profile.date_of_birth = datetime.strptime(profile_data['date_of_birth'], '%Y-%m-%d').date()
            except ValueError:
                pass
        
        profile.updated_at = datetime.utcnow()
        db.session.commit()
        
        return profile
    
    def increment_profile_views(self, user_id: int):
        """Incrementar vistas del perfil"""
        profile = self.get_user_profile(user_id)
        if profile:
            profile.profile_views += 1
            db.session.commit()
    
    def update_user_stats(self, user_id: int, projects_completed: int = None, 
                         rating_average: float = None, total_reviews: int = None):
        """Actualizar estadísticas del usuario"""
        profile = self.get_user_profile(user_id)
        if profile:
            if projects_completed is not None:
                profile.projects_completed = projects_completed
            if rating_average is not None:
                profile.rating_average = rating_average
            if total_reviews is not None:
                profile.total_reviews = total_reviews
            
            profile.updated_at = datetime.utcnow()
            db.session.commit()
    
    def get_session_by_id(self, session_id: str) -> Session:
        """Obtener sesión por ID"""
        return Session.query.filter_by(id=session_id, status='ACTIVE').first()
    
    def deactivate_session(self, session_id: str):
        """Desactivar sesión"""
        session = self.get_session_by_id(session_id)
        if session:
            session.deactivate()
    
    # Métodos para transacciones
    def create_transaction(self, user_id: int, transaction_type: str, vehicle_id: str = None, 
                          amount: float = None, currency: str = 'USD', description: str = None, 
                          metadata: str = None) -> Transaction:
        """Crear una nueva transacción"""
        transaction = Transaction(
            user_id=user_id,
            transaction_type=transaction_type,
            vehicle_id=vehicle_id,
            amount=amount,
            currency=currency,
            description=description,
            metadata=metadata
        )
        
        db.session.add(transaction)
        db.session.commit()
        return transaction
    
    def get_user_transactions(self, user_id: int, limit: int = 50) -> List[Transaction]:
        """Obtener transacciones de un usuario"""
        return Transaction.query.filter_by(user_id=user_id).order_by(
            Transaction.created_at.desc()
        ).limit(limit).all()
    
    def update_transaction_status(self, transaction_id: int, status: str) -> Transaction:
        """Actualizar estado de una transacción"""
        transaction = Transaction.query.get(transaction_id)
        if transaction:
            transaction.status = status
            transaction.updated_at = datetime.utcnow()
            db.session.commit()
        return transaction
    
    # Métodos para operaciones
    def log_user_operation(self, user_id: int, operation_type: str, operation_data: str = None,
                          ip_address: str = None, user_agent: str = None, success: bool = True,
                          error_message: str = None) -> UserOperation:
        """Registrar una operación del usuario"""
        operation = UserOperation(
            user_id=user_id,
            operation_type=operation_type,
            operation_data=operation_data,
            ip_address=ip_address,
            user_agent=user_agent,
            success=success,
            error_message=error_message
        )
        
        db.session.add(operation)
        db.session.commit()
        return operation
    
    def get_user_operations(self, user_id: int, limit: int = 100) -> List[UserOperation]:
        """Obtener operaciones de un usuario"""
        return UserOperation.query.filter_by(user_id=user_id).order_by(
            UserOperation.created_at.desc()
        ).limit(limit).all()
    
    # Métodos para actividades
    def log_user_activity(self, user_id: int, activity_type: str, activity_data: str = None,
                         page_url: str = None, session_id: str = None) -> UserActivity:
        """Registrar una actividad del usuario"""
        activity = UserActivity(
            user_id=user_id,
            activity_type=activity_type,
            activity_data=activity_data,
            page_url=page_url,
            session_id=session_id
        )
        
        db.session.add(activity)
        db.session.commit()
        return activity
    
    def get_user_activities(self, user_id: int, limit: int = 200) -> List[UserActivity]:
        """Obtener actividades de un usuario"""
        return UserActivity.query.filter_by(user_id=user_id).order_by(
            UserActivity.created_at.desc()
        ).limit(limit).all()
    
    def get_user_history_summary(self, user_id: int) -> Dict:
        """Obtener resumen del historial del usuario para el chatbot"""
        # Obtener datos recientes
        recent_transactions = self.get_user_transactions(user_id, limit=10)
        recent_operations = self.get_user_operations(user_id, limit=20)
        recent_activities = self.get_user_activities(user_id, limit=50)
        
        # Procesar transacciones
        transaction_summary = {
            'total_transactions': len(recent_transactions),
            'transaction_types': {},
            'total_amount': 0,
            'recent_transactions': []
        }
        
        for transaction in recent_transactions:
            # Contar tipos de transacciones
            if transaction.transaction_type not in transaction_summary['transaction_types']:
                transaction_summary['transaction_types'][transaction.transaction_type] = 0
            transaction_summary['transaction_types'][transaction.transaction_type] += 1
            
            # Sumar montos
            if transaction.amount:
                transaction_summary['total_amount'] += transaction.amount
            
            # Agregar a transacciones recientes
            transaction_summary['recent_transactions'].append({
                'type': transaction.transaction_type,
                'amount': transaction.amount,
                'status': transaction.status,
                'date': transaction.created_at.isoformat(),
                'description': transaction.description
            })
        
        # Procesar operaciones
        operation_summary = {
            'total_operations': len(recent_operations),
            'operation_types': {},
            'success_rate': 0,
            'recent_operations': []
        }
        
        successful_operations = 0
        for operation in recent_operations:
            # Contar tipos de operaciones
            if operation.operation_type not in operation_summary['operation_types']:
                operation_summary['operation_types'][operation.operation_type] = 0
            operation_summary['operation_types'][operation.operation_type] += 1
            
            # Contar operaciones exitosas
            if operation.success:
                successful_operations += 1
            
            # Agregar a operaciones recientes
            operation_summary['recent_operations'].append({
                'type': operation.operation_type,
                'success': operation.success,
                'date': operation.created_at.isoformat(),
                'error': operation.error_message
            })
        
        # Calcular tasa de éxito
        if len(recent_operations) > 0:
            operation_summary['success_rate'] = (successful_operations / len(recent_operations)) * 100
        
        # Procesar actividades
        activity_summary = {
            'total_activities': len(recent_activities),
            'activity_types': {},
            'recent_activities': []
        }
        
        for activity in recent_activities:
            # Contar tipos de actividades
            if activity.activity_type not in activity_summary['activity_types']:
                activity_summary['activity_types'][activity.activity_type] = 0
            activity_summary['activity_types'][activity.activity_type] += 1
            
            # Agregar a actividades recientes
            activity_summary['recent_activities'].append({
                'type': activity.activity_type,
                'page_url': activity.page_url,
                'date': activity.created_at.isoformat()
            })
        
        return {
            'user_id': user_id,
            'transactions': transaction_summary,
            'operations': operation_summary,
            'activities': activity_summary,
            'generated_at': datetime.utcnow().isoformat()
        }

# Instancia global del gestor de base de datos
db_manager = DatabaseManager()
