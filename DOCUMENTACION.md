# 🎮 UNO GODOT GAME - Documentación Profesional

**Versión:** 1.0  
**Motor:** Godot Engine 4.6 (WIP)  
**Lenguaje:** GDScript  
**Tipo de Proyecto:** Juego de Cartas Multijugador  
**Última actualización:** Abril 2026

---

## 📋 Tabla de Contenidos

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

## 📖 Descripción General

**UNO Godot Game** es una implementación del clásico juego de cartas UNO desarrollada en Godot Engine 4.6 con soporte para:

- **Modo Multijugador Local**: Jugador vs 3 CPUs inteligentes
- **Modo Multijugador en Red**: 2-5 jugadores conectados por LAN (IPv4)
- **Sistema de Descubrimiento de Salas**: Mediante códigos numéricos de 4 dígitos y broadcast UDP
- **Interfaz Visual Profesional**: Efectos de perspectiva 3D, animaciones suaves, y temas personalizados
- **Sistema de Sonido Completo**: Música ambiental, SFX, y efectos de audio dinámicos

**Objetivo**: Jugar UNO con amigos de manera fluida, competitiva y entretenida, ya sea localmente o en red.

---

## ✨ Características

### 🎮 Gameplay

- ✅ Reglas completas de UNO (colores, números, cartas especiales)
- ✅ Cartas especiales: Skip, Reverse, +2, +4, Wild
- ✅ Acumulación de cartas (chaining de +2 y +4)
- ✅ Sistema de turnos con validación
- ✅ IA competente para 3 CPUs
- ✅ Indicadores visuales de turno y estado

### 🌐 Multijugador

- ✅ Arquitectura Host/Cliente con ENet
- ✅ Sincronización de estado entre jugadores
- ✅ Sistema de discovery de salas por TCP
- ✅ Validación anti-trucos en el servidor
- ✅ Manejo robusto de desconexiones

### 🎨 Interfaz

- ✅ Menú principal intuitivo
- ✅ Selector de modos (Local/Multijugador)
- ✅ Lobby con countdown de jugadores
- ✅ HUD en juego con información de turno
- ✅ Selector de color para cartas Wild
- ✅ Pantalla de Game Over con ganador
- ✅ Menú de pausa

### 🔊 Audio

- ✅ 3 pistas de música ambiental
- ✅ SFX para acciones (robar, jugar, hover)
- ✅ Efectos dinámicos: Reverb, Low-Pass Filter
- ✅ Volumen controlable por bus

### 🎯 Experiencia

- ✅ Animaciones fluidas de cartas
- ✅ Efectos visuales en hover (3D perspective)
- ✅ Rotación dinámica de manos
- ✅ Feedback visual de cartas no jugables
- ✅ Respuesta inmediata a acciones

---

## 🔧 Requisitos Técnicos

### Software

- **Godot Engine 4.6+** (versión oficial o nightly)
- **Sistema Operativo**: Windows, macOS, Linux
- **Red**: LAN IPv4 (para multijugador)

### Hardware Mínimo

- **CPU**: Procesador moderno (Intel i5/AMD Ryzen 5 o superior)
- **RAM**: 2 GB mínimo
- **GPU**: Tarjeta gráfica integrada compatible con OpenGL 4.3+
- **Conexión**: Puerto 7777 (TCP) y 7778 (UDP) disponibles para multijugador

### Dependencias Integradas

- **Nakama SDK** (addon incluido, actualmente no utilizado)
- **ENet** (built-in en Godot)

---

## 📁 Estructura del Proyecto

```
UNO-Godot-Game/
├── 📄 project.godot                    # Configuración principal del proyecto
├── 📄 default_bus_layout.tres         # Configuración de buses de audio
├── 📄 icon.svg                        # Icono del proyecto
├── 📄 LICENSE                         # Licencia del proyecto
├── 📄 README.md                       # Guía rápida (complementario)
│
├── 📁 addons/                         # Complementos externos
│   └── com.heroiclabs.nakama/        # SDK Nakama (no activo)
│
├── 📁 Assets/                         # Recursos multimedia
│   ├── Audio/                         # Música y SFX
│   │   ├── Music/                    # 3 pistas de música
│   │   └── Sfx/                      # Efectos de sonido
│   ├── Cards/                         # Sprites de cartas
│   │   ├── Blue/, Green/, Red/, Yellow/  # Colores estándar
│   │   ├── Wild/                     # Cartas comodín
│   │   └── *.png.import               # Metadatos de importación
│   ├── Background/                    # Texturas de fondo (4 variantes)
│   ├── Curves/                        # Curvas de animación
│   │   ├── CardHandRotateCurve.tres  # Rotación dinámica de manos
│   │   ├── HorizontalCardCurve.tres  # Posicionamiento horizontal
│   │   └── VerticalCardCurve.tres    # Posicionamiento vertical
│   └── Shaders/                       # Shaders GLSL
│       ├── 2D-Perspective.gdshader   # Efecto 3D en cartas
│       ├── BlurShader.gdshader       # Efecto blur (pausa)
│       └── ChromaticAbberation.gdshader
│
├── 📁 Scenes/                         # Escenas (.tscn)
│   ├── Cards/
│   │   └── Card.tscn                 # Prefab de carta individual
│   ├── Game/                          # Escenas de juego local
│   │   ├── Deck.tscn                 # Visualización del mazo
│   │   ├── GameMaster.tscn           # Autoload: lógica central
│   │   ├── GameScreen.tscn           # Pantalla principal de juego
│   │   ├── HandManager.tscn          # Gestor de manos visuales
│   │   ├── MusicManager.tscn         # Autoload: música
│   │   └── PlayerHand.tscn           # Representación de mano del jugador
│   ├── GameMultiplayer/              # Escenas multijugador (WIP)
│   ├── Menus/                         # Interfaz de usuario
│   │   ├── button_theme.tres         # Tema de botones
│   │   ├── menu_theme.tres           # Tema del menú
│   │   ├── custom_button.gd          # Script de botón personalizado
│   │   ├── CustomButton.tscn         # Componente de botón
│   │   ├── MainMenu/                 # Menú principal
│   │   ├── MultiplayerMenu/          # Menú multijugador
│   │   └── PauseMenu/                # Menú de pausa
│   └── Network/
│       └── Lobby.tscn                # Sala de espera pre-juego
│
├── 📁 Scripts/                        # Código GDScript
│   ├── GameMaster.gd                 # 🔴 CORE: Lógica de juego (reglas, turnos, validación)
│   ├── MusicManager.gd               # Reproducción y efectos de música
│   ├── SceneManager.gd               # Transiciones entre escenas
│   ├── Cards/
│   │   ├── CardLogic.gd              # Lógica y validación de cartas
│   │   └── CardFace.gd               # Renderizado visual de cartas
│   ├── Game Screen/                   # UI y control del juego
│   │   ├── GameScreen.gd             # Controlador principal de pantalla
│   │   ├── HandManager.gd            # Posicionamiento y animación de manos
│   │   ├── DiscardPile.gd            # Visualización de descarte
│   │   └── Game Hud/                 # Elementos HUD (indicadores)
│   ├── Network/                       # 🔴 CORE: Sistema multijugador
│   │   ├── NetworkManager.gd         # Gestión de conexiones ENet
│   │   ├── GameState.gd              # Sincronización de estado
│   │   ├── RoomRegistry.gd           # Discovery de salas (UDP)
│   │   └── Lobby.gd                  # Controlador de sala de espera
│   └── Game Screen Multiplayer/      # (Reservado para futuro)
│
└── 📄 DOCUMENTACION.md                # Este archivo

```

### 📊 Descripción de Carpetas Clave

| Carpeta      | Contenido                      | Propósito                     |
| ------------ | ------------------------------ | ----------------------------- |
| **Assets/**  | Imágenes, audio, shaders       | Recursos multimedia           |
| **Scenes/**  | Archivos .tscn (escenas Godot) | Componentes visuales          |
| **Scripts/** | Lógica GDScript                | Comportamiento del juego      |
| **addons/**  | Plugins externos               | Extensiones (Nakama sin usar) |

---

## 🏗️ Arquitectura del Sistema

### 1. Diagrama General

```
┌─────────────────────────────────────────────────────┐
│              CAPA DE PRESENTACIÓN                    │
│  (Menús, HUD, GameScreen, Animaciones, Sonido)     │
│                                                      │
│  ├─ MainMenu → MultiplayerMenu → Lobby             │
│  └─ GameScreen (Local) | GameScreenMP (Red)        │
└────────────────────┬────────────────────────────────┘
                     │
┌────────────────────┴────────────────────────────────┐
│         CAPA DE LÓGICA Y SINCRONIZACIÓN             │
│  (GameMaster, GameState, NetworkManager)           │
│                                                      │
│  ├─ GameMaster: Reglas, turnos, validación        │
│  ├─ GameState: Serialización de estado            │
│  └─ NetworkManager: RPC y conexiones              │
└────────────────────┬────────────────────────────────┘
                     │
┌────────────────────┴────────────────────────────────┐
│         CAPA DE COMUNICACIÓN (NETWORK)              │
│  (ENet, UDP Discovery, RoomRegistry)               │
│                                                      │
│  ├─ ENet (TCP/UDP): Transporte de datos            │
│  ├─ RoomRegistry: Discovery por UDP                │
│  └─ Multiplayer API: Sistema RPC de Godot         │
└─────────────────────────────────────────────────────┘
```

### 2. Flujo de Datos

**Juego Local:**

```
Usuario Input
    ↓
GameScreen (captura click)
    ↓
HandManager (obtiene carta)
    ↓
GameMaster (valida + aplica lógica)
    ↓
GameScreen (actualiza UI)
    ↓
MusicManager (SFX)
```

**Juego Multijugador:**

```
Usuario Input (Cliente)
    ↓
GameScreen.mp_request_play() [RPC]
    ↓
NetworkManager._server_play_card() (Host)
    ↓
GameMaster (valida, aplica lógica)
    ↓
NetworkManager._rpc_receive_state() [Broadcast]
    ↓
GameScreen (todos actualizan UI)
```

---

## 🎯 Módulos Principales

### 1. 🔴 GameMaster.gd (CORE)

**Responsabilidad**: Lógica central del juego, árbitro supremo.

**Variables Clave**:

```gdscript
var players: Array = ["player", "cpu1", "cpu2", "cpu3"]
var current_player: int = 0
var current_color: String = "Blue"
var cards_to_be_taken: int = 0
var clockwise: bool = true
```

**Métodos Principales**:

| Método                                  | Descripción                                |
| --------------------------------------- | ------------------------------------------ |
| `init_deck()`                           | Inicializa mazo con todas las cartas       |
| `draw_from_deck()`                      | Extrae cartas del mazo (refill automático) |
| `play_card(player_id, card, new_color)` | Valida y juega una carta                   |
| `can_be_played(card)`                   | Verifica si carta es jugable               |
| `next_turn(skip, reverse)`              | Avanza al siguiente turno                  |
| `apply_card_effect(card)`               | Aplica efectos especiales                  |
| `cpu_play(cpu_id)`                      | IA: CPU juega automáticamente              |
| `calculate_winner()`                    | Determina ganador                          |

**Señales**:

```gdscript
signal new_round          # Nuevo turno iniciado
signal game_over(winner)  # Juego terminado
signal card_played(player, card)
signal card_drawn(player, count)
```

**Ejemplo de Uso**:

```gdscript
# En GameScreen.gd
func _on_card_clicked(card: Node) -> void:
    if GameMaster.play_card(0, card, selected_color):
        card.queue_free()  # Elimina visualmente
```

---

### 2. GameScreen.gd (Controlador Principal)

**Responsabilidad**: Controla la pantalla de juego, UI y flujo visual.

**Componentes**:

- `GameHud`: Información de turno, botón robar
- `DiscardPile`: Muestra carta superior del descarte
- `HandManagers`: 4 gestores (1 jugador + 3 CPUs)
- `ColorSelector`: Widget para elegir color
- `PauseMenu`: Pausa in-game
- `GameOverScreen`: Pantalla de victoria

**Flujo de Turno Local**:

```gdscript
1. _on_GameMaster_new_round()
   └─ Si es turno del jugador:
      ├─ Habilitar interacción
      ├─ Si hay cartas acumuladas: Botón robar en azul
      └─ Esperar click en carta o botón robar
   └─ Si es CPU:
      └─ Esperar 1-3s, GameMaster.cpu_play()
```

---

### 3. HandManager.gd (Gestor de Manos)

**Responsabilidad**: Posiciona, anima y controla interacción con cartas.

**Características**:

- Posicionamiento dinámico con curvas de Bezier
- Rotación radial según cantidad de cartas
- Efectos hover (escala, elevación 3D)
- Validación visual (cartas grises si no son jugables)

**Algoritmo de Posicionamiento**:

```gdscript
for each card in hand:
    hand_ratio = index / (total_cards - 1)
    position.x = vertical_curve.sample(hand_ratio) * spread_amount
    position.y = horizontal_curve.sample(hand_ratio)
    rotation = rotate_curve.sample(hand_ratio) * max_rotation
```

---

### 4. 🔴 NetworkManager.gd (CORE Red)

**Responsabilidad**: Gestión de conexiones ENet y sincronización.

**Puertos**:

- **7777**: TCP/UDP para juego (ENet)
- **7778**: UDP para discovery (RoomRegistry)

**Flujo de Host**:

```gdscript
create_server(username: String)
  ├─ ENetMultiplayerPeer.create_server(7777, MAX_PLAYERS)
  ├─ RoomRegistry.host_open_room() → genera código XXXX
  └─ Emite: server_created(code)
```

**Flujo de Cliente**:

```gdscript
join_by_code(code: String, username: String)
  ├─ RoomRegistry.client_find_room(code)
  │  └─ UDP Broadcast: FIND:XXXX cada 0.5s (máx 10 intentos)
  ├─ Host responde: FOUND:IP:PORT
  ├─ ENetMultiplayerPeer.create_client(ip, 7777)
  └─ Emite: joined_server
```

**Señales**:

```gdscript
signal server_created(code)
signal joined_server
signal connection_failed
signal server_disconnected
signal player_registered(peer_id, username)
signal player_disconnected(peer_id)
```

---

### 5. GameState.gd (Sincronización)

**Responsabilidad**: Serialización y envío de estado del juego.

**Estado Sincronizado**:

```gdscript
# Privado de cada jugador
var player_hands: Dictionary = {
    1: [card1, card2, ...],
    2: [card1, card2, ...],
    ...
}

# Público (visto por todos)
var current_player: int
var current_color: String
var top_discard_card: Card
var deck_size: int
```

**Métodos RPC**:

- `_rpc_receive_hand()`: Sincroniza mano local
- `_rpc_receive_state()`: Sincroniza estado público
- `_rpc_game_started()`: Inicia juego
- `_rpc_game_over(winner_id)`: Anuncia ganador

---

### 6. RoomRegistry.gd (Discovery)

**Responsabilidad**: Descubrimiento de salas mediante broadcast UDP.

**Protocolo**:

- Host escucha puerto 7778
- Cliente envía `FIND:XXXX`
- Host responde `FOUND:IP:7777`
- Cliente intenta conectar por TCP a 7777

**Timeout**: 5 segundos (10 intentos × 0.5s)

---

### 7. CardLogic.gd (Validación de Cartas)

**Responsabilidad**: Lógica y validación de jugadas.

**Propiedades de Carta**:

```gdscript
color: String      # "Blue", "Green", "Red", "Yellow", "Wild"
value: String      # "0"-"9", "Skip", "Reverse", "Picker", "PickFour", "ColorChanger"
```

**Validación**:

```gdscript
func can_play_on(top_card: Card, current_color: String) -> bool:
    return (color == top_card.color or
            value == top_card.value or
            color == "Wild" or
            current_color == color)
```

**Efectos**:

- **Skip**: `next_turn(skip=true)` → avanza 2 posiciones
- **Reverse**: `clockwise = !clockwise` → invierte orden
- **Picker (+2)**: `cards_to_be_taken += 2`
- **PickFour (+4)**: `cards_to_be_taken += 4`
- **Wild**: Permite elegir color

---

### 8. MusicManager.gd (Audio)

**Responsabilidad**: Reproducción de música y SFX, efectos de audio.

**Pistas de Música**:

1. "Riding the Mood Swing"
2. "Sunset Juice"
3. "The Halcyon Card Club"

**Buses de Audio**:

- **Default**: Audio general
- **Music**: Música (con Reverb + LowPass)
- **Fx**: Efectos de sonido

**SFX Disponibles**:

- `CardDrawSfx`: Robar carta
- `CardPlaySfx`: Jugar carta
- `CardFlickSfx`: Hover
- `CardShuffleSfx`: Shuffle inicial

**Métodos**:

```gdscript
set_reverb_wet(value: float)    # 0.0-1.0
set_lowpass_freq(value: float)  # Hz
```

---

## 🎮 Flujo de Juego

### Modo Juego Local (1v3 CPU)

```
1. INICIO
   └─ MainMenu.gd
      └─ Selecciona "Jugar"
         └─ SceneManager.go_to_game()

2. CARGA
   └─ GameScreen.tscn cargada
   └─ GameMaster.init_deck()
   └─ Distribuye 7 cartas a cada jugador
   └─ Define first_player aleatorio

3. TURNO - Jugador Local (índice 0)
   ├─ GameScreen._on_GameMaster_new_round()
   ├─ Habilita clics en cartas
   ├─ Usuario selecciona carta
   ├─ GameScreen._on_card_clicked(card)
   ├─ GameMaster.play_card(0, card, color)
      ├─ Valida con can_be_played()
      ├─ Aplica efecto especial
      ├─ Avanza turno: next_turn()
   ├─ Emite: new_round
   └─ Cicloma turno siguiente (CPU)

4. TURNO - CPU (índice 1-3)
   ├─ GameMaster.cpu_play(cpu_id)
   ├─ Espera 1-3s (delay realista)
   ├─ Busca cartas jugables
   ├─ Juega aleatoria o roba si no hay
   ├─ Emite: new_round
   └─ Ciclo al siguiente

5. CONDICIONES DE VICTORIA
   ├─ Si jugador tira última carta: GANA
   ├─ Si CPU tira última carta: PIERDE
   ├─ Emite: game_over(winner_id)
      └─ GameScreen muestra GameOverScreen

6. FIN DE PARTIDA
   ├─ Mostrar ganador
   ├─ Botón "Volver al Menú"
   ├─ SceneManager.go_to_main_menu()
   └─ Limpiar estado del juego
```

### Modo Multijugador en Red

```
1. PRECONEXIÓN
   ├─ MultiplayerMenu.gd
   ├─ Host: create_server(username)
   │  └─ RoomRegistry genera código XXXX
   │  └─ Emite: server_created
   └─ Cliente: join_by_code(XXXX, username)
      └─ RoomRegistry busca IP del host
      └─ Emite: joined_server (cuando conecta)

2. SALA DE ESPERA (Lobby.tscn)
   ├─ Muestra: "Esperando jugadores..."
   ├─ Contador de conectados
   ├─ Host puede iniciar (2-5 jugadores)
   └─ Clientes esperan comando

3. INICIO DE JUEGO
   ├─ Host: NetworkManager.host_start_game()
   ├─ RPC: change_scene_to_game()
   ├─ Todos cargan GameScreen (multijugador)
   ├─ GameMaster.init_deck()
   └─ GameState sincroniza estado

4. TURNO MULTIJUGADOR - Cliente
   ├─ Usuario selecciona carta
   ├─ GameScreen.mp_request_play() [RPC al Host]
   ├─ Host valida (solo si es su turno)
   └─ Si válido: Host aplica, sincroniza

5. TURNO MULTIJUGADOR - Host
   ├─ NetworkManager._server_play_card()
   │  ├─ Obtiene peer_id del cliente
   │  ├─ Valida: ordered_ids[current_player] == peer_id
   │  ├─ GameMaster.play_card(...)
   │  ├─ Aplica lógica
   │  └─ RPC a todos: _rpc_receive_state()
   ├─ Todos reciben estado sincronizado
   └─ Ciclo siguiente

6. CONDICIÓN DE VICTORIA (Multijugador)
   ├─ Host detecta ganador
   ├─ RPC a todos: _rpc_game_over(winner_id)
   ├─ Todos muestran GameOverScreen
   └─ Opción: volver a jugar o desconectar
```

---

## 🌐 Sistema de Red

### 1. Arquitectura Host/Cliente

```
┌──────────────────┐                    ┌──────────────────┐
│   CLIENTE 1      │                    │   HOST/SERVER    │
│ (peer_id = 2)    │                    │   (peer_id = 1)  │
└────────┬─────────┘                    └─────────┬────────┘
         │                                        │
         │───────────── TCP/UDP (7777) ──────────│
         │        ENetMultiplayerPeer              │
         │                                        │
         │ RPC: mp_request_play(card)            │
         │                  ──────────────────>  │ _server_play_card()
         │                                        │
         │ RPC: _rpc_receive_state()             │
         │  <──────────────────                  │
         │                                        │
```

### 2. Discovery de Salas (UDP Broadcast)

```
CLIENT                                   HOST
  │                                       │
  ├─ UDP:7778 "FIND:1234"               │
  ├─────────────────────────────────>   │
  │                                   Listen on 7778
  │                                  Match code 1234
  │ UDP:7778 "FOUND:192.168.1.100"     │
  │ <─────────────────────────────────  │
  │                                       │
  └─ TCP:7777 connect()                 │
  ├──────────────────────────────────>  │ Accept connection
  │                                   ENetPeer created
```

### 3. Validación Anti-Trucos

**Servidor valida siempre:**

```gdscript
# En _server_play_card()
if ordered_ids[current_player] != peer_id:
    return ERROR  # Cliente intenta jugar fuera de turno

if not GameMaster.can_be_played(card):
    return ERROR  # Carta inválida
```

### 4. Sincronización de Estado

**Cada turno, Host envía:**

```gdscript
_rpc_receive_state.call_group("players", {
    "current_player": current_player,
    "current_color": current_color,
    "top_card": top_discard_card,
    "deck_size": deck.size(),
    "players_data": players_info
})
```

---

## 💻 Desarrollo

### Instalación

1. **Clonar repositorio**:

   ```bash
   git clone https://github.com/HectorHernandezCuCi/UNO-Godot-Game.git
   cd UNO-Godot-Game
   ```

2. **Abrir en Godot 4.6+**:
   - Importar proyecto en Godot
   - Esperar a que se compileln shaders
   - Presionar F5 o "Play"

### Scripts Esenciales para Desarrollo

#### GameMaster.gd (Lógica de Juego)

```gdscript
# Agregar nueva carta especial:
func apply_card_effect(card: Card) -> void:
    match card.value:
        "Skip":
            next_turn(skip=true)
        "MyNewCard":
            # Tu lógica aquí
            pass
```

#### GameScreen.gd (UI)

```gdscript
# Agregar nuevo elemento UI:
func _ready() -> void:
    # Conectar evento
    GameMaster.new_round.connect(_on_GameMaster_new_round)
```

#### NetworkManager.gd (Red)

```gdscript
# Agregar nuevo RPC:
@rpc("authority", "call_local", "reliable")
func my_custom_rpc(data: String) -> void:
    # Tu lógica
    pass
```

### Extensibilidad

**Para agregar una nueva carta especial**:

1. Crear sprite en `Assets/Cards/[Color]/`
2. Agregar metadata en `CardLogic.gd`
3. Implementar lógica en `GameMaster.apply_card_effect()`
4. Ajustar IA en `GameMaster.cpu_play()`

**Para agregar nuevo menú**:

1. Crear escena en `Scenes/Menus/[NuevoMenu]/`
2. Crear script derivado de Control
3. Conectar botones a `SceneManager.go_to_*()`
4. Actualizar flow en `MainMenu.gd`

**Para agregar persistencia**:

1. Implementar sistema de guardado en `GameState.gd`
2. Guardar en `user://` (carpeta de usuario)
3. Cargar al iniciar juego

### Debugging

**Habilitar logs detallados**:

```gdscript
# En GameMaster.gd
func play_card(player_id: int, card: Card, new_color: String) -> bool:
    print("[GAMEMASTER] Player %d plays %s" % [player_id, card.value])
    # ... resto de lógica
```

**Inspector de Red**:

- F12 en Godot para debugger
- Ver `multiplayer.get_unique_id()` en consola
- Verificar sincronización con `print(GameState.player_hands)`

**Monitor de Rendimiento**:

- Debug → Monitor
- Ver FPS, uso de memoria
- Optimizar si < 60 FPS

---

## ❓ Troubleshooting

### Red

| Problema                        | Solución                                      |
| ------------------------------- | --------------------------------------------- |
| **Clientes no encuentran host** | Verificar firewall (puerto 7777, 7778)        |
| **Timeout al conectar**         | Aumentar intentos en RoomRegistry.gd          |
| **Desconexión frecuente**       | Revisar latencia de red, aumentar timeout     |
| **RPC no llegan**               | Verificar `@rpc` decorators, peer_id correcto |

### Gameplay

| Problema                       | Solución                                |
| ------------------------------ | --------------------------------------- |
| **CPU juega carta inválida**   | Revisar `can_be_played()` en GameMaster |
| **Turno no avanza**            | Verificar `next_turn()` se ejecuta      |
| **Cartas desaparecen**         | Revisar animaciones, `queue_free()`     |
| **Mano no rota correctamente** | Ajustar curvas en HandManager           |

### Audio

| Problema                      | Solución                           |
| ----------------------------- | ---------------------------------- |
| **Música no suena**           | Verificar volumen de bus "Music"   |
| **SFX no sincroniza**         | Revisar `wait_time` en animaciones |
| **Efecto reverb distorsiona** | Bajar `set_reverb_wet()` a 0.3     |

### Visual

| Problema                       | Solución                                    |
| ------------------------------ | ------------------------------------------- |
| **Efecto 3D no aparece**       | Verificar shader compiló, material asignado |
| **Cards superpuestas**         | Revisar z-index en HandManager              |
| **UI cortada en resoluciones** | Usar Control con anchors/margins            |

---

## 📚 Referencias

### Documentación Oficial

- [Godot 4.6 Docs](https://docs.godotengine.org/)
- [GDScript Reference](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/index.html)
- [Multiplayer API](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html)

### Addons

- [Nakama SDK](https://github.com/heroiclabs/nakama-godot)
- [ENet Documentation](https://github.com/lsalzman/enet)

---

## 📝 Changelog

### v1.0 (Abril 2026)

- ✅ Lógica completa de UNO local
- ✅ Sistema multijugador con ENet
- ✅ Discovery de salas por UDP
- ✅ IA de CPU competente
- ✅ Interfaz visual profesional
- ✅ Sistema de audio completo
- ⏳ Persistencia en desarrollo
- ⏳ Nakama integration en roadmap

---

## 👨‍💼 Equipo

**Desarrollo**: Hector Alfredo Hernandez Trujillo y Ricardo Saul Razura Estrada
**Motor**: Godot Engine 4.6  
**Licencia**: [Ver LICENSE](LICENSE)

---

## 📞 Soporte

Para reportar bugs o sugerencias:

- 📧 Email: [contacto del desarrollador]
- 🐛 Issues: [GitHub Issues]
- 💬 Discussions: [GitHub Discussions]

---

**Última actualización**: 22 de Abril de 2026  
**Versión de Godot**: 4.6 WIP  
**Estado del Proyecto**: En Desarrollo Activo
