-- Run this once in the Supabase SQL Editor for the wishlist project.
-- The app signs visitors in anonymously. Access to each list is granted only
-- after a visitor joins with that list's unguessable invite token.

create extension if not exists pgcrypto with schema extensions;

create table if not exists public.wishlist_rooms (
  id uuid primary key default gen_random_uuid(),
  data jsonb not null default '{}'::jsonb,
  invite_token text not null unique,
  created_by uuid not null references auth.users(id) on delete cascade,
  updated_at timestamptz not null default now()
);

create table if not exists public.wishlist_room_members (
  room_id uuid not null references public.wishlist_rooms(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (room_id, user_id)
);

alter table public.wishlist_rooms enable row level security;
alter table public.wishlist_room_members enable row level security;

revoke all on table public.wishlist_rooms from anon, authenticated;
revoke all on table public.wishlist_room_members from anon, authenticated;
grant select (id, data) on table public.wishlist_rooms to authenticated;
grant update (data, updated_at) on table public.wishlist_rooms to authenticated;
grant select on table public.wishlist_room_members to authenticated;

drop policy if exists "room members can read their room" on public.wishlist_rooms;
create policy "room members can read their room"
  on public.wishlist_rooms for select to authenticated
  using (
    exists (
      select 1 from public.wishlist_room_members m
      where m.room_id = id and m.user_id = (select auth.uid())
    )
  );

drop policy if exists "room members can update their room" on public.wishlist_rooms;
create policy "room members can update their room"
  on public.wishlist_rooms for update to authenticated
  using (
    exists (
      select 1 from public.wishlist_room_members m
      where m.room_id = id and m.user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1 from public.wishlist_room_members m
      where m.room_id = id and m.user_id = (select auth.uid())
    )
  );

drop policy if exists "users can read their own memberships" on public.wishlist_room_members;
create policy "users can read their own memberships"
  on public.wishlist_room_members for select to authenticated
  using (user_id = (select auth.uid()));

create or replace function public.create_wishlist_room(p_data jsonb)
returns table (room_id uuid, invite_token text)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_room_id uuid := gen_random_uuid();
  v_invite_token text := encode(extensions.gen_random_bytes(32), 'hex');
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'Sign in is required to create a shared wishlist';
  end if;

  insert into public.wishlist_rooms (id, data, invite_token, created_by)
  values (v_room_id, coalesce(p_data, '{}'::jsonb), v_invite_token, v_user_id);

  insert into public.wishlist_room_members (room_id, user_id)
  values (v_room_id, v_user_id);

  return query select v_room_id, v_invite_token;
end;
$$;

create or replace function public.join_wishlist_room(p_invite_token text)
returns table (room_id uuid, data jsonb)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_room_id uuid;
  v_data jsonb;
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'Sign in is required to join a shared wishlist';
  end if;

  select r.id, r.data into v_room_id, v_data
  from public.wishlist_rooms r
  where r.invite_token = p_invite_token;

  if v_room_id is null then
    raise exception 'This wishlist invite link is invalid or expired';
  end if;

  insert into public.wishlist_room_members (room_id, user_id)
  values (v_room_id, v_user_id)
  on conflict (room_id, user_id) do nothing;

  return query select v_room_id, v_data;
end;
$$;

revoke all on function public.create_wishlist_room(jsonb) from public, anon;
revoke all on function public.join_wishlist_room(text) from public, anon;
grant execute on function public.create_wishlist_room(jsonb) to authenticated;
grant execute on function public.join_wishlist_room(text) to authenticated;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'wishlist_rooms'
  ) then
    execute 'alter publication supabase_realtime add table public.wishlist_rooms';
  end if;
end;
$$;
