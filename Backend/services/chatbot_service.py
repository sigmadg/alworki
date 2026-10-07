#!/usr/bin/env python3
"""
Servicio de Chatbot con LLM y RAG
"""

import os
import json
import logging
from typing import Dict, List, Optional, Tuple
import numpy as np
from datetime import datetime

# Configuración de logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ChatbotService:
    def __init__(self):
        self.knowledge_base = self._load_knowledge_base()
        self.conversation_history = {}
        self.model = None
        self.embeddings = None
        self.vector_index = None
        self._initialize_models()
    
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
    
    def _initialize_models(self):
        """Inicializar modelos de IA (simulado por ahora)"""
        try:
            logger.info("🤖 Inicializando modelos de IA...")
            
            # Simulación de modelos - en producción usarías modelos reales
            self.model = "gemma-3-3b-simulated"
            self.embeddings = "sentence-transformers-simulated"
            self.vector_index = "faiss-simulated"
            
            logger.info("✅ Modelos inicializados correctamente")
            
        except Exception as e:
            logger.error(f"❌ Error inicializando modelos: {e}")
            # Fallback a respuestas predefinidas
            self.model = "fallback"
    
    def _search_knowledge_base(self, query: str) -> List[Dict]:
        """Buscar en la base de conocimiento usando RAG"""
        try:
            # Simulación de búsqueda semántica
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
    
    def _generate_response(self, query: str, context: List[Dict]) -> str:
        """Generar respuesta usando LLM y contexto RAG"""
        try:
            if self.model == "fallback":
                return self._fallback_response(query, context)
            
            # Simulación de generación con LLM
            query_lower = query.lower()
            
            # Respuestas predefinidas basadas en el contexto
            if "intercambio" in query_lower or "cambiar" in query_lower:
                return "El intercambio de vehículos en AlworkiAuto funciona de la siguiente manera: Primero registras tu vehículo con fotos y detalles, luego especificas qué tipo de vehículo buscas, recibes ofertas de otros usuarios interesados en intercambiar, y finalmente negocian los términos del intercambio. Es un proceso seguro y transparente."
            
            elif "comprar" in query_lower or "vender" in query_lower:
                return "Para comprar o vender vehículos en AlworkiAuto: Si quieres vender, listas tu vehículo con precio y fotos detalladas. Si quieres comprar, puedes buscar entre los vehículos disponibles y hacer ofertas. Todas las transacciones son seguras y verificadas."
            
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
    
    def _fallback_response(self, query: str, context: List[Dict]) -> str:
        """Respuesta de fallback cuando los modelos no están disponibles"""
        query_lower = query.lower()
        
        if "hola" in query_lower or "buenos" in query_lower:
            return "¡Hola! Soy el asistente de AlworkiAuto. ¿En qué puedo ayudarte?"
        
        elif "gracias" in query_lower:
            return "¡De nada! Estoy aquí para ayudarte. ¿Hay algo más en lo que pueda asistirte?"
        
        else:
            return "Entiendo tu consulta. Te recomiendo contactar directamente con nuestro equipo de soporte en soporte@alworkiauto.com para obtener la mejor asistencia."
    
    def process_message(self, message: str, user_id: str = "default") -> Dict:
        """Procesar mensaje del usuario y generar respuesta"""
        try:
            logger.info(f"🤖 Procesando mensaje: {message}")
            
            # Buscar en la base de conocimiento
            context = self._search_knowledge_base(message)
            
            # Generar respuesta
            response = self._generate_response(message, context)
            
            # Determinar confianza
            confidence = len(context) > 0 or self.model != "fallback"
            
            # Extraer fuentes
            sources = [item["section"] for item in context[:2]]
            
            # Guardar en historial
            if user_id not in self.conversation_history:
                self.conversation_history[user_id] = []
            
            self.conversation_history[user_id].append({
                "timestamp": datetime.now().isoformat(),
                "user_message": message,
                "bot_response": response,
                "context_used": context
            })
            
            return {
                "response": response,
                "confidence": confidence,
                "sources": sources,
                "context_used": len(context)
            }
            
        except Exception as e:
            logger.error(f"❌ Error procesando mensaje: {e}")
            return {
                "response": "Lo siento, estoy teniendo problemas técnicos. ¿Puedes intentar de nuevo?",
                "confidence": False,
                "sources": [],
                "context_used": 0
            }
    
    def get_status(self) -> str:
        """Obtener estado del chatbot"""
        if self.model and self.model != "fallback":
            return "online"
        else:
            return "fallback"
    
    def initialize(self) -> bool:
        """Inicializar el chatbot"""
        try:
            self._initialize_models()
            return True
        except Exception as e:
            logger.error(f"❌ Error en inicialización: {e}")
            return False

# Instancia global del servicio
chatbot_service = ChatbotService()
