"""
Microservicio de Tarjetas
"""

from flask import Flask, jsonify, request
from flask_cors import CORS
import sys
import os

# Agregar el directorio raíz al path para importar módulos
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from config.config import config

def create_cards_service():
    """Crear y configurar el servicio de tarjetas"""
    
    app = Flask(__name__)
    
    # Configuración del servicio
    service_config = config.get_service_config('cards')
    
    # Configuración de CORS
    CORS(app, resources={
        r"/*": {
            "origins": service_config.cors_origins,
            "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
            "allow_headers": ["Content-Type", "Authorization"]
        }
    })
    
    # Datos de tarjetas (en un caso real, esto vendría de una base de datos)
    CARDS_DATA = [
        {
            "id": 1,
            "title": "Carpintero/a",
            "description": "Fabricación y reparación de muebles y estructuras de madera. Servicios a domicilio para proyectos personalizados.",
            "last_updated": "25 trabajadores cerca de ti",
            "image_url": "1.svg"
        },
        {
            "id": 2,
            "title": "Cocinero/a",
            "description": "Preparación de comidas caseras, catering para eventos y servicios de chef a domicilio.",
            "last_updated": "30 trabajadores cerca de ti",
            "image_url": "2.svg"
        },
        {
            "id": 3,
            "title": "Jardinero/a",
            "description": "Diseño, mantenimiento y cuidado de jardines. Servicios de poda, siembra y paisajismo.",
            "last_updated": "20 trabajadores cerca de ti",
            "image_url": "3.svg"
        },
        {
            "id": 4,
            "title": "Mecánico/a",
            "description": "Reparación y mantenimiento de vehículos. Servicio a domicilio para diagnósticos y reparaciones menores.",
            "last_updated": "15 trabajadores cerca de ti",
            "image_url": "4.png"
        },
        {
            "id": 5,
            "title": "Lavandero/a",
            "description": "Lavado y planchado de ropa. Servicio de recogida y entrega a domicilio.",
            "last_updated": "10 trabajadores cerca de ti",
            "image_url": "https://berrydashboard.io/vue/assets/background1-24822d62.png"
        },
        {
            "id": 6,
            "title": "Artesano/a",
            "description": "Creación de productos artesanales como cerámica, joyería y textiles. Pedidos personalizados y envíos a domicilio.",
            "last_updated": "12 trabajadores cerca de ti",
            "image_url": "https://berrydashboard.io/vue/assets/background1-24822d62.png"
        },
        {
            "id": 7,
            "title": "Pintor/a",
            "description": "Pintura de interiores y exteriores. Servicios de diseño y decoración a domicilio.",
            "last_updated": "18 trabajadores cerca de ti",
            "image_url": "https://berrydashboard.io/vue/assets/background1-24822d62.png"
        },
        {
            "id": 8,
            "title": "Albañil",
            "description": "Construcción y reparación de estructuras. Servicios de remodelación y mantenimiento a domicilio.",
            "last_updated": "22 trabajadores cerca de ti",
            "image_url": "https://berrydashboard.io/vue/assets/background1-24822d62.png"
        },
        {
            "id": 9,
            "title": "Sastre",
            "description": "Confección y ajuste de prendas de vestir. Servicios de costura y reparación a domicilio.",
            "last_updated": "8 trabajadores cerca de ti",
            "image_url": "https://berrydashboard.io/vue/assets/background1-24822d62.png"
        },
        {
            "id": 10,
            "title": "Peluquero/a",
            "description": "Cortes de cabello, tintes y tratamientos capilares. Servicio a domicilio para mayor comodidad.",
            "last_updated": "14 trabajadores cerca de ti",
            "image_url": "https://berrydashboard.io/vue/assets/background1-24822d62.png"
        },
        {
            "id": 11,
            "title": "Chofer",
            "description": "Servicio de transporte privado. Viajes seguros y puntuales a cualquier destino.",
            "last_updated": "25 trabajadores cerca de ti",
            "image_url": "https://berrydashboard.io/vue/assets/background1-24822d62.png"
        },
        {
            "id": 12,
            "title": "Repartidor/a",
            "description": "Entrega de paquetes, comida y productos. Servicio rápido y confiable.",
            "last_updated": "35 trabajadores cerca de ti",
            "image_url": "https://berrydashboard.io/vue/assets/background1-24822d62.png"
        },
        {
            "id": 13,
            "title": "Animador/a",
            "description": "Animación para eventos infantiles, fiestas y reuniones. Servicios personalizados.",
            "last_updated": "7 trabajadores cerca de ti",
            "image_url": "https://berrydashboard.io/vue/assets/background1-24822d62.png"
        },
        {
            "id": 14,
            "title": "Abogado/a",
            "description": "Asesoría legal en áreas civiles, laborales, familiares y más. Consultas remotas o presenciales.",
            "last_updated": "10 trabajadores cerca de ti",
            "image_url": "https://berrydashboard.io/vue/assets/background1-24822d62.png"
        },
        {
            "id": 15,
            "title": "Médico/a",
            "description": "Consultas médicas generales y especializadas. Servicio a domicilio o telemedicina.",
            "last_updated": "20 trabajadores cerca de ti",
            "image_url": "https://berrydashboard.io/vue/assets/background1-24822d62.png"
        },
        {
            "id": 16,
            "title": "Ingeniero/a",
            "description": "Diseño, planificación y supervisión de proyectos. Consultoría remota o presencial.",
            "last_updated": "15 trabajadores cerca de ti",
            "image_url": "https://berrydashboard.io/vue/assets/background1-24822d62.png"
        },
        {
            "id": 17,
            "title": "Arquitecto/a",
            "description": "Diseño de planos y supervisión de obras. Servicios de consultoría a domicilio o remotos.",
            "last_updated": "12 trabajadores cerca de ti",
            "image_url": "https://berrydashboard.io/vue/assets/background1-24822d62.png"
        },
        {
            "id": 18,
            "title": "Psicólogo/a",
            "description": "Terapia psicológica para adultos, adolescentes y niños. Sesiones presenciales o en línea.",
            "last_updated": "18 trabajadores cerca de ti",
            "image_url": "https://berrydashboard.io/vue/assets/background1-24822d62.png"
        },
        {
            "id": 19,
            "title": "Diseñador/a gráfico",
            "description": "Creación de logotipos, banners y material publicitario. Trabajo remoto con entregas digitales.",
            "last_updated": "25 trabajadores cerca de ti",
            "image_url": "https://berrydashboard.io/vue/assets/background1-24822d62.png"
        },
        {
            "id": 20,
            "title": "Traductor/a",
            "description": "Traducción de documentos y textos. Servicios remotos con entrega digital.",
            "last_updated": "10 trabajadores cerca de ti",
            "image_url": "https://berrydashboard.io/vue/assets/background1-24822d62.png"
        },
        {
            "id": 21,
            "title": "Desarrollador/a web",
            "description": "Creación de sitios web y aplicaciones. Trabajo remoto con entregas digitales.",
            "last_updated": "30 trabajadores cerca de ti",
            "image_url": "https://berrydashboard.io/vue/assets/background1-24822d62.png"
        },
        {
            "id": 22,
            "title": "Contador/a",
            "description": "Asesoría fiscal, contable y financiera. Servicios presenciales o remotos.",
            "last_updated": "15 trabajadores cerca de ti",
            "image_url": "https://berrydashboard.io/vue/assets/background1-24822d62.png"
        },
        {
            "id": 23,
            "title": "Profesor/a",
            "description": "Clases particulares o grupales en diversas materias. Modalidad presencial o en línea.",
            "last_updated": "20 trabajadores cerca de ti",
            "image_url": "https://berrydashboard.io/vue/assets/background1-24822d62.png"
        },
        {
            "id": 24,
            "title": "Servicio de limpieza",
            "description": "Limpieza profunda de hogares, oficinas y espacios comerciales. Servicios flexibles y adaptados a tus horarios.",
            "last_updated": "30 trabajadores cerca de ti",
            "image_url": "https://berrydashboard.io/vue/assets/background1-24822d62.png"
        },
        {
            "id": 25,
            "title": "Veterinarios",
            "description": "Atención veterinaria a domicilio para tus mascotas. Consultas, vacunación, cuidados preventivos y tratamientos especializados.",
            "last_updated": "37 trabajadores cerca de ti",
            "image_url": "https://berrydashboard.io/vue/assets/background1-24822d62.png"
        },
        {
            "id": 26,
            "title": "Enfermería",
            "description": "Cuidados de enfermería a domicilio para pacientes postoperatorios, ancianos o personas con necesidades especiales. Servicios profesionales y compasivos.",
            "last_updated": "24 trabajadores cerca de ti",
            "image_url": "https://berrydashboard.io/vue/assets/background1-24822d62.png"
        },
        {
            "id": 27,
            "title": "Servicio de catering",
            "description": "Catering para eventos sociales y corporativos. Menús personalizados y entrega a domicilio.",
            "last_updated": "16 trabajadores cerca de ti",
            "image_url": "https://berrydashboard.io/vue/assets/background1-24822d62.png"
        }
    ]
    
    @app.route('/api/cards', methods=['GET'])
    def get_cards():
        """Obtener todas las tarjetas"""
        return jsonify(CARDS_DATA)
    
    @app.route('/api/cards/<int:card_id>', methods=['GET'])
    def get_card(card_id):
        """Obtener una tarjeta específica por ID"""
        card = next((card for card in CARDS_DATA if card['id'] == card_id), None)
        if card:
            return jsonify(card)
        else:
            return jsonify({'error': 'Tarjeta no encontrada'}), 404
    
    @app.route('/api/cards/search', methods=['GET'])
    def search_cards():
        """Buscar tarjetas por título o descripción"""
        query = request.args.get('q', '').lower()
        if not query:
            return jsonify(CARDS_DATA)
        
        filtered_cards = [
            card for card in CARDS_DATA 
            if query in card['title'].lower() or query in card['description'].lower()
        ]
        
        return jsonify(filtered_cards)
    
    @app.route('/api/cards/category/<category>', methods=['GET'])
    def get_cards_by_category(category):
        """Obtener tarjetas por categoría (ejemplo básico)"""
        # En un caso real, las tarjetas tendrían un campo category
        # Por ahora, devolvemos todas las tarjetas
        return jsonify(CARDS_DATA)
    
    @app.route('/health', methods=['GET'])
    def health_check():
        """Endpoint de health check"""
        return jsonify({
            'status': 'OK', 
            'service': 'cards-service',
            'message': 'Servicio de tarjetas funcionando correctamente',
            'total_cards': len(CARDS_DATA)
        }), 200
    
    return app

def run_cards_service():
    """Ejecutar el servicio de tarjetas"""
    app = create_cards_service()
    service_config = config.get_service_config('cards')
    
    print(f"🚀 Iniciando servicio de tarjetas en http://{service_config.host}:{service_config.port}")
    
    app.run(
        host=service_config.host,
        port=service_config.port,
        debug=service_config.debug
    )

if __name__ == '__main__':
    run_cards_service()
