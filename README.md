# DesktopOverlay

Herramienta para establecer un fondo de pantalla personalizado en equipos macOS donde el wallpaper está restringido por un perfil MDM corporativo.

## Cómo funciona

El perfil MDM bloquea el mecanismo nativo de wallpaper (`com.apple.desktop`), pero no impide que aplicaciones del usuario creen ventanas a nivel de escritorio. DesktopOverlay coloca una ventana borderless, invisible al mouse, por encima del wallpaper pero debajo de todas las aplicaciones. El resultado visual es indistinguible de un fondo de pantalla real.

## Requisitos

- macOS Sonoma 14 o posterior.
- Una imagen ubicada en `~/Documents/wallpaper/` con nombre `index` en cualquiera de estos formatos: `.jpg`, `.jpeg`, `.png`, `.heic`, `.tiff`, `.bmp`, `.gif`, `.webp`.
- No se requieren permisos de administrador.

## Estructura de archivos

```
~/Documents/wallpaper/
├── DesktopOverlay          # Binario compilado
├── DesktopOverlay.swift    # Código fuente
├── index.jpg               # Tu imagen de fondo (cualquier formato soportado)
├── overlay.log             # Log de ejecución
└── README.md               # Este archivo
```

---

## Uso

### Ejecutar una sola vez (sesión actual)

Lanza el overlay manualmente. Se mantendrá activo hasta que cierres sesión o lo detengas:

```bash
~/Documents/wallpaper/DesktopOverlay &
```

> El `&` al final envía el proceso a segundo plano para que puedas seguir usando la terminal.

### Detener el overlay

**Si lo ejecutaste manualmente:**

1. Busca el PID del proceso:

   ```bash
   ps aux | grep '[D]esktopOverlay'
   ```

2. Detén el proceso usando el PID que aparece en la segunda columna:

   ```bash
   kill <PID>
   ```

**Si está corriendo como Launch Agent (ver sección siguiente):**

```bash
launchctl unload ~/Library/LaunchAgents/com.user.desktopoverlay.plist
```

Esto lo detiene inmediatamente. El overlay **no** volverá a ejecutarse hasta que lo cargues de nuevo o reinicies sesión (si el plist sigue instalado).

---

### Ejecutar automáticamente al hacer login (persistente a reinicios)

1. Copia el archivo de configuración del Launch Agent (si aún no existe):

   ```bash
   cat > ~/Library/LaunchAgents/com.user.desktopoverlay.plist << 'EOF'
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>Label</key>
       <string>com.user.desktopoverlay</string>
       <key>ProgramArguments</key>
       <array>
           <string>/Users/xmf5239/Documents/wallpaper/DesktopOverlay</string>
       </array>
       <key>RunAtLoad</key>
       <true/>
       <key>KeepAlive</key>
       <true/>
       <key>StandardOutPath</key>
       <string>/Users/xmf5239/Documents/wallpaper/overlay.log</string>
       <key>StandardErrorPath</key>
       <string>/Users/xmf5239/Documents/wallpaper/overlay.log</string>
   </dict>
   </plist>
   EOF
   ```

2. Carga el agente:

   ```bash
   launchctl load ~/Library/LaunchAgents/com.user.desktopoverlay.plist
   ```

3. Verifica que esté corriendo:

   ```bash
   launchctl list | grep desktopoverlay
   ```

   Deberás ver una línea con el PID y el label `com.user.desktopoverlay`.

A partir de ahora, el overlay se ejecutará automáticamente cada vez que inicies sesión y se reiniciará si el proceso se cierra inesperadamente (gracias a `KeepAlive`).

### Remover del login automático

Para que el overlay deje de ejecutarse al iniciar sesión:

1. Descarga el agente (esto también detiene el proceso activo):

   ```bash
   launchctl unload ~/Library/LaunchAgents/com.user.desktopoverlay.plist
   ```

2. Elimina el archivo plist:

   ```bash
   rm ~/Library/LaunchAgents/com.user.desktopoverlay.plist
   ```

---

### Cambiar la imagen de fondo de pantalla

Simplemente reemplaza el archivo `index.*` en `~/Documents/wallpaper/` con tu nueva imagen:

```bash
cp /ruta/a/mi_nueva_imagen.jpg ~/Documents/wallpaper/index.jpg
```

La app vigila la carpeta y **detecta cambios automáticamente**; no necesitas reiniciarla. Si cambias el formato (por ejemplo de `.jpg` a `.png`), asegúrate de eliminar el archivo anterior:

```bash
rm ~/Documents/wallpaper/index.jpg
cp /ruta/a/mi_nueva_imagen.png ~/Documents/wallpaper/index.png
```

La imagen se escala proporcionalmente para cubrir la pantalla, centrada, con barras negras si la relación de aspecto no coincide. Para mejores resultados usa imágenes con resolución igual o superior a la de tu pantalla.

---

## Recompilar desde el código fuente

Si modificas `DesktopOverlay.swift`, recompila con:

```bash
swiftc ~/Documents/wallpaper/DesktopOverlay.swift \
  -o ~/Documents/wallpaper/DesktopOverlay \
  -framework AppKit
```

Si el Launch Agent está activo, recárgalo para usar el nuevo binario:

```bash
launchctl unload ~/Library/LaunchAgents/com.user.desktopoverlay.plist
launchctl load  ~/Library/LaunchAgents/com.user.desktopoverlay.plist
```

## Desinstalación completa

```bash
launchctl unload ~/Library/LaunchAgents/com.user.desktopoverlay.plist 2>/dev/null
rm -f ~/Library/LaunchAgents/com.user.desktopoverlay.plist
rm -rf ~/Documents/wallpaper/DesktopOverlay
rm -rf ~/Documents/wallpaper/DesktopOverlay.swift
rm -rf ~/Documents/wallpaper/overlay.log
rm -rf ~/Documents/wallpaper/README.md
```

> La imagen `index.*` no se elimina para que no pierdas tu fondo personalizado.
