#!/usr/bin/env python3
"""
Script de prueba para verificar que el backend funciona correctamente
"""

import requests
import json
import time

BASE_URL = 'http://localhost:5000'

def test_health_check():
    """Prueba el endpoint de health check"""
    print("🔍 Probando health check...")
    try:
        response = requests.get(f'{BASE_URL}/health')
        if response.status_code == 200:
            print("✅ Health check exitoso")
            print(f"   Respuesta: {response.json()}")
            return True
        else:
            print(f"❌ Health check falló: {response.status_code}")
            return False
    except requests.exceptions.ConnectionError:
        print("❌ No se puede conectar al backend. ¿Está ejecutándose?")
        return False
    except Exception as e:
        print(f"❌ Error en health check: {e}")
        return False

def test_register():
    """Prueba el endpoint de registro"""
    print("\n🔍 Probando registro de usuario...")
    
    user_data = {
        'firstname': 'Test',
        'lastname': 'User',
        'email': 'test@example.com',
        'password': 'test123'
    }
    
    try:
        response = requests.post(
            f'{BASE_URL}/register',
            json=user_data,
            headers={'Content-Type': 'application/json'}
        )
        
        if response.status_code == 201:
            print("✅ Registro exitoso")
            print(f"   Respuesta: {response.json()}")
            return True
        elif response.status_code == 400:
            print("⚠️  Usuario ya existe o datos inválidos")
            print(f"   Respuesta: {response.json()}")
            return True  # No es un error, el usuario ya existe
        else:
            print(f"❌ Registro falló: {response.status_code}")
            print(f"   Respuesta: {response.json()}")
            return False
    except Exception as e:
        print(f"❌ Error en registro: {e}")
        return False

def test_login():
    """Prueba el endpoint de login"""
    print("\n🔍 Probando login...")
    
    login_data = {
        'email': 'test@example.com',
        'password': 'test123'
    }
    
    try:
        response = requests.post(
            f'{BASE_URL}/login',
            json=login_data,
            headers={'Content-Type': 'application/json'}
        )
        
        if response.status_code == 200:
            print("✅ Login exitoso")
            data = response.json()
            print(f"   Usuario: {data['user']['firstname']} {data['user']['lastname']}")
            print(f"   Session ID: {data['session_id'][:8]}...")
            return data['session_id']
        else:
            print(f"❌ Login falló: {response.status_code}")
            print(f"   Respuesta: {response.json()}")
            return None
    except Exception as e:
        print(f"❌ Error en login: {e}")
        return None

def test_verify_session(session_id):
    """Prueba el endpoint de verificación de sesión"""
    print("\n🔍 Probando verificación de sesión...")
    
    try:
        response = requests.get(
            f'{BASE_URL}/verify-session',
            headers={
                'Authorization': f'Bearer {session_id}',
                'Content-Type': 'application/json'
            }
        )
        
        if response.status_code == 200:
            print("✅ Verificación de sesión exitosa")
            data = response.json()
            print(f"   Usuario: {data['firstname']} {data['lastname']}")
            return True
        else:
            print(f"❌ Verificación de sesión falló: {response.status_code}")
            print(f"   Respuesta: {response.json()}")
            return False
    except Exception as e:
        print(f"❌ Error en verificación de sesión: {e}")
        return False

def test_logout(session_id):
    """Prueba el endpoint de logout"""
    print("\n🔍 Probando logout...")
    
    try:
        response = requests.post(
            f'{BASE_URL}/logout',
            json={'session_id': session_id},
            headers={'Content-Type': 'application/json'}
        )
        
        if response.status_code == 200:
            print("✅ Logout exitoso")
            print(f"   Respuesta: {response.json()}")
            return True
        else:
            print(f"❌ Logout falló: {response.status_code}")
            print(f"   Respuesta: {response.json()}")
            return False
    except Exception as e:
        print(f"❌ Error en logout: {e}")
        return False

def main():
    """Función principal que ejecuta todas las pruebas"""
    print("🚀 Iniciando pruebas del backend...")
    print("=" * 50)
    
    # Esperar un poco para que el backend se inicie
    time.sleep(2)
    
    # Ejecutar pruebas
    tests_passed = 0
    total_tests = 5
    
    # Test 1: Health check
    if test_health_check():
        tests_passed += 1
    
    # Test 2: Registro
    if test_register():
        tests_passed += 1
    
    # Test 3: Login
    session_id = test_login()
    if session_id:
        tests_passed += 1
    
    # Test 4: Verificación de sesión
    if session_id and test_verify_session(session_id):
        tests_passed += 1
    
    # Test 5: Logout
    if session_id and test_logout(session_id):
        tests_passed += 1
    
    # Resumen
    print("\n" + "=" * 50)
    print(f"📊 Resultados: {tests_passed}/{total_tests} pruebas exitosas")
    
    if tests_passed == total_tests:
        print("🎉 ¡Todas las pruebas pasaron! El backend está funcionando correctamente.")
    else:
        print("⚠️  Algunas pruebas fallaron. Revisa los errores arriba.")
    
    print("\n💡 Para probar el frontend:")
    print("   1. Asegúrate de que el backend esté ejecutándose en http://localhost:5000")
    print("   2. Ejecuta el frontend con: npm run dev")
    print("   3. Ve a http://localhost:5173/login")
    print("   4. Usa las credenciales: test@example.com / test123")

if __name__ == '__main__':
    main()






