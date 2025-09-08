// Script pour vérifier et corriger la configuration Firebase

console.log('🔥 Vérification Configuration Firebase DailyGrowth');

// Ta configuration actuelle (à vérifier)
const firebaseConfig = {
  apiKey: "AIzaSyCdJSoFjbBqFtxxrIRV2zc7ow_Um7dC5U",
  authDomain: "dailygrowth-pwa.firebaseapp.com",
  projectId: "dailygrowth-pwa",
  storageBucket: "dailygrowth-pwa.appspot.com",
  messagingSenderId: "443167745906",
  appId: "1:443167745906:web:c0e8f1c03571d440f3dfeb",
  measurementId: "G-BXJW80Y4EF"
};

console.log('Configuration Firebase:', firebaseConfig);
console.log('Project ID:', firebaseConfig.projectId);
console.log('API Key:', firebaseConfig.apiKey.substring(0, 10) + '...');

// Test de validation
const isValid = firebaseConfig.apiKey.startsWith('AIza') && 
                firebaseConfig.projectId === 'dailygrowth-pwa';

console.log('Configuration valide:', isValid ? '✅' : '❌');

if (!isValid) {
    console.log('❌ Configuration Firebase invalide !');
    console.log('Vérifiez dans Firebase Console : https://console.firebase.google.com/project/dailygrowth-pwa');
}

// VAPID Key
const vapidKey = 'BJe790aSYySweHjaldtDhKaWTx5BBQ0dskvXly3urJWFnFifeoWY1EA8wJnDvyUhlu_s_AZODY9ucqBi0FgMxXs';
console.log('VAPID Key:', vapidKey.substring(0, 10) + '...');