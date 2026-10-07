#!/usr/bin/env python3
"""
Servicio de Chatbot Mejorado - Versión Simple
Integra datos de operación y transacción con la historia técnica
"""

import os
import json
import logging
import requests
from typing import Dict, List, Optional
from datetime import datetime, timedelta
import random

# Configuración de logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class EnhancedChatbotSimple:
    def __init__(self):
        self.knowledge_base = self._load_knowledge_base()
        self.conversation_history = {}
        self.model = "enhanced-simple"
        
        # Simulación de datos de usuario (en producción vendría de la base de datos)
        self.user_data_simulation = {
            "1": {
                "transactions": [
                    {"type": "buy", "amount": 15000, "date": "2024-01-15", "status": "completed", "description": "Compra de Honda Civic 2020"},
                    {"type": "sell", "amount": 12000, "date": "2024-01-10", "status": "completed", "description": "Venta de Toyota Corolla 2019"},
                    {"type": "exchange", "amount": 8000, "date": "2024-01-05", "status": "pending", "description": "Intercambio de motocicleta"}
                ],
                "operations": [
                    {"type": "login", "date": "2024-01-20", "success": True},
                    {"type": "profile_update", "date": "2024-01-18", "success": True},
                    {"type": "vehicle_search", "date": "2024-01-16", "success": True},
                    {"type": "contact_seller", "date": "2024-01-14", "success": True}
                ],
                "activities": [
                    {"type": "page_view", "page": "/dashboard", "date": "2024-01-20"},
                    {"type": "button_click", "page": "/search", "action": "search_vehicles", "date": "2024-01-19"},
                    {"type": "form_submit", "page": "/vehicle/VEH001", "form": "contact_seller", "date": "2024-01-18"}
                ]
            }
        }
        
    def _load_knowledge_base(self) -> Dict:
        """Cargar base de conocimiento sobre AlworkiAuto"""
        return {
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
                }
            },
            "support": {
                "contact": {
                    "email": "soporte@alworkiauto.com",
                    "phone": "+1-800-ALWORKI",
                    "hours": "Lunes a Viernes 9:00 AM - 6:00 PM"
                }
            }
        }
    
    def _get_user_data(self, user_id: str) -> Optional[Dict]:
        """Obtener datos del usuario (simulado)"""
        try:
            if user_id in self.user_data_simulation:
                return self.user_data_simulation[user_id]
            else:
                # Generar datos simulados para usuarios nuevos
                return self._generate_simulated_user_data(user_id)
        except Exception as e:
            logger.warning(f"Error obteniendo datos del usuario {user_id}: {e}")
            return None
    
    def _generate_simulated_user_data(self, user_id: str) -> Dict:
        """Generar datos simulados para un usuario"""
        # Simular algunas transacciones aleatorias
        transaction_types = ["buy", "sell", "exchange"]
        transactions = []
        
        for i in range(random.randint(0, 3)):
            transaction_type = random.choice(transaction_types)
            amount = random.randint(5000, 25000)
            date = (datetime.now() - timedelta(days=random.randint(1, 30))).strftime("%Y-%m-%d")
            
            transactions.append({
                "type": transaction_type,
                "amount": amount,
                "date": date,
                "status": random.choice(["completed", "pending", "cancelled"]),
                "description": f"{transaction_type.title()} de vehículo"
            })
        
        # Simular operaciones
        operation_types = ["login", "profile_update", "vehicle_search", "contact_seller", "upload_photo"]
        operations = []
        
        for i in range(random.randint(2, 8)):
            operation_type = random.choice(operation_types)
            date = (datetime.now() - timedelta(days=random.randint(1, 15))).strftime("%Y-%m-%d")
            
            operations.append({
                "type": operation_type,
                "date": date,
                "success": random.choice([True, True, True, False])  # 75% éxito
            })
        
        # Simular actividades
        activity_types = ["page_view", "button_click", "form_submit", "file_upload"]
        activities = []
        
        for i in range(random.randint(5, 15)):
            activity_type = random.choice(activity_types)
            date = (datetime.now() - timedelta(days=random.randint(1, 10))).strftime("%Y-%m-%d")
            
            activities.append({
                "type": activity_type,
                "page": random.choice(["/dashboard", "/search", "/profile", "/vehicles"]),
                "action": f"action_{i}",
                "date": date
            })
        
        user_data = {
            "transactions": transactions,
            "operations": operations,
            "activities": activities
        }
        
        # Guardar para futuras consultas
        self.user_data_simulation[user_id] = user_data
        return user_data
    
    def _search_knowledge_base(self, query: str) -> List[Dict]:
        """Buscar en la base de conocimiento"""
        try:
            query_lower = query.lower()
            relevant_info = []
            
            # Buscar en diferentes secciones
            for section, content in self.knowledge_base.items():
                if isinstance(content, dict):
                    for key, value in content.items():
                        if isinstance(value, dict):
                            for subkey, subvalue in value.items():
                                if isinstance(subvalue, str) and query_lower in subvalue.lower():
                                    relevant_info.append({
                                        "section": f"{section}.{key}.{subkey}",
                                        "content": subvalue,
                                        "relevance": 0.8
                                    })
                                elif isinstance(subvalue, list):
                                    for item in subvalue:
                                        if isinstance(item, str) and query_lower in item.lower():
                                            relevant_info.append({
                                                "section": f"{section}.{key}.{subkey}",
                                                "content": item,
                                                "relevance": 0.7
                                            })
            
            # Ordenar por relevancia
            relevant_info.sort(key=lambda x: x["relevance"], reverse=True)
            return relevant_info[:3]  # Top 3 resultados
            
        except Exception as e:
            logger.error(f"❌ Error en búsqueda: {e}")
            return []
    
    def _generate_response(self, query: str, context: List[Dict], user_data: Optional[Dict] = None) -> str:
        """Generar respuesta usando contexto y datos del usuario"""
        try:
            query_lower = query.lower()
            
            # Respuestas específicas con datos del usuario
            if "historial" in query_lower or "actividad" in query_lower or "transacciones" in query_lower:
                if user_data:
                    return self._generate_history_response(user_data)
                else:
                    return "No tengo acceso a tu historial de actividades. Para obtener información personalizada, asegúrate de estar logueado correctamente."
            
            elif "mis" in query_lower and ("operaciones" in query_lower or "transacciones" in query_lower):
                if user_data:
                    return self._generate_personal_operations_response(user_data)
                else:
                    return "Para ver tus operaciones y transacciones, necesito que estés autenticado. Por favor, inicia sesión primero."
            
            elif "estadísticas" in query_lower or "estadisticas" in query_lower:
                if user_data:
                    return self._generate_statistics_response(user_data)
                else:
                    return "Para mostrarte tus estadísticas personales, necesito acceso a tu cuenta. Por favor, inicia sesión."
            
            elif "intercambio" in query_lower or "cambiar" in query_lower:
                base_response = "El intercambio de vehículos en AlworkiAuto funciona de la siguiente manera: Primero registras tu vehículo con fotos y detalles, luego especificas qué tipo de vehículo buscas, recibes ofertas de otros usuarios interesados en intercambiar, y finalmente negocian los términos del intercambio. Es un proceso seguro y transparente."
                
                if user_data:
                    exchange_count = sum(1 for t in user_data.get('transactions', []) if t['type'] == 'exchange')
                    if exchange_count > 0:
                        base_response += f" Veo que ya has realizado {exchange_count} intercambio(s) en nuestra plataforma."
                
                return base_response
            
            elif "comprar" in query_lower or "vender" in query_lower:
                base_response = "Para comprar o vender vehículos en AlworkiAuto: Si quieres vender, listas tu vehículo con precio y fotos detalladas. Si quieres comprar, puedes buscar entre los vehículos disponibles y hacer ofertas. Todas las transacciones son seguras y verificadas."
                
                if user_data:
                    transactions = user_data.get('transactions', [])
                    if transactions:
                        total_amount = sum(t.get('amount', 0) for t in transactions)
                        base_response += f" Según tu historial, has realizado {len(transactions)} transacción(es) por un total de ${total_amount:,.2f}."
                
                return base_response
            
            elif "cuenta" in query_lower or "registro" in query_lower:
                return "Para crear una cuenta en AlworkiAuto: 1) Ve a la página de registro, 2) Completa tu información personal, 3) Verifica tu email, 4) Sube los documentos requeridos (identificación, licencia, documentos del vehículo), 5) Completa tu perfil con foto. El proceso es rápido y seguro."
            
            elif "evaluación" in query_lower or "valor" in query_lower:
                return "La evaluación de vehículos incluye una inspección técnica completa, valoración de mercado basada en datos actuales, y un reporte detallado con el estado del vehículo y su valor estimado. Esto te ayuda a establecer un precio justo."
            
            elif "soporte" in query_lower or "ayuda" in query_lower:
                return "Nuestro equipo de soporte está disponible de lunes a viernes de 9:00 AM a 6:00 PM. Puedes contactarnos por email a soporte@alworkiauto.com o llamar al +1-800-ALWORKI. También tenemos una sección de FAQ con preguntas comunes."
            
            elif "alworki" in query_lower or "plataforma" in query_lower:
                return "AlworkiAuto es una plataforma innovadora para el intercambio y compraventa de vehículos. Ofrecemos un sistema seguro, transparente y fácil de usar donde puedes intercambiar tu vehículo, comprar o vender con confianza."
            
            else:
                # Respuesta general con contexto
                if context:
                    context_text = " ".join([item["content"] for item in context[:2]])
                    return f"Basándome en la información disponible: {context_text}. ¿Hay algo específico sobre AlworkiAuto que te gustaría saber?"
                else:
                    return "Hola! Soy el asistente de AlworkiAuto. Puedo ayudarte con información sobre intercambios, compraventa, evaluación de vehículos, creación de cuentas y más. ¿En qué puedo ayudarte?"
            
        except Exception as e:
            logger.error(f"❌ Error generando respuesta: {e}")
            return "Lo siento, estoy teniendo problemas técnicos. ¿Puedes intentar de nuevo?"
    
    def _generate_history_response(self, user_data: Dict) -> str:
        """Generar respuesta sobre el historial del usuario"""
        transactions = user_data.get('transactions', [])
        operations = user_data.get('operations', [])
        activities = user_data.get('activities', [])
        
        response = "Aquí tienes un resumen de tu actividad en AlworkiAuto:\n\n"
        
        # Información de transacciones
        if transactions:
            total_amount = sum(t.get('amount', 0) for t in transactions)
            response += f"📊 **Transacciones:** Has realizado {len(transactions)} transacción(es)"
            if total_amount > 0:
                response += f" por un total de ${total_amount:,.2f}"
            response += ".\n"
            
            # Tipos de transacciones
            transaction_types = {}
            for t in transactions:
                transaction_types[t['type']] = transaction_types.get(t['type'], 0) + 1
            
            if transaction_types:
                response += "   - Tipos: " + ", ".join([f"{tipo} ({cantidad})" for tipo, cantidad in transaction_types.items()]) + "\n"
        else:
            response += "📊 **Transacciones:** Aún no has realizado transacciones.\n"
        
        # Información de operaciones
        if operations:
            successful_ops = sum(1 for op in operations if op.get('success', False))
            success_rate = (successful_ops / len(operations)) * 100 if operations else 0
            response += f"⚙️ **Operaciones:** {len(operations)} operaciones con {success_rate:.1f}% de éxito.\n"
        else:
            response += "⚙️ **Operaciones:** No hay operaciones registradas.\n"
        
        # Información de actividades
        if activities:
            response += f"🎯 **Actividades:** {len(activities)} actividades registradas.\n"
        else:
            response += "🎯 **Actividades:** No hay actividades registradas.\n"
        
        return response
    
    def _generate_personal_operations_response(self, user_data: Dict) -> str:
        """Generar respuesta sobre operaciones personales del usuario"""
        transactions = user_data.get('transactions', [])
        
        if not transactions:
            return "No tienes transacciones registradas aún. ¡Comienza explorando nuestros servicios de intercambio y compraventa!"
        
        response = "Aquí están tus transacciones recientes:\n\n"
        
        # Ordenar por fecha (más recientes primero)
        sorted_transactions = sorted(transactions, key=lambda x: x.get('date', ''), reverse=True)
        
        for i, transaction in enumerate(sorted_transactions[:5], 1):
            response += f"{i}. **{transaction['type'].title()}** - "
            if transaction.get('amount'):
                response += f"${transaction['amount']:,.2f} - "
            response += f"Estado: {transaction['status']}\n"
            if transaction.get('description'):
                response += f"   Descripción: {transaction['description']}\n"
            response += f"   Fecha: {transaction.get('date', 'N/A')}\n\n"
        
        if len(transactions) > 5:
            response += f"... y {len(transactions) - 5} transacciones más."
        
        return response
    
    def _generate_statistics_response(self, user_data: Dict) -> str:
        """Generar respuesta con estadísticas del usuario"""
        transactions = user_data.get('transactions', [])
        operations = user_data.get('operations', [])
        
        response = "📈 **Tus estadísticas en AlworkiAuto:**\n\n"
        
        # Estadísticas de transacciones
        total_transactions = len(transactions)
        total_amount = sum(t.get('amount', 0) for t in transactions)
        
        response += f"💰 **Transacciones:** {total_transactions} realizadas"
        if total_amount > 0:
            response += f" por ${total_amount:,.2f}"
        response += "\n"
        
        # Estadísticas de operaciones
        total_operations = len(operations)
        successful_ops = sum(1 for op in operations if op.get('success', False))
        success_rate = (successful_ops / total_operations) * 100 if total_operations else 0
        
        response += f"⚙️ **Operaciones:** {total_operations} con {success_rate:.1f}% de éxito\n"
        
        # Tipos de transacciones más comunes
        transaction_types = {}
        for t in transactions:
            transaction_types[t['type']] = transaction_types.get(t['type'], 0) + 1
        
        if transaction_types:
            most_common = max(transaction_types.items(), key=lambda x: x[1])
            response += f"🏆 **Actividad principal:** {most_common[0]} ({most_common[1]} veces)\n"
        
        return response
    
    def process_message(self, message: str, user_id: str = "default") -> Dict:
        """Procesar mensaje del usuario y generar respuesta"""
        try:
            logger.info(f"🤖 Procesando mensaje: {message}")
            
            # Obtener datos del usuario
            user_data = self._get_user_data(user_id)
            
            # Buscar en la base de conocimiento
            context = self._search_knowledge_base(message)
            
            # Generar respuesta con contexto del usuario
            response = self._generate_response(message, context, user_data)
            
            # Determinar confianza
            confidence = len(context) > 0 or user_data is not None
            
            # Extraer fuentes
            sources = [item["section"] for item in context[:2]]
            
            # Guardar en historial de conversación
            if user_id not in self.conversation_history:
                self.conversation_history[user_id] = []
            
            self.conversation_history[user_id].append({
                "timestamp": datetime.now().isoformat(),
                "user_message": message,
                "bot_response": response,
                "context_used": context,
                "user_data_used": user_data is not None
            })
            
            return {
                "response": response,
                "confidence": confidence,
                "sources": sources,
                "context_used": len(context),
                "user_data_available": user_data is not None
            }
            
        except Exception as e:
            logger.error(f"❌ Error procesando mensaje: {e}")
            return {
                "response": "Lo siento, estoy teniendo problemas técnicos. ¿Puedes intentar de nuevo?",
                "confidence": False,
                "sources": [],
                "context_used": 0,
                "user_data_available": False
            }
    
    def get_status(self) -> str:
        """Obtener estado del chatbot"""
        return "online"
    
    def initialize(self) -> bool:
        """Inicializar el chatbot"""
        try:
            logger.info("🤖 Inicializando chatbot mejorado simple...")
            logger.info("✅ Chatbot inicializado correctamente")
            return True
        except Exception as e:
            logger.error(f"❌ Error en inicialización: {e}")
            return False

# Instancia global del servicio
enhanced_chatbot_simple = EnhancedChatbotSimple()
