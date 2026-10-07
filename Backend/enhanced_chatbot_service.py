#!/usr/bin/env python3
"""
Servicio de Chatbot Mejorado con Integración de Datos del Usuario
"""

import os
import json
import logging
import requests
from typing import Dict, List, Optional
from datetime import datetime

# Configuración de logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class EnhancedChatbotService:
    def __init__(self):
        self.knowledge_base = self._load_knowledge_base()
        self.conversation_history = {}
        self.model = "enhanced-fallback"
        self.transaction_service_url = "http://localhost:5004"
        
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
    
    def _get_user_history(self, user_id: str) -> Optional[Dict]:
        """Obtener historial del usuario desde el servicio de transacciones"""
        try:
            if not user_id.isdigit():
                return None
                
            response = requests.get(
                f"{self.transaction_service_url}/history/{user_id}",
                timeout=5
            )
            
            if response.status_code == 200:
                return response.json()
            else:
                logger.warning(f"No se pudo obtener historial del usuario {user_id}: {response.status_code}")
                return None
                
        except Exception as e:
            logger.warning(f"Error obteniendo historial del usuario {user_id}: {e}")
            return None
    
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
    
    def _generate_response(self, query: str, context: List[Dict], user_history: Optional[Dict] = None) -> str:
        """Generar respuesta usando contexto y datos del usuario"""
        try:
            query_lower = query.lower()
            
            # Respuestas específicas con datos del usuario
            if "historial" in query_lower or "actividad" in query_lower or "transacciones" in query_lower:
                if user_history:
                    return self._generate_history_response(user_history)
                else:
                    return "No tengo acceso a tu historial de actividades. Para obtener información personalizada, asegúrate de estar logueado correctamente."
            
            elif "mis" in query_lower and ("operaciones" in query_lower or "transacciones" in query_lower):
                if user_history:
                    return self._generate_personal_operations_response(user_history)
                else:
                    return "Para ver tus operaciones y transacciones, necesito que estés autenticado. Por favor, inicia sesión primero."
            
            elif "estadísticas" in query_lower or "estadisticas" in query_lower:
                if user_history:
                    return self._generate_statistics_response(user_history)
                else:
                    return "Para mostrarte tus estadísticas personales, necesito acceso a tu cuenta. Por favor, inicia sesión."
            
            elif "intercambio" in query_lower or "cambiar" in query_lower:
                base_response = "El intercambio de vehículos en AlworkiAuto funciona de la siguiente manera: Primero registras tu vehículo con fotos y detalles, luego especificas qué tipo de vehículo buscas, recibes ofertas de otros usuarios interesados en intercambiar, y finalmente negocian los términos del intercambio. Es un proceso seguro y transparente."
                
                if user_history and user_history.get('transactions', {}).get('transaction_types', {}).get('exchange'):
                    exchange_count = user_history['transactions']['transaction_types']['exchange']
                    base_response += f" Veo que ya has realizado {exchange_count} intercambio(s) en nuestra plataforma."
                
                return base_response
            
            elif "comprar" in query_lower or "vender" in query_lower:
                base_response = "Para comprar o vender vehículos en AlworkiAuto: Si quieres vender, listas tu vehículo con precio y fotos detalladas. Si quieres comprar, puedes buscar entre los vehículos disponibles y hacer ofertas. Todas las transacciones son seguras y verificadas."
                
                if user_history:
                    transactions = user_history.get('transactions', {})
                    if transactions.get('total_transactions', 0) > 0:
                        total_amount = transactions.get('total_amount', 0)
                        base_response += f" Según tu historial, has realizado {transactions['total_transactions']} transacción(es) por un total de ${total_amount:,.2f}."
                
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
    
    def _generate_history_response(self, user_history: Dict) -> str:
        """Generar respuesta sobre el historial del usuario"""
        transactions = user_history.get('transactions', {})
        operations = user_history.get('operations', {})
        activities = user_history.get('activities', {})
        
        response = "Aquí tienes un resumen de tu actividad en AlworkiAuto:\n\n"
        
        # Información de transacciones
        if transactions.get('total_transactions', 0) > 0:
            response += f"📊 **Transacciones:** Has realizado {transactions['total_transactions']} transacción(es)"
            if transactions.get('total_amount', 0) > 0:
                response += f" por un total de ${transactions['total_amount']:,.2f}"
            response += ".\n"
            
            # Tipos de transacciones
            transaction_types = transactions.get('transaction_types', {})
            if transaction_types:
                response += "   - Tipos: " + ", ".join([f"{tipo} ({cantidad})" for tipo, cantidad in transaction_types.items()]) + "\n"
        else:
            response += "📊 **Transacciones:** Aún no has realizado transacciones.\n"
        
        # Información de operaciones
        if operations.get('total_operations', 0) > 0:
            success_rate = operations.get('success_rate', 0)
            response += f"⚙️ **Operaciones:** {operations['total_operations']} operaciones con {success_rate:.1f}% de éxito.\n"
        else:
            response += "⚙️ **Operaciones:** No hay operaciones registradas.\n"
        
        # Información de actividades
        if activities.get('total_activities', 0) > 0:
            response += f"🎯 **Actividades:** {activities['total_activities']} actividades registradas.\n"
        else:
            response += "🎯 **Actividades:** No hay actividades registradas.\n"
        
        return response
    
    def _generate_personal_operations_response(self, user_history: Dict) -> str:
        """Generar respuesta sobre operaciones personales del usuario"""
        transactions = user_history.get('transactions', {})
        recent_transactions = transactions.get('recent_transactions', [])
        
        if not recent_transactions:
            return "No tienes transacciones registradas aún. ¡Comienza explorando nuestros servicios de intercambio y compraventa!"
        
        response = "Aquí están tus transacciones recientes:\n\n"
        
        for i, transaction in enumerate(recent_transactions[:5], 1):
            response += f"{i}. **{transaction['type'].title()}** - "
            if transaction.get('amount'):
                response += f"${transaction['amount']:,.2f} - "
            response += f"Estado: {transaction['status']}\n"
            if transaction.get('description'):
                response += f"   Descripción: {transaction['description']}\n"
            response += f"   Fecha: {transaction['date'][:10]}\n\n"
        
        if len(recent_transactions) > 5:
            response += f"... y {len(recent_transactions) - 5} transacciones más."
        
        return response
    
    def _generate_statistics_response(self, user_history: Dict) -> str:
        """Generar respuesta con estadísticas del usuario"""
        transactions = user_history.get('transactions', {})
        operations = user_history.get('operations', {})
        
        response = "📈 **Tus estadísticas en AlworkiAuto:**\n\n"
        
        # Estadísticas de transacciones
        total_transactions = transactions.get('total_transactions', 0)
        total_amount = transactions.get('total_amount', 0)
        
        response += f"💰 **Transacciones:** {total_transactions} realizadas"
        if total_amount > 0:
            response += f" por ${total_amount:,.2f}"
        response += "\n"
        
        # Estadísticas de operaciones
        total_operations = operations.get('total_operations', 0)
        success_rate = operations.get('success_rate', 0)
        
        response += f"⚙️ **Operaciones:** {total_operations} con {success_rate:.1f}% de éxito\n"
        
        # Tipos de transacciones más comunes
        transaction_types = transactions.get('transaction_types', {})
        if transaction_types:
            most_common = max(transaction_types.items(), key=lambda x: x[1])
            response += f"🏆 **Actividad principal:** {most_common[0]} ({most_common[1]} veces)\n"
        
        return response
    
    def process_message(self, message: str, user_id: str = "default") -> Dict:
        """Procesar mensaje del usuario y generar respuesta"""
        try:
            logger.info(f"🤖 Procesando mensaje: {message}")
            
            # Obtener historial del usuario
            user_history = self._get_user_history(user_id)
            
            # Buscar en la base de conocimiento
            context = self._search_knowledge_base(message)
            
            # Generar respuesta con contexto del usuario
            response = self._generate_response(message, context, user_history)
            
            # Determinar confianza
            confidence = len(context) > 0 or user_history is not None
            
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
                "user_history_used": user_history is not None
            })
            
            # Registrar la operación de chat
            try:
                if user_id.isdigit():
                    requests.post(
                        f"{self.transaction_service_url}/operations",
                        json={
                            'user_id': int(user_id),
                            'operation_type': 'chatbot_interaction',
                            'operation_data': {
                                'message': message,
                                'response_length': len(response),
                                'confidence': confidence,
                                'sources_count': len(sources)
                            },
                            'success': True
                        },
                        timeout=5
                    )
            except Exception as e:
                logger.warning(f"⚠️ No se pudo registrar la operación de chat: {e}")
            
            return {
                "response": response,
                "confidence": confidence,
                "sources": sources,
                "context_used": len(context),
                "user_history_available": user_history is not None
            }
            
        except Exception as e:
            logger.error(f"❌ Error procesando mensaje: {e}")
            return {
                "response": "Lo siento, estoy teniendo problemas técnicos. ¿Puedes intentar de nuevo?",
                "confidence": False,
                "sources": [],
                "context_used": 0,
                "user_history_available": False
            }
    
    def get_status(self) -> str:
        """Obtener estado del chatbot"""
        return "online"
    
    def initialize(self) -> bool:
        """Inicializar el chatbot"""
        try:
            logger.info("🤖 Inicializando chatbot mejorado...")
            logger.info("✅ Chatbot inicializado correctamente")
            return True
        except Exception as e:
            logger.error(f"❌ Error en inicialización: {e}")
            return False

# Instancia global del servicio
enhanced_chatbot_service = EnhancedChatbotService()
