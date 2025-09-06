#!/usr/bin/env python3
import http.server
import ssl
import socketserver
import os
from pathlib import Path

PORT = 8443
web_dir = Path('.')

class MyHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=web_dir, **kwargs)

print("🔒 Démarrage serveur HTTPS pour test notifications PWA DailyGrowth")
print(f"📁 Répertoire: {web_dir.absolute()}")

# Utiliser certificats existants ou créer des basiques
cert_file = 'server.crt'
key_file = 'server.key'

if not os.path.exists(cert_file) or not os.path.exists(key_file):
    print("⚠️ Génération certificats auto-signés...")
    os.system(f'openssl req -x509 -newkey rsa:2048 -keyout {key_file} -out {cert_file} -days 1 -nodes -subj "/CN=192.168.1.59"')

try:
    with socketserver.TCPServer(('', PORT), MyHTTPRequestHandler) as httpd:
        context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        context.check_hostname = False
        context.verify_mode = ssl.CERT_NONE
        context.load_cert_chain(cert_file, key_file)
        httpd.socket = context.wrap_socket(httpd.socket, server_side=True)
        
        print(f"✅ Serveur HTTPS démarré: https://192.168.1.59:{PORT}")
        print(f"🧪 Page de test: https://192.168.1.59:{PORT}/test_pwa_notifications.html")
        print("📱 Instructions:")
        print("   1. Ouvrir l'URL dans Safari iOS")
        print("   2. Accepter le certificat auto-signé")
        print("   3. Ajouter à l'écran d'accueil (PWA)")
        print("   4. Tester les notifications et badges")
        print("\n🛑 Ctrl+C pour arrêter")
        
        httpd.serve_forever()
        
except KeyboardInterrupt:
    print("\n🛑 Serveur arrêté")
except Exception as e:
    print(f"❌ Erreur serveur: {e}")
    # Fallback HTTP simple pour développement
    print("🔄 Fallback serveur HTTP simple sur port 8080...")
    os.system("python3 -m http.server 8080")