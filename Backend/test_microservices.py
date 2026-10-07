#!/usr/bin/env python3
"""
Script de pruebas para verificar todos los microservicios
"""

import requests
import time
import json
from typing import Dict, Any

# Configuración de servicios
SERVICES = {
    'auth': 'http://localhost:5000',
    'cards': 'http://localhost:5001',
    'api': 'http://localhost:5002'
}

def test_service_health(service_name: str, base_url: str) -> bool:
    """Probar el health check de un servicio"""
    print(f"🔍 Probando health check de {service_name}...")
    
    try:
        response = requests.get(f"{base_url}/health", timeout=10)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ {service_name} - {data.get('message', 'OK')}")
            return True
        else:
            print(f"❌ {service_name} - Error {response.status_code}")
            return False
    except requests.exceptions.ConnectionError:
        print(f"❌ {service_name} - No se puede conectar")
        return False
    except Exception as e:
        print(f"❌ {service_name} - Error: {e}")
        return False

def test_auth_service(base_url: str) -> Dict[str, Any]:
    """Probar el servicio de autenticación"""
    print("\n🔐 Probando servicio de autenticación...")
    results = {}
    
    # Test 1: Registro
    print("  📝 Probando registro...")
    try:
        response = requests.post(f"{base_url}/register", json={
            'firstname': 'Test',
            'lastname': 'User',
            'email': 'test@example.com',
            'password': 'test123'
        }, timeout=10)
        
        if response.status_code in [201, 400]:  # 400 si el usuario ya existe
            print("  ✅ Registro funcionando")
            results['register'] = True
        else:
            print(f"  ❌ Error en registro: {response.status_code}")
            results['register'] = False
    except Exception as e:
        print(f"  ❌ Error en registro: {e}")
        results['register'] = False
    
    # Test 2: Login
    print("  🔑 Probando login...")
    try:
        response = requests.post(f"{base_url}/login", json={
            'email': 'test@example.com',
            'password': 'test123'
        }, timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            session_id = data.get('session_id')
            print("  ✅ Login exitoso")
            results['login'] = True
            results['session_id'] = session_id
        else:
            print(f"  ❌ Error en login: {response.status_code}")
            results['login'] = False
    except Exception as e:
        print(f"  ❌ Error en login: {e}")
        results['login'] = False
    
    # Test 3: Verificación de sesión
    if results.get('session_id'):
        print("  🔍 Probando verificación de sesión...")
        try:
            headers = {'Authorization': f'Bearer {results["session_id"]}'}
            response = requests.get(f"{base_url}/verify-session", headers=headers, timeout=10)
            
            if response.status_code == 200:
                print("  ✅ Verificación de sesión exitosa")
                results['verify_session'] = True
            else:
                print(f"  ❌ Error en verificación: {response.status_code}")
                results['verify_session'] = False
        except Exception as e:
            print(f"  ❌ Error en verificación: {e}")
            results['verify_session'] = False
    
    return results

def test_cards_service(base_url: str) -> Dict[str, Any]:
    """Probar el servicio de tarjetas"""
    print("\n🃏 Probando servicio de tarjetas...")
    results = {}
    
    # Test 1: Obtener todas las tarjetas
    print("  📋 Probando obtención de tarjetas...")
    try:
        response = requests.get(f"{base_url}/api/cards", timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            print(f"  ✅ Tarjetas obtenidas: {len(data)} tarjetas")
            results['get_cards'] = True
            results['total_cards'] = len(data)
        else:
            print(f"  ❌ Error obteniendo tarjetas: {response.status_code}")
            results['get_cards'] = False
    except Exception as e:
        print(f"  ❌ Error obteniendo tarjetas: {e}")
        results['get_cards'] = False
    
    # Test 2: Obtener tarjeta específica
    print("  🔍 Probando obtención de tarjeta específica...")
    try:
        response = requests.get(f"{base_url}/api/cards/1", timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            print(f"  ✅ Tarjeta obtenida: {data.get('title', 'Sin título')}")
            results['get_card'] = True
        else:
            print(f"  ❌ Error obteniendo tarjeta: {response.status_code}")
            results['get_card'] = False
    except Exception as e:
        print(f"  ❌ Error obteniendo tarjeta: {e}")
        results['get_card'] = False
    
    # Test 3: Búsqueda de tarjetas
    print("  🔎 Probando búsqueda de tarjetas...")
    try:
        response = requests.get(f"{base_url}/api/cards/search?q=carpintero", timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            print(f"  ✅ Búsqueda exitosa: {len(data)} resultados")
            results['search_cards'] = True
        else:
            print(f"  ❌ Error en búsqueda: {response.status_code}")
            results['search_cards'] = False
    except Exception as e:
        print(f"  ❌ Error en búsqueda: {e}")
        results['search_cards'] = False
    
    return results

def test_api_gateway(base_url: str) -> Dict[str, Any]:
    """Probar el API Gateway"""
    print("\n🌐 Probando API Gateway...")
    results = {}
    
    # Test 1: Ruta raíz
    print("  🏠 Probando ruta raíz...")
    try:
        response = requests.get(f"{base_url}/", timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            print(f"  ✅ API Gateway funcionando: {data.get('message', 'OK')}")
            results['root'] = True
        else:
            print(f"  ❌ Error en ruta raíz: {response.status_code}")
            results['root'] = False
    except Exception as e:
        print(f"  ❌ Error en ruta raíz: {e}")
        results['root'] = False
    
    # Test 2: Health check del gateway
    print("  💓 Probando health check del gateway...")
    try:
        response = requests.get(f"{base_url}/health", timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            services_status = data.get('services', {})
            print(f"  ✅ Gateway health check: {len(services_status)} servicios monitoreados")
            results['health'] = True
            results['services_status'] = services_status
        else:
            print(f"  ❌ Error en health check: {response.status_code}")
            results['health'] = False
    except Exception as e:
        print(f"  ❌ Error en health check: {e}")
        results['health'] = False
    
    # Test 3: Proxy de autenticación
    print("  🔐 Probando proxy de autenticación...")
    try:
        response = requests.post(f"{base_url}/login", json={
            'email': 'test@example.com',
            'password': 'test123'
        }, timeout=10)
        
        if response.status_code == 200:
            print("  ✅ Proxy de autenticación funcionando")
            results['auth_proxy'] = True
        else:
            print(f"  ❌ Error en proxy de autenticación: {response.status_code}")
            results['auth_proxy'] = False
    except Exception as e:
        print(f"  ❌ Error en proxy de autenticación: {e}")
        results['auth_proxy'] = False
    
    # Test 4: Proxy de tarjetas
    print("  🃏 Probando proxy de tarjetas...")
    try:
        response = requests.get(f"{base_url}/api/cards", timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            print(f"  ✅ Proxy de tarjetas funcionando: {len(data)} tarjetas")
            results['cards_proxy'] = True
        else:
            print(f"  ❌ Error en proxy de tarjetas: {response.status_code}")
            results['cards_proxy'] = False
    except Exception as e:
        print(f"  ❌ Error en proxy de tarjetas: {e}")
        results['cards_proxy'] = False
    
    return results

def main():
    """Función principal de pruebas"""
    print("🧪 Iniciando pruebas de microservicios...")
    print("=" * 60)
    
    # Esperar un momento para que los servicios se inicien
    print("⏳ Esperando que los servicios se inicien...")
    time.sleep(5)
    
    # Probar health checks de todos los servicios
    print("\n📊 Verificando estado de servicios...")
    services_healthy = {}
    
    for service_name, base_url in SERVICES.items():
        services_healthy[service_name] = test_service_health(service_name, base_url)
    
    # Probar servicios individuales
    results = {}
    
    if services_healthy.get('auth'):
        results['auth'] = test_auth_service(SERVICES['auth'])
    
    if services_healthy.get('cards'):
        results['cards'] = test_cards_service(SERVICES['cards'])
    
    if services_healthy.get('api'):
        results['api'] = test_api_gateway(SERVICES['api'])
    
    # Resumen de resultados
    print("\n" + "=" * 60)
    print("📋 RESUMEN DE PRUEBAS")
    print("=" * 60)
    
    total_tests = 0
    passed_tests = 0
    
    for service_name, service_results in results.items():
        print(f"\n🔧 {service_name.upper()}:")
        for test_name, test_result in service_results.items():
            if isinstance(test_result, bool):
                total_tests += 1
                if test_result:
                    passed_tests += 1
                    print(f"  ✅ {test_name}")
                else:
                    print(f"  ❌ {test_name}")
            elif isinstance(test_result, dict):
                print(f"  📊 {test_name}: {test_result}")
    
    print(f"\n📊 RESULTADOS FINALES:")
    print(f"   Pruebas pasadas: {passed_tests}/{total_tests}")
    print(f"   Porcentaje de éxito: {(passed_tests/total_tests*100):.1f}%" if total_tests > 0 else "N/A")
    
    if passed_tests == total_tests and total_tests > 0:
        print("\n🎉 ¡Todas las pruebas pasaron! El sistema de microservicios está funcionando correctamente.")
    else:
        print("\n⚠️  Algunas pruebas fallaron. Revisa los errores arriba.")
    
    print("\n💡 Para usar el sistema:")
    print(f"   - API Gateway: {SERVICES['api']}")
    print(f"   - Credenciales de prueba: test@example.com / test123")

if __name__ == '__main__':
    main()
