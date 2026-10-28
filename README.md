# 🐾 Shih Tzu Grooming App & AI Suite

Una aplicación móvil integral desarrollada en **Flutter** especializada en el cuidado, estilismo y diagnóstico estético-veterinario de perros de raza **Shih Tzu**, potenciada con visión artificial mediante **Google Gemini 2.5 Flash**.

---

## 🌟 Características Principales

### 🐕 1. Simulador de Cortes con IA (Grooming Simulator)
* **5 Estilos Oficiales para Shih Tzu:**
  * **Corte Cachorro (*Puppy Cut*):** Manto uniforme, fresco y fácil de mantener.
  * **Corte Oso de Peluche (*Teddy Bear Cut*):** Cabeza esférica y cuerpo afelpado y redondeado.
  * **Corte Top Knot (*Moño Japonés*):** Moño superior característico con manto estilizado.
  * **Corte de León (*Lion Cut*):** Melena densa alrededor de la cabeza y cuerpo recortado.
  * **Corte de Exhibición (*Show Cut*):** Manto largo hasta el suelo con caída natural.
* **Adaptación Cromática Inteligente:** Selección dinámica del modelo estilístico según el color del manto del ejemplar (dorado/blanco vs. panda/negro y blanco).
* **Comparador Antes / Después:** Deslizador interactivo visual para comparar la foto original del perro con la proyección del corte simulado.
* **Ficha de Estilismo Exportable:** Generación y descarga de tarjeta de corte con datos técnicos para llevar al peluquero canino.

### 🔬 2. Escáner Clínico y de Manto con IA (Gemini 2.5 Flash)
* **Verificación Estricta de Raza:** Análisis visual que confirma si el ejemplar es un Shih Tzu o mezcla con fuerte predominio. Rechaza con criterio fundamentado cualquier otra raza (Golden Retriever, Pug, Labrador, Poodle, Chihuahua, etc.).
* **Diagnóstico Ocular y Lagrimal:** Detección de manchas de porfirina (óxido lagrimal) y alerta de riesgo corneal por pelos rozando los ojos.
* **Estado del Manto y Riesgo de Nudos:** Evaluación del volumen, hidratación del pelo y propensión al afieltrado.
* **Puntuación Global (0 - 100):** Nivel de salud e higiene con recomendaciones prácticas tanto para el tutor como para el peluquero profesional.

### 🐾 3. Ficha Técnica y Gestión de Mascotas
* Registro completo de mascotas con foto verificada, nombre, edad, sexo y notas de cuidado.
* Historial de simulaciones y cortes favoritos guardados por mascota.

### 🎓 4. Academia de Cuidado & Tutoriales Ilustrados
* Guías interactivas paso a paso para el tutor y estilista (cepillado diario, baño relajante, técnica de secado, corte de uñas y despeje lagrimal).
* Marcador de lecciones favoritas y barra de progreso de aprendizaje completado.

### 🛡️ 5. Control de Acceso Multi-Rol (Cliente, Admin y Root)
* **Modo Cliente:** Exploración de cortes, escáner, simulación y gestión de mascotas propias.
* **Modo Administrador:** Supervisión del catálogo de estilos, aprobación de contenido y métricas.
* **Modo Root (Superusuario):** Auditoría en tiempo real de logs del sistema, gestión global de usuarios, monitoreo de estados de red y configuración en caliente de la API de Gemini.

### 🎨 6. Personalización y Accesibilidad
* **Tema Adaptable:** Soporte completo para Modo Oscuro (*Dark Mode*) y Modo Claro (*Light Mode*).
* **Multilenguaje:** Traducción nativa a **Español**, **Inglés** y **Portugués**.
* **Gestión de Créditos:** Sistema de balance para simulaciones y calidad de imagen configurable.

---

## 🛠️ Stack Tecnológico

| Componente | Tecnología |
| :--- | :--- |
| **Framework** | [Flutter](https://flutter.dev/) (Dart SDK ^3.9.0) |
| **Inteligencia Artificial** | [Google Gemini API](https://aistudio.google.com/) (`gemini-2.5-flash` Multimodal Vision) |
| **Gestor de Estado** | [Provider](https://pub.dev/packages/provider) (`AppStateProvider`) |
| **Persistencia Local** | [SharedPreferences](https://pub.dev/packages/shared_preferences) |
| **Servicios Backend** | Firebase Core / Mock Repository con sincronización reactiva |
| **Diseño y Tipografía** | Google Fonts (Inter / Poppins) y Material Design 3 |
| **Manejo de Imágenes** | Image Picker, Path Provider, Share Plus |

---

## 📂 Estructura del Proyecto

```text
beta/
├── assets/
│   └── images/                # Recursos gráficos, iconos y estilos de cortes en alta resolución
├── lib/
│   ├── core/
│   │   ├── config/            # Configuración global de la app y constantes de Gemini
│   │   ├── models/            # Modelos de datos (Pet, Style, Creation, Tutorial, etc.)
│   │   ├── providers/         # Estado centralizado reactivo (AppStateProvider)
│   │   ├── services/          # Conexión con Gemini API, Firebase y exportación multimedia
│   │   ├── theme/             # Paleta de colores, tipografías y temas Claro / Oscuro
│   │   ├── utils/             # Sistema de traducciones i18n
│   │   └── widgets/           # Widgets reutilizables (Comparador Antes/Después, etc.)
│   ├── features/
│   │   ├── admin/             # Módulos y pantallas del panel de administración
│   │   ├── client/            # Pantallas para el usuario (Home, Simulador, Escáner, Perfil)
│   │   └── root/              # Módulos y herramientas del panel de superusuario
│   └── main.dart              # Punto de entrada de la aplicación
├── pubspec.yaml               # Dependencias y configuración de assets
└── README.md                  # Documentación del proyecto
```

---

## 🚀 Instalación y Puesta en Marcha

### Prerrequisitos
* **Flutter SDK:** Versión 3.24 o superior instalada ([Guía oficial de instalación](https://docs.flutter.dev/get-started/install)).
* **Android SDK:** Configurado para Android 10+ (API level 29 o superior).
* **Dispositivo físico o emulador Android** con conectividad a Internet.

### Pasos

1. **Clonar o abrir el repositorio:**
   ```bash
   cd beta
   ```

2. **Instalar dependencias de Flutter:**
   ```bash
   flutter pub get
   ```

3. **Verificar el código y dependencias:**
   ```bash
   flutter analyze
   ```

4. **Configurar la Clave de Google Gemini (Opcional):**
   * La aplicación incluye preconfigurada la clave por defecto en `lib/core/config/app_config.dart`.
   * Si deseas usar tu propia clave gratuita de Google AI Studio, puedes definirla en ese archivo o gestionarla desde la consola de administración en **Panel Root > Configuración del Sistema**.

5. **Ejecutar en modo depuración:**
   ```bash
   flutter run
   ```

---

## 📦 Compilación para Producción (Release APK)

Para generar el archivo ejecutable listo para instalar en cualquier dispositivo Android:

```bash
flutter build apk --release
```

El instalador final se generará en:
```text
build/app/outputs/flutter-apk/app-release.apk
```

---

## 🛡️ Seguridad y Buenas Prácticas con la IA
* Las solicitudes a Gemini se realizan mediante peticiones seguras HTTPS a la API v1beta de Google.
* Los diagnósticos procesan la imagen en memoria y devuelven un esquema JSON estructurado sin almacenar datos personales en servidores externos.
* Se validan los límites de tiempo de espera (*timeouts*) para garantizar una experiencia de usuario fluida incluso con conexiones de datos móviles inestables.

---

Desarrollado con ❤️ para la comunidad de amantes y profesionales del **Shih Tzu**.
