# rdpm

Gestor de conexiones de escritorio remoto (RDP) para [Omarchy](https://omarchy.org/) / Hyprland, basado en FreeRDP 3.

- Registro de máquinas (host, puerto, dominio, usuario, carpeta compartida)
- Contraseñas guardadas en el llavero del sistema (gnome-keyring), nunca en texto plano ni en la línea de comandos
- Menú interactivo con [gum](https://github.com/charmbracelet/gum)
- Gestión de sesiones abiertas: ir a la ventana, desconectar
- Icono en la barra de Omarchy con el número de sesiones activas

## Instalación

```bash
git clone git@github.com:kuronosu/rdpm.git ~/Work/rdpm
cd ~/Work/rdpm
./install.sh
```

El instalador:

1. Instala las dependencias que falten (`freerdp`, `gum`, `jq`, `libsecret`) con `pacman`.
2. Enlaza `bin/rdpm` y `bin/rdpm-launch` en `~/.local/bin` (son enlaces simbólicos: un `git pull` actualiza todo).
3. Crea `~/.config/rdpm/machines.json` si no existe.
4. Añade el icono a la barra de Omarchy (`~/.config/omarchy/shell.json`, con copia de seguridad).

Para desinstalar: `./install.sh --uninstall` (conserva máquinas y contraseñas).

## Uso

### Icono de la barra 󰢹

| Acción | Resultado |
|---|---|
| Clic izquierdo | Menú de máquinas (conectar, añadir, editar, eliminar) |
| Clic derecho | Conectar a la última máquina usada |
| Clic central | Sesiones activas |

### Terminal

```bash
rdpm                      # menú
rdpm connect <nombre>     # conectar
rdpm last                 # conectar a la última
rdpm sessions             # sesiones activas
rdpm add                  # añadir máquina
rdpm edit <nombre>        # editar máquina
rdpm remove <nombre>      # eliminar máquina
rdpm list                 # listar máquinas
rdpm status               # estado en JSON (usado por la barra)
```

### Atajos dentro de la ventana RDP

| Atajo | Acción |
|---|---|
| Ctrl derecho | Soltar / capturar el teclado |
| Ctrl + Alt + Enter | Pantalla completa |
| Ctrl + Alt + Fin | Enviar Ctrl+Alt+Supr a Windows |

**Desconectar** (cerrar la ventana) deja la sesión abierta en Windows.
Para **cerrar sesión**, hazlo desde Windows: *Inicio → usuario → Cerrar sesión*.

## Datos

| Qué | Dónde |
|---|---|
| Máquinas | `~/.config/rdpm/machines.json` |
| Contraseñas | Llavero: `secret-tool search service rdpm` |
| Última máquina | `~/.local/state/rdpm/last` |
| Logs de conexión | `~/.local/state/rdpm/<nombre>.log` |
| Certificados aceptados | `~/.config/freerdp/server/` |

Formato de `machines.json`:

```json
[
  { "name": "oficina", "host": "192.168.1.10", "port": 3389, "user": "juan", "domain": "EMPRESA", "share": "~/RDP" }
]
```

Las máquinas y las contraseñas **no** se guardan en este repositorio. Para llevar las máquinas a otro equipo, copia `machines.json`; las contraseñas se piden al conectar la primera vez.

## Carpeta compartida

Cada máquina puede compartir **una carpeta de Linux** con Windows (campo `share`):

- Vacío: no se comparte nada (por defecto).
- Una ruta, p. ej. `~/RDP`: se crea si no existe y en Windows aparece en *Este equipo* como **"RDP en &lt;tu equipo&gt;"**, o en `\\tsclient\RDP`.

Windows tiene **lectura y escritura** sobre esa carpeta mientras dure la conexión, así que evita compartir el home entero: expondría `~/.ssh`, tokens y el resto de tu configuración a cualquier programa de la máquina remota. Para pasar texto o archivos sueltos también sirve el portapapeles.

## Opciones de FreeRDP

Cada conexión usa: certificados TOFU, autenticación solo NTLM (sin Kerberos), resolución dinámica, H.264 (AVC444), audio y micrófono, portapapeles compartido, la carpeta compartida configurada y reconexión automática. Se ajustan en la función `connect` de `bin/rdpm`.
