# Alworki + Supabase

La app Flutter sigue usando la API Flask (`/api/*`). La base de datos puede ser **SQLite** (desarrollo local) o **PostgreSQL en Supabase** (producción).

## 1. Crear proyecto Supabase

1. [supabase.com](https://supabase.com) → **New Project**
2. Guarda la contraseña de la base de datos
3. En **Settings → API** copia:
   - **Project URL**
   - **anon public** key
   - **service_role** key (solo servidor)

## 2. Aplicar el esquema

En el panel de Supabase: **SQL Editor** → pega y ejecuta:

`supabase/migrations/001_alworki_schema.sql`

Incluye todas las tablas: usuarios, perfiles, feed, mensajes, contactos, órdenes, proyectos, etc., con políticas RLS.

## 3. Configurar el backend

```bash
cp .env.example Backend/.env
```

Edita `Backend/.env`:

```env
SUPABASE_URL=https://TU_PROYECTO.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJ...
DATABASE_URL=postgresql://postgres.TU_REF:TU_PASSWORD@...pooler.supabase.com:6543/postgres
JWT_SECRET_KEY=una-clave-segura
```

Instala dependencias y arranca:

```bash
cd Backend
python3 -m venv venv && source venv/bin/activate
pip install -r requirements-api.txt
python app_unified.py
# o desde la raíz: ./scripts/start_backend.sh
```

Con `DATABASE_URL` configurado, el backend usa Postgres. Con `SUPABASE_URL` + `SERVICE_ROLE_KEY`, el registro/login usa **Supabase Auth** y sincroniza `app_users`.

Sin variables: sigue funcionando con SQLite local (`Backend/instance/*.db`).

## 4. Configurar Flutter

```bash
flutter pub get
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:5002 \
  --dart-define=SUPABASE_URL=https://TU_PROYECTO.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

En dispositivo físico usa la IP de tu PC en `API_BASE_URL`.

## 5. Endpoints cubiertos

| Dominio | Rutas |
|---------|--------|
| Auth | `/api/auth/register`, `login`, `verify-token`, `refresh-token`, `logout` |
| Perfil | `/api/users/me/profile`, skills, materials, portfolio, reviews |
| Catálogo | `/api/cards`, `/api/feed`, `/api/stories` |
| Social | `/api/messages`, `/api/contacts`, `/api/notifications` |
| Negocio | `/api/exchange`, `/api/projects`, `/api/quotes`, `/api/orders`, `/api/wallet` |

Todos persisten en Supabase cuando `DATABASE_URL` está activo.

## 6. Seguridad

- No subas `.env` a Git
- `SUPABASE_SERVICE_ROLE_KEY` solo en el servidor Flask
- `SUPABASE_ANON_KEY` puede ir en la app; RLS protege acceso directo
- El backend usa `DATABASE_URL` con rol de servicio y omite RLS

## 7. Migrar datos locales a Supabase

1. Exporta SQLite (`Backend/instance/alworki.db`) a CSV/JSON
2. Importa en las tablas equivalentes de Postgres
3. Crea usuarios en Supabase Auth y vincula `app_users.auth_uuid`

Para desarrollo, al arrancar con tablas vacías el backend ejecuta el **seed demo** automáticamente.
