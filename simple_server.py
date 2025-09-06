#!/usr/bin/env python3
import http.server
import socketserver
import os
import socket

# Obtenir l'IP locale automatiquement
def get_local_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except:
        return "localhost"

PORT = 8000
local_ip = get_local_ip()

class MyHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=os.getcwd(), **kwargs)

print("🚀 DailyGrowth - Serveur Test Notifications PWA")
print(f"📁 Répertoire: {os.getcwd()}")
print(f"🌐 IP locale détectée: {local_ip}")
print()

try:
    with socketserver.TCPServer(("", PORT), MyHTTPRequestHandler) as httpd:
        print(f"✅ Serveur HTTP démarré avec succès !")
        print()
        print("📱 URLs à tester sur iPhone :")
        print(f"   http://{local_ip}:{PORT}/test_notifications_standalone.html")
        print(f"   http://localhost:{PORT}/test_notifications_standalone.html (Mac uniquement)")
        print()
        print("📋 Instructions iPhone :")
        print("   1. Connecter iPhone au MÊME WiFi que le Mac")
        print("   2. Ouvrir Safari iOS")
        print("   3. Taper l'URL complète")
        print("   4. Autoriser les notifications")
        print("   5. Ajouter à l'écran d'accueil (Partager → 'Ajouter à l'écran d'accueil')")
        print("   6. Lancer depuis l'icône PWA pour tester les badges")
        print()
        print("🔧 Dépannage :")
        print("   - Vérifier que iPhone et Mac sont sur le même WiFi")
        print("   - Désactiver le pare-feu macOS si nécessaire")
        print("   - Essayer de naviguer vers http://{local_ip}:{PORT} d'abord")
        print()
        print("🛑 Ctrl+C pour arrêter le serveur")
        print("-" * 60)
        
        httpd.serve_forever()
        
except OSError as e:
    if "Address already in use" in str(e):
        print(f"❌ Le port {PORT} est déjà utilisé.")
        print("💡 Essayez de changer le PORT dans le script ou arrêtez l'autre serveur.")
    else:
        print(f"❌ Erreur serveur: {e}")
except KeyboardInterrupt:
    print("\n🛑 Serveur arrêté proprement")
except Exception as e:
    print(f"❌ Erreur inattendue: {e}")