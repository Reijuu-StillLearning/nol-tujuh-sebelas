-- Allow anonymous visitors to read the published snapshot.
-- The existing RLS policy still limits this role to slot = 'published'.
grant select on public.birthday_content to anon;
