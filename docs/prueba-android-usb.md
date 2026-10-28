# Prueba en un celular Android por USB

1. Iniciar Docker Desktop y ejecutar `docker compose up -d` desde la raíz del proyecto.
2. Comprobar que `http://localhost:3000/api-docs` abre en la computadora.
3. Conectar el celular con depuración USB habilitada y aceptar la autorización.
4. Ejecutar `adb devices` y luego `adb -s SERIAL reverse tcp:3000 tcp:3000`, reemplazando `SERIAL` por el identificador del celular. Si `adb` no está en PATH, usar el ejecutable de `platform-tools` del Android SDK.
5. En Android Studio, abrir `main.dart → Edit Configurations` y establecer en **Additional run args**:

   ```text
   --dart-define=API_BASE_URL=http://localhost:3000
   ```

6. Seleccionar el celular, detener la app y volver a ejecutarla. Hot Reload no aplica cambios de `--dart-define`.

Mantener el cable conectado. Tras reconectar el celular puede ser necesario repetir `adb reverse`. La configuración de `.idea/` es local y no se incluye en Git.

## Validación GPS

El seed `sql/02_seed_login.sql` configura la sede de prueba en latitud `-12.06497`, longitud `-75.20384`, con radio de 50 metros. Habilitar la ubicación precisa en el celular.

El seed solo inserta la sede si no existe: editarlo, reaplicarlo o reiniciar Docker no actualiza las coordenadas de una sede existente. En una base de desarrollo existente, aplicar explícitamente:

```sql
UPDATE sedes
SET latitud = -12.06497, longitud = -75.20384, radio_permitido_metros = 50
WHERE nombre = 'Sede Principal Lima';
```

Comprobar los valores guardados antes de volver a pulsar **Validar mi ubicación**. No es necesario borrar el volumen de MySQL.
