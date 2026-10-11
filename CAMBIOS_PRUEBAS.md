# Cambios de PRUEBAS — 11 octubre 2026

- Historial: inserta versiones por contenido, evita duplicados idénticos y detiene el correo si falla el guardado. No requiere ampliar permisos de historial ni sobrescribe registros anteriores.
- Proyección: por solicitud del usuario, solo genera PDF y prepara correo. No guarda registros nuevos ni aparece en Historial. No se borran registros históricos de Supabase.
- Inventario: ajustes manuales e importaciones usan ddh_pruebas_ajustar_inventario. Actualización y movimiento en una sola transacción; detecta inventario cambiado desde la revisión. Importaciones conservan mínimos críticos.
- Correos: preferencias por usuario en ddh_pruebas_correo_config, protegidas por RLS. Se cargan al iniciar sesión en PRUEBAS desde otro dispositivo; Guardar configuración sincroniza.

La oficial operaciones-ddh sigue en commit 0204f27dfe01432f2e8da7f57142b2b479738815. Ambas aplicaciones siguen usando la misma base OPERACIONES-DDH-PRUEBAS: el stock y el historial son compartidos. La tabla nueva de configuración y la función adicional solo se usan desde este código de PRUEBAS. No se modificaron las políticas, funciones ni ajustes Auth existentes. El archivo pruebas_support.sql documenta la migración ya aplicada; no volver a ejecutarlo sobre el mismo proyecto.

Validación: node verify.cjs; pruebas de inventario (auditoría, mínimos, conflicto, rollback de lote) y RLS ejecutadas dentro de una transacción revertida. Sin registros de prueba persistidos. La revisión no incluyó una sesión interactiva en navegador.
