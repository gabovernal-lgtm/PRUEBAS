create table public.ddh_primeras_alertas (
 id uuid primary key default gen_random_uuid(),
 fecha date not null, equipo text not null, titulo text not null check(length(titulo) between 1 and 160),
 datos jsonb not null check(jsonb_typeof(datos)='object' and octet_length(datos::text)<900000),
 created_by uuid not null default auth.uid() references auth.users(id),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
alter table public.ddh_primeras_alertas enable row level security;
revoke all on public.ddh_primeras_alertas from anon, authenticated;
grant select, insert on public.ddh_primeras_alertas to authenticated;
grant update(fecha,equipo,titulo,datos) on public.ddh_primeras_alertas to authenticated;
grant delete on public.ddh_primeras_alertas to authenticated;
create policy pa_read on public.ddh_primeras_alertas for select to authenticated using (public.ddh_is_approved());
create policy pa_insert on public.ddh_primeras_alertas for insert to authenticated with check(public.ddh_is_approved() and created_by=(select auth.uid()));
create policy pa_update on public.ddh_primeras_alertas for update to authenticated using(public.ddh_is_admin()) with check(public.ddh_is_admin());
create policy pa_delete on public.ddh_primeras_alertas for delete to authenticated using(public.ddh_is_admin());
create index pa_creator_fecha on public.ddh_primeras_alertas(created_by,fecha desc);
create function public.ddh_pa_timestamp() returns trigger language plpgsql security invoker set search_path='' as $$ begin new.updated_at=clock_timestamp();return new;end $$;
create trigger pa_timestamp before update on public.ddh_primeras_alertas for each row execute function public.ddh_pa_timestamp();
