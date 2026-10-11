-- Additive support used only by PRUEBAS. No changes to existing policies or functions.
create table public.ddh_pruebas_correo_config (
 user_id uuid primary key references auth.users(id) on delete cascade,
 destinatarios jsonb not null default '{}'::jsonb check (jsonb_typeof(destinatarios) = 'object'),
 updated_at timestamptz not null default now()
);
alter table public.ddh_pruebas_correo_config enable row level security;
revoke all on public.ddh_pruebas_correo_config from public, anon, authenticated;
grant select, insert, update on public.ddh_pruebas_correo_config to authenticated;
create policy pruebas_correo_read on public.ddh_pruebas_correo_config for select to authenticated
 using (user_id = (select auth.uid()) and (select public.ddh_is_approved()));
create policy pruebas_correo_insert on public.ddh_pruebas_correo_config for insert to authenticated
 with check (user_id = (select auth.uid()) and (select public.ddh_is_approved()));
create policy pruebas_correo_update on public.ddh_pruebas_correo_config for update to authenticated
 using (user_id = (select auth.uid()) and (select public.ddh_is_approved()))
 with check (user_id = (select auth.uid()) and (select public.ddh_is_approved()));

-- Locks the complete batch before changing stock. A stale preview aborts the entire batch.
create function public.ddh_pruebas_ajustar_inventario(p_items jsonb, p_tipo text, p_observacion text default '')
returns integer language plpgsql security invoker set search_path = '' as $$
declare item jsonb; material public.materiales_criticos%rowtype; nuevo numeric; minimo numeric; total integer := 0;
begin
 if not public.ddh_is_admin() then raise exception 'Acceso restringido'; end if;
 if p_tipo is null or p_tipo not in ('ajuste','importacion') then raise exception 'Tipo inválido'; end if;
 if p_items is null or jsonb_typeof(p_items) <> 'array' then raise exception 'Lista inválida'; end if;
 if jsonb_array_length(p_items) < 1 or jsonb_array_length(p_items) > 1000 then raise exception 'Cantidad de ítems inválida'; end if;
 if (select count(*) <> count(distinct (v->>'id')::bigint) from jsonb_array_elements(p_items) v) then raise exception 'Material duplicado o sin ID'; end if;
 for item in select v from jsonb_array_elements(p_items) v order by (v->>'id')::bigint loop
  select * into material from public.materiales_criticos where id=(item->>'id')::bigint for update;
  if not found then raise exception 'Material no disponible'; end if;
  if item->>'expected_updated_at' is null or material.actualizado_en is distinct from (item->>'expected_updated_at')::timestamptz then
   raise exception 'El inventario cambió. Actualice y revise nuevamente antes de guardar.';
  end if;
  nuevo := (item->>'stock')::numeric;
  minimo := case when p_tipo='ajuste' and item ? 'cantidad_critica' then (item->>'cantidad_critica')::numeric else material.cantidad_critica end;
  if nuevo is null or minimo is null or nuevo < 0 or minimo < 0 or nuevo::text in ('NaN','Infinity','-Infinity') or minimo::text in ('NaN','Infinity','-Infinity') then raise exception 'Stock o mínimo inválido'; end if;
  if nuevo = material.stock and minimo = material.cantidad_critica then continue; end if;
  update public.materiales_criticos set stock=nuevo,cantidad_critica=minimo,actualizado_en=clock_timestamp() where id=material.id;
  insert into public.materiales_movimientos(material_id,tipo,cantidad,stock_anterior,stock_nuevo,observacion,usuario)
  values(material.id,p_tipo,abs(nuevo-material.stock),material.stock,nuevo,
   '[PRUEBAS] ' || coalesce(p_observacion,'') || ' | Mínimo: ' || material.cantidad_critica || ' → ' || minimo,auth.uid());
  total := total + 1;
 end loop;
 return total;
end $$;
revoke all on function public.ddh_pruebas_ajustar_inventario(jsonb,text,text) from public,anon;
grant execute on function public.ddh_pruebas_ajustar_inventario(jsonb,text,text) to authenticated;
