-- PRUEBAS: registro independiente. Los historiales existentes comparten base con la app oficial.
create table public.ddh_pruebas_horas_descuento (
 id uuid primary key default gen_random_uuid(),
 fecha date not null,
 equipo text not null check (equipo in ('CH1-83','CH1-133','CH1-135','CH1-140','CH1-141','CH1-142','CH1-143','CH1-154','CH1-155','CH1-156','CH1-159','CH1-160','CH1-161','CH1-162','CH9-63','CH1-120','CH1-144','CH1-158','CH1-146')),
 turno text not null check (turno in ('A','B')),
 motivo text not null check (motivo in ('Mantención Preventiva','Reparación fuera de plan','Espera de accesos cliente','Espera por condición climática','Espera de instrucciones','Espera de conductor','Espera de equipo de apoyo','Espera de Mecánico','Espera por personal','Espera por tronadura','Espera de agua','Espera de combustible','Espera de medición','Medición','Otra')),
 horas numeric not null check(horas>0 and horas<=24 and horas=round(horas,2)),
 estatus text not null default 'Pendiente' check(estatus in ('Cobrar','Pendiente')),
 observacion text not null default '' check(length(observacion)<=2000) check(motivo<>'Otra' or length(trim(observacion))>0) check(motivo<>'Otra' or length(trim(observacion))>0) check(motivo<>'Otra' or length(trim(observacion))>0) check(motivo<>'Otra' or length(trim(observacion))>0) check(motivo<>'Otra' or length(trim(observacion))>0) check(motivo<>'Otra' or length(trim(observacion))>0),
 created_by uuid not null default auth.uid() references auth.users(id),
 cuenta_usuario text not null default (auth.jwt()->>'email'),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 revisiones jsonb not null default '[]'::jsonb
);
create index ddh_horas_fecha_idx on public.ddh_pruebas_horas_descuento(fecha desc,created_at desc,id desc);
create index ddh_horas_equipo_fecha_idx on public.ddh_pruebas_horas_descuento(equipo,fecha desc);
create index ddh_horas_autor_idx on public.ddh_pruebas_horas_descuento(created_by);
alter table public.ddh_pruebas_horas_descuento enable row level security;
revoke all on public.ddh_pruebas_horas_descuento from public,anon,authenticated;
grant select on public.ddh_pruebas_horas_descuento to authenticated;
grant insert(id,fecha,equipo,turno,motivo,horas,estatus,observacion) on public.ddh_pruebas_horas_descuento to authenticated;
grant update(fecha,equipo,turno,motivo,horas,estatus,observacion) on public.ddh_pruebas_horas_descuento to authenticated;
grant delete on public.ddh_pruebas_horas_descuento to authenticated;
create policy hd_read on public.ddh_pruebas_horas_descuento for select to authenticated using ((select public.ddh_is_approved()));
create policy hd_insert on public.ddh_pruebas_horas_descuento for insert to authenticated with check ((select public.ddh_is_approved()) and created_by=(select auth.uid()));
create policy hd_update on public.ddh_pruebas_horas_descuento for update to authenticated using ((select public.ddh_is_approved()) and (created_by=(select auth.uid()) or (select public.ddh_is_admin()))) with check ((select public.ddh_is_approved()) and (created_by=(select auth.uid()) or (select public.ddh_is_admin())));
create policy hd_delete on public.ddh_pruebas_horas_descuento for delete to authenticated using ((select public.ddh_is_admin()));
create function public.ddh_horas_version() returns trigger language plpgsql security invoker set search_path='' as $$
begin
 if not public.ddh_is_admin() and (to_jsonb(new)-array['estatus','updated_at','revisiones']) is distinct from (to_jsonb(old)-array['estatus','updated_at','revisiones']) then raise exception 'Solo un administrador puede modificar los datos del registro.' using errcode='42501'; end if;
 new.updated_at=clock_timestamp();
 new.revisiones=old.revisiones||jsonb_build_array(jsonb_build_object('fecha',new.updated_at,'usuario',auth.uid(),'antes',to_jsonb(old)-'revisiones','estatus_nuevo',new.estatus));
 return new;
end $$;
revoke all on function public.ddh_horas_version() from public,anon,authenticated;
create trigger ddh_horas_version before update on public.ddh_pruebas_horas_descuento for each row execute function public.ddh_horas_version();

-- Administración del historial general, coronas y horas. Sin modificar movimientos de inventario.
alter table public.historial_operaciones add column if not exists updated_at timestamptz not null default now();
alter table public.rebajas_coronas add column if not exists updated_at timestamptz not null default now();
create function public.ddh_historial_version() returns trigger language plpgsql security invoker set search_path='' as $$ begin new.updated_at=clock_timestamp();return new;end $$;
revoke all on function public.ddh_historial_version() from public,anon,authenticated;
create trigger ddh_historial_version before update on public.historial_operaciones for each row execute function public.ddh_historial_version();
create trigger ddh_coronas_version before update on public.rebajas_coronas for each row execute function public.ddh_historial_version();
grant update(tipo,fecha,equipo,pozo,sector_origen,sector_destino,sector,supervisor,jefe_faena,detalle,estado,datos),delete on public.historial_operaciones to authenticated;
grant update(equipo,pozo,serie_corona,id_corona,fondo_inicial,fondo_final,tipo_desgaste,vida_util),delete on public.rebajas_coronas to authenticated;
create policy ddh_admin_history_update on public.historial_operaciones for update to authenticated using ((select public.ddh_is_admin())) with check ((select public.ddh_is_admin()));
create policy ddh_admin_history_delete on public.historial_operaciones for delete to authenticated using ((select public.ddh_is_admin()));
create policy ddh_admin_coronas_update on public.rebajas_coronas for update to authenticated using ((select public.ddh_is_admin())) with check ((select public.ddh_is_admin()));
create policy ddh_admin_coronas_delete on public.rebajas_coronas for delete to authenticated using ((select public.ddh_is_admin()));
create table public.ddh_admin_historial_cambios (
 id uuid primary key default gen_random_uuid(),tabla text not null,registro_id text not null,
 accion text not null check(accion in ('editar','eliminar')),antes jsonb not null,despues jsonb,
 usuario uuid not null default auth.uid() references auth.users(id),fecha timestamptz not null default now()
);
alter table public.ddh_admin_historial_cambios enable row level security;
revoke all on public.ddh_admin_historial_cambios from public,anon,authenticated;
grant select,insert on public.ddh_admin_historial_cambios to authenticated;
create index ddh_admin_cambios_usuario_idx on public.ddh_admin_historial_cambios(usuario);
create policy ddh_admin_cambios_read on public.ddh_admin_historial_cambios for select to authenticated using ((select public.ddh_is_admin()));
create policy ddh_admin_cambios_insert on public.ddh_admin_historial_cambios for insert to authenticated with check ((select public.ddh_is_admin()) and usuario=(select auth.uid()));
create function public.ddh_pruebas_admin_historial(p_tabla text,p_id text,p_version timestamptz,p_accion text,p_datos jsonb default '{}'::jsonb)
returns jsonb language plpgsql security invoker set search_path='' as $$
declare allowed text[];prev jsonb;result jsonb;sets text;k text;
begin
 if not public.ddh_is_admin() then raise exception 'Acceso exclusivo para administradores.' using errcode='42501';end if;
 case p_tabla
 when 'historial_operaciones' then allowed=array['tipo','fecha','equipo','pozo','sector_origen','sector_destino','sector','supervisor','jefe_faena','detalle','estado','datos'];
 when 'rebajas_coronas' then allowed=array['equipo','pozo','serie_corona','id_corona','fondo_inicial','fondo_final','tipo_desgaste','vida_util'];
 when 'ddh_pruebas_horas_descuento' then allowed=array['fecha','equipo','turno','motivo','horas','estatus','observacion'];
 else raise exception 'Historial no permitido.';end case;
 if p_accion not in ('editar','eliminar') or p_accion is null then raise exception 'Acción inválida.';end if;
 execute format('select to_jsonb(t) from public.%I t where id::text=$1 for update',p_tabla) into prev using p_id;
 if prev is null then raise exception 'El registro ya no existe.';end if;
 if p_version is null or (prev->>'updated_at')::timestamptz<>p_version then raise exception 'El registro cambió. Cierre y vuelva a consultar antes de editar.';end if;
 if p_accion='eliminar' then
  execute format('delete from public.%I where id::text=$1',p_tabla) using p_id;
 else
  if p_datos is null or jsonb_typeof(p_datos)<>'object' or p_datos='{}'::jsonb then raise exception 'Complete los datos.';end if;
  for k in select jsonb_object_keys(p_datos) loop
   if not k=any(allowed) then raise exception 'Campo no permitido: %',k;end if;
   sets=concat_ws(',',sets,format('%I=(jsonb_populate_record(null::public.%I,$1)).%I',k,p_tabla,k));
  end loop;
  execute format('update public.%I t set %s where id::text=$2 returning to_jsonb(t)',p_tabla,sets) into result using p_datos,p_id;
 end if;
 insert into public.ddh_admin_historial_cambios(tabla,registro_id,accion,antes,despues) values(p_tabla,p_id,p_accion,prev,result);
 return jsonb_build_object('ok',true,'registro',result);
end $$;
revoke all on function public.ddh_pruebas_admin_historial(text,text,timestamptz,text,jsonb) from public,anon;
grant execute on function public.ddh_pruebas_admin_historial(text,text,timestamptz,text,jsonb) to authenticated;

-- Acceso exclusivo para administradores (actualización).
alter policy hd_read on public.ddh_pruebas_horas_descuento using ((select public.ddh_is_admin()));
alter policy hd_insert on public.ddh_pruebas_horas_descuento with check ((select public.ddh_is_admin()) and created_by=(select auth.uid()));
alter policy hd_update on public.ddh_pruebas_horas_descuento using ((select public.ddh_is_admin())) with check ((select public.ddh_is_admin()));
