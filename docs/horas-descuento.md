# Horas a descuento — PRUEBAS

Registro persistente por fecha, equipo, turno, motivo, horas, estatus y observación. 15 motivos; Medición y Espera de medición son distintos. Otra requiere observación. Cobrar significa descuento confirmado (rojo); Pendiente requiere revisión (amarillo).

Filtros por equipo, fechas, turno y estatus. Exportación Excel y PDF con resumen separado por estatus y detalle. No se importaron registros del Excel de referencia.

Administradores pueden editar/eliminar horas, historial_operaciones y rebajas_coronas. RPC con validación de versión y auditoría transaccional. Usuarios aprobados pueden registrar horas y cambiar el estatus de registros propios. Solo administradores pueden cambiar otros campos o eliminar.

ATENCIÓN: los historiales anteriores son compartidos por las aplicaciones oficial y PRUEBAS; corregirlos afecta ambas. La tabla de horas es exclusiva ddh_pruebas_horas_descuento. No se modificó código del repositorio oficial ni movimientos de inventario.

Validado: permisos SQL con transacciones revertidas, control de versiones, auditoría; pruebas de navegador con API simulada para guardado, recarga, reintentos sin duplicación, filtros, paginación de 501 registros, edición/eliminación, exportación XLSX/PDF y móvil 390px. Datos reales conservados.
