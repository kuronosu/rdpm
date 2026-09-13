#!/usr/bin/env bash
# Instala rdpm: enlaza los scripts en ~/.local/bin y añade el icono a la barra de Omarchy
#
# Uso:
#   ./install.sh              instalar (o actualizar)
#   ./install.sh --uninstall  quitar enlaces e icono (conserva máquinas y contraseñas)

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/rdpm"
SHELL_JSON="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/shell.json"
SCRIPTS=(rdpm rdpm-launch)
MODULE_ID="rdpm"

say() { printf '\033[34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[33m!!\033[0m %s\n' "$*" >&2; }

bar_module() {
  jq -n --arg id "$MODULE_ID" '{
    id: $id,
    type: "command",
    exec: "$HOME/.local/bin/rdpm status",
    interval: 3,
    onClick: "$HOME/.local/bin/rdpm-launch",
    onRightClick: "$HOME/.local/bin/rdpm-launch last",
    onMiddleClick: "$HOME/.local/bin/rdpm-launch sessions"
  }'
}

shell_json_edit() { # shell_json_edit <filtro jq> [args jq...]
  local filter="$1"; shift
  cp "$SHELL_JSON" "$SHELL_JSON.bak.$(date +%s)"
  local tmp; tmp="$(mktemp "$SHELL_JSON.XXXX")"
  jq --indent 2 "$@" "$filter" "$SHELL_JSON" > "$tmp" && mv "$tmp" "$SHELL_JSON"
}

uninstall() {
  for s in "${SCRIPTS[@]}"; do
    if [ -L "$BIN_DIR/$s" ]; then rm "$BIN_DIR/$s" && say "Eliminado $BIN_DIR/$s"; fi
  done
  if [ -f "$SHELL_JSON" ] && jq -e --arg id "$MODULE_ID" '[.. | objects | select(.id? == $id)] | length > 0' "$SHELL_JSON" >/dev/null; then
    shell_json_edit '.bar.layout |= with_entries(.value |= map(select(.id != $id)))' --arg id "$MODULE_ID"
    say "Icono quitado de la barra"
  fi
  say "Listo. Tus máquinas siguen en $CONFIG_DIR y las contraseñas en el llavero."
}

check_deps() {
  local missing=() cmd pkg
  declare -A deps=([xfreerdp3]=freerdp [gum]=gum [jq]=jq [secret-tool]=libsecret)
  for cmd in "${!deps[@]}"; do
    command -v "$cmd" >/dev/null || missing+=("${deps[$cmd]}")
  done
  if [ ${#missing[@]} -gt 0 ]; then
    say "Faltan paquetes: ${missing[*]}"
    if command -v pacman >/dev/null; then
      sudo pacman -S --needed "${missing[@]}"
    else
      warn "Instálalos con el gestor de paquetes de tu sistema y vuelve a ejecutar este script."
      exit 1
    fi
  fi
  command -v hyprctl >/dev/null || warn "No se encontró Hyprland: la gestión de sesiones no funcionará."
  if ! busctl --user list 2>/dev/null | grep -q org.freedesktop.secrets; then
    warn "No hay un servicio de llavero activo (gnome-keyring): no se podrán guardar contraseñas."
  fi
}

install() {
  check_deps

  mkdir -p "$BIN_DIR"
  for s in "${SCRIPTS[@]}"; do
    chmod +x "$REPO/bin/$s"
    if [ -e "$BIN_DIR/$s" ] && [ ! -L "$BIN_DIR/$s" ]; then
      mv "$BIN_DIR/$s" "$BIN_DIR/$s.bak.$(date +%s)"
      warn "$BIN_DIR/$s existía y se renombró como copia de seguridad"
    fi
    ln -sfn "$REPO/bin/$s" "$BIN_DIR/$s"
    say "Enlazado $BIN_DIR/$s → $REPO/bin/$s"
  done
  case ":$PATH:" in *":$BIN_DIR:"*) ;; *) warn "$BIN_DIR no está en tu PATH" ;; esac

  mkdir -p "$CONFIG_DIR"
  if [ ! -f "$CONFIG_DIR/machines.json" ]; then
    echo '[]' > "$CONFIG_DIR/machines.json"
    say "Creado $CONFIG_DIR/machines.json (vacío; añade máquinas desde el menú)"
  fi

  if [ -f "$SHELL_JSON" ]; then
    local module; module="$(bar_module)"
    if jq -e --arg id "$MODULE_ID" '[.. | objects | select(.id? == $id)] | length > 0' "$SHELL_JSON" >/dev/null; then
      # Actualiza la definición conservando la posición en la barra
      shell_json_edit '.bar.layout |= with_entries(.value |= map(if .id == $m.id then $m else . end))' --argjson m "$module"
      say "Icono de la barra actualizado"
    else
      shell_json_edit '.bar.layout.right = [$m] + (.bar.layout.right // [])' --argjson m "$module"
      say "Icono añadido a la barra (a la derecha)"
    fi
  else
    warn "No se encontró $SHELL_JSON: omito el icono de la barra (¿no es Omarchy?)"
  fi

  say "Instalación completa. Ejecuta 'rdpm' o usa el icono 󰢹 de la barra."
}

case "${1:-}" in
  --uninstall|-u) uninstall ;;
  ""|--install) install ;;
  *) echo "Uso: $0 [--uninstall]" >&2; exit 1 ;;
esac
