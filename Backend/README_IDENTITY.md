# Verificación de identidad (INE + biometría facial)

Alworki verifica cuentas comparando el **rostro de la credencial INE** con un **selfie**, más validación de **CURP**.

## Stack open source

| Componente | Librería | Licencia |
|------------|----------|----------|
| Comparación facial | [DeepFace](https://github.com/serengil/deepface) (ArcFace + RetinaFace) | MIT |
| Lectura de imagen | OpenCV (`opencv-python-headless`) | Apache 2.0 |
| OCR opcional | Tesseract + `pytesseract` | Apache 2.0 |

## Instalación (backend)

```bash
cd Backend
pip install -r requirements-identity.txt

# OCR en español (Linux)
sudo apt install tesseract-ocr tesseract-ocr-spa
```

### Modo demo (sin DeepFace)

Solo para desarrollo local:

```bash
export IDENTITY_DEMO_MODE=1
python app_unified.py
```

## API

### `GET /api/users/me/identity/status`

Requiere JWT. Devuelve estado de la última verificación.

### `POST /api/users/me/identity/verify`

`multipart/form-data`:

| Campo | Requerido | Descripción |
|-------|-----------|-------------|
| `ine_front` | Sí | Foto frontal INE/IFE |
| `selfie` | Sí | Selfie del usuario |
| `ine_back` | No | Reverso (mejora OCR) |
| `curp` | No | CURP manual si el OCR falla |

Respuesta incluye `approved`, `face`, `ocr`, `messages`.

Si `approved: true`, el perfil queda con `verified: true`.

## App Flutter

Ruta: `/verify-identity`  
Acceso desde el banner **«Verifica tu cuenta»** en el perfil.

## Limitación importante

La **biometría oficial del INE** (consulta a su base nacional) solo está disponible para **instituciones autorizadas** (bancos, fintech reguladas) con convenio ante el INE/CNBV.

Este módulo hace **verificación propia** de Alworki: útil para confianza en la plataforma, pero no equivale a validación gubernamental.

## Variables de entorno

| Variable | Default | Descripción |
|----------|---------|-------------|
| `IDENTITY_DEMO_MODE` | `0` | `1` = simula match facial |
| `IDENTITY_FACE_MODEL` | `ArcFace` | Modelo DeepFace |
| `IDENTITY_FACE_DETECTOR` | `retinaface` | Detector de rostros |
| `IDENTITY_FACE_THRESHOLD` | `0.4` | Umbral de distancia |
