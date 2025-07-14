# SIG Shoes - Aplicación de Distribuidor

Esta es una aplicación Flutter para distribuidores del sistema SIG Shoes que permite gestionar entregas, optimizar rutas y realizar un seguimiento en tiempo real de las asignaciones.

## Características Principales

### 1. Autenticación
- Login seguro con credenciales del distribuidor
- Gestión de sesiones con tokens JWT
- Verificación automática de autenticación

### 2. Gestión de Asignaciones
- Ver todas las asignaciones pendientes y completadas
- Marcar entregas como completadas
- Reportar problemas en entregas
- Actualizar estado de pedidos en tiempo real

### 3. Mapa Interactivo
- Visualización de todas las ubicaciones de entrega
- Ubicación actual del distribuidor en tiempo real
- Marcadores diferenciados por estado de entrega
- Cálculo de rutas óptimas automático

### 4. Optimización de Rutas
- Algoritmo de optimización para minimizar distancia y tiempo
- Creación automática de rutas basadas en ubicaciones
- Cálculo de tiempo estimado de entrega
- Navegación paso a paso

### 5. Perfil del Distribuidor
- Información personal y del vehículo
- Estadísticas de entregas
- Configuración de la aplicación

## Configuración

### Requisitos Previos
1. Flutter SDK (versión 3.8.0 o superior)
2. Dart SDK
3. Android Studio/VS Code con extensiones de Flutter
4. Dispositivo Android o emulador

### Instalación
1. Clonar el repositorio
2. Ejecutar `flutter pub get` para instalar dependencias
3. Configurar permisos de ubicación en Android
4. Ejecutar `flutter run` para iniciar la aplicación

### API Backend
La aplicación se conecta al backend de SIG Shoes en:
- URL: https://sigbackend.up.railway.app
- Documentación: https://sigbackend.up.railway.app/docs

### Configuración de Mapas
Para utilizar Google Maps:
1. Obtener una API Key de Google Maps
2. Agregar la clave en `android/app/src/main/AndroidManifest.xml`
3. Habilitar las APIs necesarias en Google Cloud Console

## Estructura del Proyecto

```
lib/
├── models/          # Modelos de datos
├── services/        # Servicios de API y ubicación
├── providers/       # Gestión de estado
├── screens/         # Pantallas de la aplicación
└── main.dart        # Punto de entrada
```

## API Endpoints Utilizados

### Autenticación
- `POST /auth/login` - Iniciar sesión
- `GET /auth/profile` - Obtener perfil del usuario

### Distribuidores
- `GET /distribuidores/{id}` - Obtener datos del distribuidor
- `GET /asignaciones?distribuidor_id={id}` - Obtener asignaciones
- `PUT /asignaciones/{id}` - Actualizar estado de entrega

### Rutas
- `GET /rutas?distribuidor_id={id}` - Obtener rutas del distribuidor
- `POST /rutas` - Crear nueva ruta optimizada

## Uso de la Aplicación

### Login
1. Ingresar email y contraseña del distribuidor
2. La aplicación validará las credenciales con el backend
3. Una vez autenticado, se cargarán las asignaciones automáticamente

### Gestión de Entregas
1. En la pestaña "Asignaciones", ver todas las entregas pendientes
2. Tocar una asignación para ver detalles
3. Usar los botones para marcar como entregado o reportar problema
4. Agregar observaciones si es necesario

### Navegación con Mapas
1. En la pestaña "Mapa", ver todas las ubicaciones de entrega
2. Tocar un marcador para ver detalles del pedido
3. Usar el botón de ruta para calcular la ruta óptima
4. Seguir las instrucciones de navegación

### Optimización de Rutas
1. La aplicación calcula automáticamente la ruta más eficiente
2. Considera la ubicación actual y todas las entregas pendientes
3. Minimiza la distancia total y el tiempo de viaje
4. Guarda la ruta en el backend para seguimiento

## Permisos Necesarios

### Android
- `ACCESS_FINE_LOCATION` - Ubicación precisa
- `ACCESS_COARSE_LOCATION` - Ubicación aproximada
- `ACCESS_BACKGROUND_LOCATION` - Ubicación en segundo plano
- `INTERNET` - Conexión a internet

## Tecnologías Utilizadas

- **Flutter** - Framework de desarrollo multiplataforma
- **Provider** - Gestión de estado
- **Google Maps** - Mapas y navegación
- **HTTP** - Cliente para API REST
- **Geolocator** - Servicios de ubicación
- **Flutter Secure Storage** - Almacenamiento seguro de tokens

## Solución de Problemas

### Problemas de Ubicación
- Verificar que los permisos de ubicación estén habilitados
- Asegurarse de que el GPS esté activado
- Comprobar la conexión a internet

### Problemas de Conexión
- Verificar la conexión a internet
- Comprobar que el backend esté disponible
- Revisar las credenciales de login

### Problemas de Mapas
- Verificar que la API Key de Google Maps sea válida
- Asegurarse de que las APIs necesarias estén habilitadas
- Comprobar los permisos de ubicación

## Desarrollo y Contribución

Para contribuir al proyecto:
1. Fork del repositorio
2. Crear una rama para la nueva funcionalidad
3. Hacer los cambios necesarios
4. Crear un pull request con descripción detallada

## Contacto y Soporte

Para soporte técnico o preguntas sobre la aplicación, contactar al equipo de desarrollo del proyecto SIG Shoes.
