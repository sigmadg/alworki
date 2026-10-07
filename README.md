# Alworki — monorepo (`FlutterApp/` + `Backend/` + `FrontEnd/` opcional)

## App Flutter (`FlutterApp/`)

La autenticación **no depende del servidor**: registro, login, invitado, JWT (access + refresh), verificación y renovación de token están implementados **dentro de la app** con:

- **Sembast** (archivo local en móvil/escritorio, IndexedDB en web) para usuarios.
- **Contraseñas** con el mismo formato que Werkzeug/Flask (`pbkdf2:sha256:600000$…`), compatible con hashes generados por `Backend/app_unified.py` si importaras usuarios.
- **JWT HS256** con la misma semántica que `Ejemplo/AlworkiAuto/Backend/auth/jwt_manager.py` (secreto por defecto igual que el backend de ejemplo; personalizable con `--dart-define=JWT_SECRET=…`).

```bash
cd FlutterApp && flutter pub get && flutter run
```

## Backend y FrontEnd (opcional)

`Backend/` y `FrontEnd/` siguen disponibles para la API Vue/Python, pruebas o futuras pantallas que consuman HTTP. **No hace falta levantar el backend** para usar login/registro en Flutter.

```bash
./run_flutter_with_backend.sh   # solo si quieres API Flask + Flutter a la vez
```

## Tests (Flutter)

```bash
cd FlutterApp && flutter test && flutter analyze
```
