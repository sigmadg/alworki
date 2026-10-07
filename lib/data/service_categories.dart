/// Catálogo único de oficios y categorías para búsqueda, tarjetas, portafolio y servicios.
class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.label,
    required this.group,
    this.keywords = const [],
    this.imageKey = 'background1.png',
  });

  final String id;
  final String label;
  final String group;
  final List<String> keywords;
  final String imageKey;

  /// Texto para rutas y búsqueda rápida.
  String get query => label;

  Iterable<String> get searchTerms sync* {
    yield label.toLowerCase();
    yield group.toLowerCase();
    for (final k in keywords) {
      yield k.toLowerCase();
    }
  }

  bool matchesQuery(String raw) {
    final q = raw.trim().toLowerCase();
    if (q.isEmpty) return true;
    return searchTerms.any((t) => t.contains(q) || q.contains(t));
  }
}

ServiceCategory _cat(String id, String group, String label, {List<String>? keywords}) =>
    ServiceCategory(
      id: id,
      group: group,
      label: label,
      keywords: keywords ?? [],
      imageKey: 'categories/$id.png',
    );

/// Grupos con todos los oficios disponibles en la app.
final kServiceCategoryGroups = <String, List<ServiceCategory>>{
  'Hogar y reparaciones': [
    _cat('plomeria', 'Hogar y reparaciones', 'Plomería', keywords: ['plomero', 'fugas', 'tuberías', 'baño']),
    _cat('electricidad', 'Hogar y reparaciones', 'Electricidad', keywords: ['electricista', 'instalación', 'luz']),
    _cat('albanileria', 'Hogar y reparaciones', 'Albañilería', keywords: ['albañil', 'mampostería', 'obra']),
    _cat('carpinteria', 'Hogar y reparaciones', 'Carpintería', keywords: ['carpintero', 'muebles', 'madera']),
    _cat('pintura', 'Hogar y reparaciones', 'Pintura', keywords: ['pintor', 'brocha', 'interiores']),
    _cat('limpieza', 'Hogar y reparaciones', 'Limpieza doméstica', keywords: ['limpieza', 'aseo', 'hogar']),
    _cat('jardineria', 'Hogar y reparaciones', 'Jardinería', keywords: ['jardinero', 'pasto', 'plantas']),
    _cat('cerrajeria', 'Hogar y reparaciones', 'Cerrajería', keywords: ['cerrajero', 'llaves', 'chapas']),
    _cat('fumigacion', 'Hogar y reparaciones', 'Fumigación', keywords: ['plagas', 'insectos']),
    _cat('impermeabilizacion', 'Hogar y reparaciones', 'Impermeabilización', keywords: ['goteras', 'techo']),
  ],
  'Salud y cuidado': [
    _cat('enfermeria', 'Salud y cuidado', 'Enfermería', keywords: ['enfermera', 'enfermero', 'curaciones', 'salud']),
    _cat('cuidadores', 'Salud y cuidado', 'Cuidadores', keywords: ['cuidador', 'cuidadora', 'adulto mayor']),
    _cat('geriatria', 'Salud y cuidado', 'Cuidado geriátrico', keywords: ['geriátrico', 'tercera edad']),
    _cat('fisioterapia', 'Salud y cuidado', 'Fisioterapia', keywords: ['fisioterapeuta', 'rehabilitación']),
    _cat('nutricion', 'Salud y cuidado', 'Nutrición', keywords: ['nutriólogo', 'dieta', 'alimentación']),
    _cat('psicologia', 'Salud y cuidado', 'Psicología', keywords: ['psicólogo', 'terapia', 'salud mental']),
    _cat('primeros_auxilios', 'Salud y cuidado', 'Primeros auxilios', keywords: ['emergencias', 'RCP']),
  ],
  'Mascotas': [
    _cat('veterinarios', 'Mascotas', 'Veterinarios', keywords: ['veterinario', 'veterinaria', 'mascota', 'perro', 'gato']),
    _cat('paseo_mascotas', 'Mascotas', 'Paseo de mascotas', keywords: ['paseador', 'perros', 'paseo']),
    _cat('estetica_canina', 'Mascotas', 'Estética canina', keywords: ['baño', 'grooming', 'peluquería canina']),
    _cat('adiestramiento', 'Mascotas', 'Adiestramiento', keywords: ['entrenador', 'obediencia']),
    _cat('cuidado_gatos', 'Mascotas', 'Cuidado de gatos', keywords: ['cat sitter', 'gatos']),
  ],
  'Educación y cuidado infantil': [
    _cat('nineras', 'Educación y cuidado infantil', 'Niñeras', keywords: ['niñera', 'niñero', 'babysitter', 'hijos']),
    _cat('apoyo_escolar', 'Educación y cuidado infantil', 'Apoyo escolar', keywords: ['tareas', 'refuerzo', 'primaria']),
    _cat('educacion_especial', 'Educación y cuidado infantil', 'Educación especial', keywords: ['inclusión', 'necesidades especiales']),
    _cat('cuidado_infantil', 'Educación y cuidado infantil', 'Cuidado infantil', keywords: ['guardería', 'bebés']),
  ],
  'Educación e idiomas': [
    _cat('ingles', 'Educación e idiomas', 'Clases de inglés', keywords: ['inglés', 'english', 'conversación']),
    _cat('otros_idiomas', 'Educación e idiomas', 'Otros idiomas', keywords: ['francés', 'alemán', 'italiano', 'portugués']),
    _cat('musica', 'Educación e idiomas', 'Música', keywords: ['guitarra', 'piano', 'canto', 'clases']),
    _cat('arte', 'Educación e idiomas', 'Arte y pintura', keywords: ['pintura', 'dibujo', 'escultura']),
    _cat('danza', 'Educación e idiomas', 'Danza', keywords: ['baile', 'ballet', 'salsa']),
    _cat('clases_particulares', 'Educación e idiomas', 'Clases particulares', keywords: ['tutor', 'matemáticas', 'física']),
  ],
  'Gastronomía': [
    _cat('cocina_casera', 'Gastronomía', 'Cocina casera', keywords: ['cocina', 'comida', 'chef']),
    _cat('reposteria', 'Gastronomía', 'Repostería', keywords: ['pasteles', 'postres', 'pan']),
    _cat('meal_prep', 'Gastronomía', 'Meal prep', keywords: ['meal prep', 'raciones', 'semanal']),
    _cat('chef_domicilio', 'Gastronomía', 'Chef a domicilio', keywords: ['chef', 'cena', 'evento']),
    _cat('bartender', 'Gastronomía', 'Bartender', keywords: ['bebidas', 'coctelería', 'bar']),
  ],
  'Belleza y bienestar': [
    _cat('peluqueria', 'Belleza y bienestar', 'Peluquería', keywords: ['peluquero', 'corte', 'cabello']),
    _cat('barberia', 'Belleza y bienestar', 'Barbería', keywords: ['barbero', 'barba']),
    _cat('manicure', 'Belleza y bienestar', 'Manicure y uñas', keywords: ['uñas', 'gelish']),
    _cat('maquillaje', 'Belleza y bienestar', 'Maquillaje', keywords: ['makeup', 'novias']),
    _cat('masajes', 'Belleza y bienestar', 'Masajes', keywords: ['masajista', 'relajación', 'spa']),
  ],
  'Tecnología': [
    _cat('soporte_tecnico', 'Tecnología', 'Soporte técnico', keywords: ['computadora', 'PC', 'software']),
    _cat('reparacion_celulares', 'Tecnología', 'Reparación de celulares', keywords: ['celular', 'pantalla', 'móvil']),
    _cat('diseno_web', 'Tecnología', 'Diseño web', keywords: ['página web', 'diseño', 'UI']),
    _cat('marketing_digital', 'Tecnología', 'Marketing digital', keywords: ['redes sociales', 'SEO', 'publicidad']),
  ],
  'Transporte y logística': [
    _cat('mensajeria', 'Transporte y logística', 'Mensajería', keywords: ['mandados', 'paquetería', 'entregas']),
    _cat('mudanzas', 'Transporte y logística', 'Mudanzas', keywords: ['mudanza', 'carga', 'traslado']),
    _cat('chofer', 'Transporte y logística', 'Chofer', keywords: ['conductor', 'traslados']),
    _cat('mecanico', 'Transporte y logística', 'Mecánico automotriz', keywords: ['auto', 'taller', 'reparación']),
  ],
  'Eventos': [
    _cat('fotografia', 'Eventos', 'Fotografía', keywords: ['fotógrafo', 'sesión', 'bodas']),
    _cat('dj', 'Eventos', 'DJ', keywords: ['música', 'fiesta', 'sonido']),
    _cat('animacion', 'Eventos', 'Animación', keywords: ['animador', 'fiestas infantiles']),
    _cat('decoracion_eventos', 'Eventos', 'Decoración de eventos', keywords: ['globos', 'fiesta', 'decoración']),
    _cat('catering', 'Eventos', 'Catering', keywords: ['banquetes', 'comida para eventos']),
  ],
  'Legal y administrativo': [
    _cat('contabilidad', 'Legal y administrativo', 'Contabilidad', keywords: ['contador', 'impuestos', 'SAT']),
    _cat('asesoria_legal', 'Legal y administrativo', 'Asesoría legal', keywords: ['abogado', 'legal', 'contratos']),
    _cat('tramites', 'Legal y administrativo', 'Trámites', keywords: ['gestoría', 'papeles', 'documentos']),
  ],
};

/// Lista plana de todas las categorías/oficios.
List<ServiceCategory> get kAllServiceCategories =>
    kServiceCategoryGroups.values.expand((list) => list).toList(growable: false);

/// Oficios destacados en la pantalla de categorías (una por grupo + los más buscados).
List<ServiceCategory> get kFeaturedServiceCategories {
  final featured = <ServiceCategory>[];
  final seen = <String>{};
  for (final list in kServiceCategoryGroups.values) {
    if (list.isNotEmpty) {
      featured.add(list.first);
      seen.add(list.first.id);
    }
  }
  const extraIds = [
    'veterinarios',
    'enfermeria',
    'cuidadores',
    'nineras',
    'plomeria',
    'limpieza',
    'ingles',
    'musica',
    'cocina_casera',
  ];
  for (final id in extraIds) {
    final cat = categoryById(id);
    if (cat != null && seen.add(cat.id)) featured.add(cat);
  }
  return featured;
}

ServiceCategory? categoryById(String id) {
  for (final c in kAllServiceCategories) {
    if (c.id == id) return c;
  }
  return null;
}

ServiceCategory? categoryByLabel(String label) {
  final q = label.trim().toLowerCase();
  for (final c in kAllServiceCategories) {
    if (c.label.toLowerCase() == q) return c;
  }
  return null;
}

List<ServiceCategory> categoriesMatchingQuery(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return kAllServiceCategories;
  return kAllServiceCategories.where((c) => c.matchesQuery(q)).toList();
}

List<String> get kServiceGroupNames => kServiceCategoryGroups.keys.toList(growable: false);
