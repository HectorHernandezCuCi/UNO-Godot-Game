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

### Arquitectura

Modelo cliente-servidor donde el host actúa como autoridad:

- Cliente envía acciones
- Servidor valida
- Servidor sincroniza estado

### Puertos

- 7777: Comunicación principal (ENet)
- 7778: Descubrimiento de salas (UDP)

### Seguridad

- Validación de turno en servidor
- Verificación de jugadas válidas

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
