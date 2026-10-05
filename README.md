# Smart Diary · by Smart Potli

Offline business diary (Android, Flutter). सगळा डेटा फोनमध्येच राहतो; इंटरनेट फक्त ✨ AI (मोफत Gemini) साठी.

## APK कसा बनवायचा (GitHub, मोफत)
1. ही सगळी फाइल्स GitHub repo मध्ये upload करा (`.github` फोल्डरसह). Repo **Private** ठेवा.
2. **Actions** टॅब → "Build APK" आपोआप सुरू होईल (8–12 मिनिटं).
3. हिरवी ✓ आली की run उघडा → खाली **Artifacts → SmartDiary-APK** डाउनलोड करा → zip उघडा → `app-release.apk`.
4. फोनमध्ये APK उघडा → "Unknown apps / अज्ञात स्रोत" परवानगी द्या → Install.

`tool/debug.keystore` मुळे प्रत्येक नवीन APK जुन्यावर update होतो आणि डेटा जात नाही. ही फाइल डिलीट करू नका.

## मोफत Gemini key
1. https://aistudio.google.com उघडा, Google account ने login करा.
2. **Get API key → Create API key** दाबा. Key (AIza… ने सुरू होणारी) copy करा.
3. अॅप → वरचं profile चिन्ह → Settings → ✨ AI → key पेस्ट करा → **AI तपासा**.
Billing / Upgrade सेट करू नका, म्हणजे कधीच पैसे लागणार नाहीत.
