# Migración Ejemplo → Flutter (Alworki)

Plataforma de **intercambio de favores** (feed tipo Instagram + tarjetas tipo Fiverr), basada en `Ejemplo/AlworkiAuto`.

## Mapa Vue → Flutter

| Vue (Ejemplo) | Flutter (`lib/`) | Estado |
|---------------|------------------|--------|
| `InstagramFeed.vue` + `InstagramStories.vue` | `ui/feed/` | ✅ MVP |
| `CardsDisplay.vue` / `SearchPage.vue` | `ui/search/search_screen.dart` | ✅ MVP |
| `UserProfile.vue` | `ui/profile/profile_screen.dart` | ✅ MVP |
| `ExchangeRequestsPage.vue` | `ui/exchange/` + `ExchangeRepository` | ✅ MVP local |
| `ProjectsPage.vue` | `ui/projects/` | ✅ mock |
| `LoginPage` / `RegisterPage` | `ui/screens/login`, `register` | ✅ local auth |
| `ChatPage` (IA) | — | ⏳ fase 2 |
| `stores/*.ts` + `/api/*` | `CatalogService` + mock en `data/` | ✅ en memoria |
| `authService.ts` | `services/auth_api.dart` | ✅ Sembast + JWT |

## Fases sugeridas (herramientas)

### Fase 1 — Qwen / Codex local (estructura y port)
- [x] Modelos y datos de favores
- [x] Navegación inferior (Inicio, Búsqueda, Perfil, Intercambio, Proyectos)
- [x] Copiar assets desde `Ejemplo/AlworkiAuto/FrontEnd` (`background1-5`, avatares, cabecera perfil)
- [x] Tema Berry/Vuetify (`lib/theme/app_theme.dart`, primary `#1e88e5`)
- [x] Chat IA (`lib/ui/chat/chat_screen.dart`, respuestas locales + API opcional `:5003`)

### Fase 2 — Claude / revisión (bugs y calidad)
- [ ] `flutter analyze` + `flutter test` en CI
- [ ] Pruebas de registro/login/intercambio en emulador
- [ ] Sincronización opcional con `Backend/app_unified.py` (HTTP) si se necesita multi-dispositivo
- [ ] API real de intercambios (`POST /api/exchange`) en backend y cliente

## Arranque

```bash
cd /home/sigmadg/Documentos/Proyectos_Gaby/Alworki
flutter pub get
flutter run -d emulator-5554   # o `flutter devices`
```

## Archivos de referencia en Ejemplo

- API mock: `Ejemplo/AlworkiAuto/Backend/app_unified.py`
- Menú: `FrontEnd/src/layouts/full/vertical-sidebar/sidebarItem.ts`
- Feed: `FrontEnd/src/components/InstagramFeed.vue`
