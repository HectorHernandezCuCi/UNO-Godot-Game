Aquí tienes tu documentación sin emojis y con un tono más profesional y consistente:

---

# UNO GODOT GAME - Documentación Profesional

**Versión:** 1.0
**Motor:** Godot Engine 4.6 (WIP)
**Lenguaje:** GDScript
**Tipo de Proyecto:** Juego de Cartas Multijugador
**Última actualización:** Abril 2026

---

## Tabla de Contenidos

1. [Descripción General](#descripción-general)
2. [Características](#características)
3. [Requisitos Técnicos](#requisitos-técnicos)
4. [Estructura del Proyecto](#estructura-del-proyecto)
5. [Arquitectura del Sistema](#arquitectura-del-sistema)
6. [Módulos Principales](#módulos-principales)
7. [Flujo de Juego](#flujo-de-juego)
8. [Sistema de Red](#sistema-de-red)
9. [Desarrollo](#desarrollo)
10. [Troubleshooting](#troubleshooting)

---

## Descripción General

**UNO Godot Game** es una implementación del clásico juego de cartas UNO desarrollada en Godot Engine 4.6 con soporte para:

- Modo multijugador local: jugador contra 3 CPUs
- Modo multijugador en red: 2 a 5 jugadores conectados por LAN (IPv4)
- Sistema de descubrimiento de salas mediante códigos numéricos de 4 dígitos y broadcast UDP
- Interfaz visual con efectos de perspectiva 3D, animaciones suaves y temas personalizados
- Sistema de audio con música ambiental y efectos dinámicos

**Objetivo:** ofrecer una experiencia fluida, competitiva y entretenida tanto en modo local como en red.

---

## Características

### Gameplay

- Reglas completas de UNO (colores, números y cartas especiales)
- Cartas especiales: Skip, Reverse, +2, +4, Wild
- Acumulación de cartas (+2 y +4)
- Sistema de turnos con validación
- Inteligencia artificial para CPUs
- Indicadores visuales de turno y estado

### Multijugador

- Arquitectura cliente/servidor utilizando ENet
- Sincronización de estado en tiempo real
- Descubrimiento de salas mediante TCP/UDP
- Validación de jugadas en servidor
- Manejo de desconexiones

### Interfaz

- Menú principal
- Selección de modo de juego
- Lobby con contador de jugadores
- HUD con información de turno
- Selector de color para cartas Wild
- Pantalla de fin de partida
- Menú de pausa

### Audio

- Tres pistas de música ambiental
- Efectos de sonido para acciones
- Efectos dinámicos (reverb, filtros)
- Control de volumen por buses

### Experiencia

- Animaciones fluidas
- Efectos visuales en interacción
- Distribución dinámica de cartas
- Feedback visual de jugadas inválidas
- Respuesta inmediata a acciones

---

## Requisitos Técnicos

### Software

- Godot Engine 4.6 o superior
- Sistemas operativos compatibles: Windows, macOS, Linux
- Red LAN IPv4 para multijugador

### Hardware Mínimo

- CPU: Intel i5 / AMD Ryzen 5 o superior
- RAM: 2 GB mínimo
- GPU compatible con OpenGL 4.3
- Puertos requeridos: 7777 (TCP) y 7778 (UDP)

### Dependencias

- ENet (integrado en Godot)
- Nakama SDK (incluido, no utilizado actualmente)

---

## Estructura del Proyecto

Se mantiene la misma estructura, eliminando iconografía para mayor claridad:

```
UNO-Godot-Game/
├── project.godot
├── default_bus_layout.tres
├── icon.svg
├── LICENSE
├── README.md
│
├── addons/
├── Assets/
├── Scenes/
├── Scripts/
│
└── DOCUMENTACION.md
```

### Descripción de Carpetas

| Carpeta  | Contenido           | Propósito                |
| -------- | ------------------- | ------------------------ |
| Assets/  | Recursos multimedia | Imágenes, audio, shaders |
| Scenes/  | Escenas (.tscn)     | Interfaz y componentes   |
| Scripts/ | Código GDScript     | Lógica del juego         |
| addons/  | Plugins externos    | Extensiones              |

---

## Arquitectura del Sistema

El sistema está dividido en tres capas principales:

1. **Capa de Presentación**
   Interfaz de usuario, animaciones y audio

2. **Capa de Lógica**
   Gestión de reglas, turnos y sincronización

3. **Capa de Red**
   Comunicación mediante ENet y descubrimiento de salas

---

## Módulos Principales

### GameMaster.gd

Responsable de la lógica central del juego:

- Gestión de jugadores
- Validación de jugadas
- Control de turnos
- Aplicación de efectos
- Determinación de ganador

### GameScreen.gd

Controlador principal de la interfaz:

- Gestión del HUD
- Interacción del usuario
- Flujo de turnos

### HandManager.gd

Gestión visual de cartas:

- Posicionamiento dinámico
- Animaciones
- Validación visual

### NetworkManager.gd

Gestión de red:

- Creación de servidor
- Conexión de clientes
- Manejo de RPC

### GameState.gd

Sincronización de estado:

- Estado público y privado
- Envío y recepción de datos

### RoomRegistry.gd

Descubrimiento de salas mediante UDP

### CardLogic.gd

Validación de cartas y reglas de juego

### MusicManager.gd

Gestión de música y efectos de sonido

---

## Flujo de Juego

### Modo Local

1. Inicio desde menú principal
2. Inicialización del mazo
3. Distribución de cartas
4. Ejecución de turnos (jugador y CPU)
5. Validación de jugadas
6. Detección de ganador
7. Finalización de partida

### Modo Multijugador

1. Creación o unión a sala
2. Lobby de espera
3. Inicio de partida por el host
4. Turnos sincronizados por servidor
5. Validación centralizada
6. Sincronización de estado
7. Finalización de partida

---

## Sistema de Red

El sistema de red de UNO Godot Game está diseñado para proporcionar una experiencia multijugador fluida y sincronizada en una red local (LAN).

### Arquitectura de Conexión

Se utiliza una arquitectura de red tipo **Cliente-Servidor (Autoritativo)** donde el creador de la sala (Host) actúa simultáneamente como cliente local y como servidor de autoridad. El sistema se apoya en dos protocolos principales:

1. **ENet (Puerto 7777 TCP/UDP):** Utilizado para la comunicación principal del juego. Garantiza la entrega de paquetes críticos (sincronización de estado, jugadas) y permite una comunicación rápida de baja latencia mediante RPCs (Remote Procedure Calls). El Host mantiene la verdad absoluta del estado del juego (mazo, pila de descarte, manos de los jugadores).
2. **Broadcast UDP (Puerto 7778):** Implementado en el script `RoomRegistry.gd`. Permite el descubrimiento automático de salas en la red local mediante un código numérico de 4 dígitos, eliminando la necesidad de introducir direcciones IP manualmente.

### Flujo de Sincronización

- **Inicialización:** Al comenzar la partida, el Host carga la escena de juego en todos los clientes y espera la confirmación (ready). Una vez todos confirman, el Host reparte las cartas, establece la carta inicial del descarte y sincroniza el estado completo hacia todos los clientes (`GameState.gd`).
- **Validación de Jugadas:** Cuando un cliente intenta jugar una carta, la acción se envía mediante RPC al servidor. El servidor valida la jugada contra las reglas en `CardLogic.gd`. Si es válida, el servidor actualiza su estado interno y luego emite un RPC para sincronizar el nuevo estado (incluyendo el cambio de turno) con todos los clientes.

---

## Pruebas Realizadas y Resultados

Durante la fase de desarrollo y validación del multijugador, se llevaron a cabo diversas pruebas en entornos controlados:

1. **Pruebas de Descubrimiento LAN:** 
   - *Descripción:* Conexión de múltiples clientes utilizando códigos de sala en diferentes dispositivos de la misma red WiFi/Ethernet.
   - *Resultado:* El broadcast UDP responde de manera confiable. Los clientes descubren la IP del Host a partir del código de sala en menos de un segundo y establecen la conexión ENet con éxito.
2. **Pruebas de Sincronización Inicial:** 
   - *Descripción:* Verificación de la propagación del estado inicial (mazo, descarte y manos) al cargar la pantalla de juego.
   - *Resultado:* Se superó un problema de condición de carrera inicial. Actualmente, el juego espera a que todos los clientes confirmen que la escena está lista antes de que el Host envíe el estado sincronizado, garantizando que nadie inicie sin cartas o sin visualizar la pila de descarte.
3. **Pruebas de Desconexión de Jugadores:**
   - *Descripción:* Simulación de cierre inesperado o caída de red de uno de los clientes durante su turno.
   - *Resultado:* El sistema captura la señal `peer_disconnected` y remueve los datos del jugador desconectado. El juego ajusta dinámicamente el orden de turnos sin interrumpir la partida. Si todos los oponentes se desconectan, el último jugador es declarado ganador.

---

## Mejoras y Optimizaciones Futuras

El sistema actual es robusto para redes locales, pero existen áreas de oportunidad para escalar la experiencia:

1. **Soporte de Multijugador por Internet (WAN):** 
   - Integrar un sistema de *Relay Servers* o *Punch-through* (usando STUN/TURN, como WebRTC) para que jugadores en diferentes redes puedan conectarse utilizando el código de sala sin requerir configuraciones de Port-Forwarding en sus routers.
2. **Migración de Host (Host Migration):**
   - Actualmente, si el Host se desconecta, la partida termina. Implementar un sistema de migración en el cual el estado sea delegado a otro cliente (que asumiría el rol de servidor) aseguraría la continuidad del juego.
3. **Persistencia y Estadísticas en Línea:**
   - Aprovechar la integración pre-configurada (y actualmente no utilizada) de *Nakama SDK* para habilitar cuentas de usuario, listas de amigos, estadísticas (ganadas/perdidas) y leaderboards.
4. **Predicción y Reconciliación en Clientes (Client Prediction):**
   - Para conexiones de mayor latencia, permitir que los clientes realicen las animaciones y reproduzcan sonidos localmente al instante de jugar una carta, en lugar de esperar la confirmación del servidor para ejecutar el feedback visual, mejorando la sensación de respuesta.

---

## Desarrollo

### Instalación

```bash
git clone https://github.com/HectorHernandezCuCi/UNO-Godot-Game.git
cd UNO-Godot-Game
```

Abrir en Godot 4.6 y ejecutar.

### Extensibilidad

- Nuevas cartas: modificar lógica en GameMaster
- Nuevos menús: agregar escenas y scripts
- Persistencia: implementar en GameState

### Debugging

- Uso de logs con `print()`
- Debugger integrado de Godot
- Monitor de rendimiento

---

## Troubleshooting

### Red

| Problema                    | Solución                                 |
| --------------------------- | ---------------------------------------- |
| Clientes no encuentran host | Verificar firewall (puertos 7777 y 7778) |
| Timeout al conectar         | Aumentar intentos en RoomRegistry        |
| Desconexión frecuente       | Revisar latencia                         |
| RPC no llegan               | Verificar configuración de RPC           |

### Gameplay

| Problema           | Solución                   |
| ------------------ | -------------------------- |
| CPU juega inválido | Revisar validación         |
| Turno no avanza    | Verificar lógica de turnos |
| Cartas desaparecen | Revisar animaciones        |

### Audio

| Problema         | Solución                 |
| ---------------- | ------------------------ |
| Música no suena  | Verificar buses de audio |
| SFX desincroniza | Revisar tiempos          |

### Visual

| Problema        | Solución                   |
| --------------- | -------------------------- |
| Shader no carga | Verificar compilación      |
| UI desalineada  | Ajustar anchors y márgenes |

---

## Referencias

- Documentación oficial de Godot
- Referencia de GDScript
- API de Multijugador de Godot

---

## Equipo

**Desarrollo:** Hector Alfredo Hernandez Trujillo, Ricardo Saul Razura Estrada
**Motor:** Godot Engine 4.6
**Licencia:** Ver archivo LICENSE
