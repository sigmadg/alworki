#!/usr/bin/env python3
"""
Orquestador para iniciar todos los servicios del backend
"""

import subprocess
import time
import signal
import sys
import os
from threading import Thread
import requests

class ServiceOrchestrator:
    def __init__(self):
        self.processes = []
        self.running = True
        
    def start_service(self, command, name, port):
        """Iniciar un servicio en un proceso separado"""
        try:
            print(f"🚀 Iniciando {name} en puerto {port}...")
            process = subprocess.Popen(
                command,
                shell=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            self.processes.append((process, name, port))
            print(f"✅ {name} iniciado (PID: {process.pid})")
            return process
        except Exception as e:
            print(f"❌ Error iniciando {name}: {e}")
            return None
    
    def check_service_health(self, port, name):
        """Verificar que un servicio esté funcionando"""
        try:
            response = requests.get(f"http://localhost:{port}/health", timeout=5)
            if response.status_code == 200:
                print(f"✅ {name} está funcionando correctamente")
                return True
            else:
                print(f"⚠️ {name} responde pero con status {response.status_code}")
                return False
        except Exception as e:
            print(f"❌ {name} no está respondiendo: {e}")
            return False
    
    def start_all_services(self):
        """Iniciar todos los servicios"""
        print("🎯 Iniciando todos los servicios del backend...")
        print("=" * 60)
        
        # Servicio principal (app_unified.py)
        main_service = self.start_service(
            "cd /home/sigmadg/Documentos/AlworkiAuto/Backend && python app_unified.py",
            "Servicio Principal",
            5002
        )
        
        # Chatbot service
        chatbot_service = self.start_service(
            "cd /home/sigmadg/Documentos/AlworkiAuto/Backend && python chatbot_service.py",
            "Chatbot Service",
            5003
        )
        
        if not main_service or not chatbot_service:
            print("❌ Error iniciando servicios")
            return False
        
        # Esperar un poco para que los servicios se inicien
        print("\n⏳ Esperando que los servicios se inicien...")
        time.sleep(5)
        
        # Verificar salud de los servicios
        print("\n🔍 Verificando salud de los servicios...")
        
        main_ok = self.check_service_health(5002, "Servicio Principal")
        chatbot_ok = self.check_service_health(5003, "Chatbot Service")
        
        if main_ok and chatbot_ok:
            print("\n" + "=" * 60)
            print("🎉 ¡Todos los servicios están funcionando!")
            print("📊 Estado de los servicios:")
            print("   • Servicio Principal: http://localhost:5002 ✅")
            print("   • Chatbot Service: http://localhost:5003 ✅")
            print("\n💡 Para usar el chatbot:")
            print("   1. Ve a: http://localhost:5173")
            print("   2. Busca el botón flotante verde con icono de robot")
            print("   3. O ve directamente a: http://localhost:5173/main/working-help-chat")
            print("\n🛑 Para detener todos los servicios: Ctrl+C")
            print("=" * 60)
            return True
        else:
            print("\n❌ Algunos servicios no están funcionando correctamente")
            return False
    
    def stop_all_services(self):
        """Detener todos los servicios"""
        print("\n🛑 Deteniendo todos los servicios...")
        for process, name, port in self.processes:
            try:
                process.terminate()
                process.wait(timeout=5)
                print(f"✅ {name} detenido")
            except subprocess.TimeoutExpired:
                process.kill()
                print(f"⚠️ {name} forzado a detener")
            except Exception as e:
                print(f"❌ Error deteniendo {name}: {e}")
    
    def run(self):
        """Ejecutar el orquestador"""
        try:
            if self.start_all_services():
                # Mantener el orquestador ejecutándose
                while self.running:
                    time.sleep(1)
        except KeyboardInterrupt:
            print("\n\n🛑 Recibida señal de interrupción...")
        finally:
            self.stop_all_services()
            print("👋 Orquestador detenido")

def main():
    """Función principal"""
    orchestrator = ServiceOrchestrator()
    orchestrator.run()

if __name__ == "__main__":
    main()


