  -- Apply in Supabase SQL Editor as the project owner.
  -- Published page: anon may READ the published snapshot and only its approved media.
  -- Administrator allow-list is seeded out of band; browser clients never use service-role keys.
  create extension if not exists pgcrypto;
  create table if not exists public.birthday_admins(
  user_id uuid primary key references auth.users(id) on delete cascade,
  added_at timestamptz not null default now()
  );
  create table if not exists public.birthday_content(
  slot text primary key check(slot in ('draft','published')),
  payload jsonb not null check(jsonb_typeof(payload)='object'),
  updated_by uuid references auth.users(id),
  updated_at timestamptz not null default now()
  );
  create table if not exists public.birthday_media(
  id uuid primary key,
  original_path text not null unique,
  thumb_path text not null unique,
  uploaded_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
  );
  create or replace function public.birthday_is_admin()
  returns boolean language sql stable security definer set search_path=public,pg_temp
  as $$ select exists(select 1 from public.birthday_admins a where a.user_id=(select auth.uid())) $$;
  revoke all on function public.birthday_is_admin() from public;
  grant execute on function public.birthday_is_admin() to anon,authenticated;
  alter table public.birthday_admins enable row level security;
  alter table public.birthday_content enable row level security;
  alter table public.birthday_media enable row level security;
  revoke all on public.birthday_admins,public.birthday_content,public.birthday_media from anon,authenticated;
  grant select on public.birthday_admins to authenticated;
  grant select,insert,update on public.birthday_content to authenticated;
  grant select,insert,delete on public.birthday_media to authenticated;
  create policy admins_read_own on public.birthday_admins for select to authenticated using(user_id=(select auth.uid()));
  create policy content_admin_all on public.birthday_content for select to authenticated using(public.birthday_is_admin());
  create policy content_read_published on public.birthday_content for select to anon,authenticated using(slot='published');
  create policy content_draft_insert on public.birthday_content for insert to authenticated with check(slot='draft' and public.birthday_is_admin() and updated_by=(select auth.uid()));
  create policy content_draft_update on public.birthday_content for update to authenticated using(slot='draft' and public.birthday_is_admin()) with check(slot='draft' and public.birthday_is_admin() and updated_by=(select auth.uid()));
  create policy media_admin_read on public.birthday_media for select to authenticated using(public.birthday_is_admin());
  create policy media_admin_insert on public.birthday_media for insert to authenticated with check(public.birthday_is_admin() and uploaded_by=(select auth.uid()));
  create policy media_admin_delete on public.birthday_media for delete to authenticated using(public.birthday_is_admin());

  -- Replace the contents of published snapshot only via this authenticated, validating function.
  create or replace function public.publish_birthday(next jsonb)
  returns jsonb language plpgsql security definer set search_path=public,pg_temp
  as $$
  declare p jsonb; photos jsonb; memories jsonb; result jsonb; photo jsonb; memory jsonb;
  begin
  if not public.birthday_is_admin() then raise exception 'administrator access required' using errcode='42501'; end if;
  if jsonb_typeof(next)<>'object' or jsonb_typeof(next->'gallery')<>'array' or jsonb_typeof(next->'timeline')<>'array' then raise exception 'invalid birthday content'; end if;
  photos:='[]'::jsonb;
  for photo in select value from jsonb_array_elements(next->'gallery') loop
    if photo->>'published'='true' then
    if coalesce(photo->>'path','') !~* '^([0-9a-f-]{36}/original[.](jpg|png|webp|avif)|/images/gallery/[A-Za-z0-9_./-]+[.](jpg|jpeg|png|webp|avif))$' or position('..' in (photo->>'path'))>0 then raise exception 'invalid gallery photo path'; end if;
    photos:=photos||jsonb_build_array(photo);
    end if;
  end loop;
  memories:='[]'::jsonb;
  for memory in select value from jsonb_array_elements(next->'timeline') loop
    if memory->>'published'='true' and (coalesce(memory->>'photoId','')='' or exists(select 1 from jsonb_array_elements(photos) x where x->>'id'=memory->>'photoId')) then memories:=memories||jsonb_build_array(memory); end if;
  end loop;
  p:=jsonb_set(jsonb_set(next,'{gallery}',photos,true),'{timeline}',memories,true);
  insert into public.birthday_content(slot,payload,updated_by,updated_at) values('published',p,(select auth.uid()),now())
  on conflict(slot) do update set payload=excluded.payload,updated_by=excluded.updated_by,updated_at=excluded.updated_at returning payload into result;
  return result;
  end $$;
  revoke all on function public.publish_birthday(jsonb) from public;
  grant execute on function public.publish_birthday(jsonb) to authenticated;

  -- Private bucket with per-object RLS. Published references get signed links only when the
  -- reader can see their path here; draft objects remain administrator-only.
  insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
  values('birthday-photos','birthday-photos',false,10485760,array['image/jpeg','image/png','image/webp','image/avif'])
  on conflict(id) do update set public=false,file_size_limit=10485760,allowed_mime_types=array['image/jpeg','image/png','image/webp','image/avif'];
  create policy birthday_storage_read_published_or_admin on storage.objects for select to anon,authenticated using(
  bucket_id='birthday-photos' and (
    (auth.uid() is not null and public.birthday_is_admin()) or
    exists(select 1 from public.birthday_content c cross join lateral jsonb_array_elements(c.payload->'gallery') p
    where c.slot='published' and (p->>'path'=name or p->>'thumbPath'=name))
  )
  );
  create policy birthday_storage_insert_admin on storage.objects for insert to authenticated with check(bucket_id='birthday-photos' and public.birthday_is_admin());
  create policy birthday_storage_delete_admin on storage.objects for delete to authenticated using(bucket_id='birthday-photos' and public.birthday_is_admin());
