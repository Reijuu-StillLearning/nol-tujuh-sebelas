# Supabase setup · protected drafts, approved public copy

The source ships without credentials. **Online authentication, durable uploads and publication are not connected until you complete these steps.** Never copy a Supabase service-role/secret key into a `VITE_` variable or browser. The only frontend key is the project's public anon/publishable key; SQL/RLS is the security boundary.

1. Create a Supabase project. In **Authentication**, disable public sign-up; invite/create your one administrator account using the Supabase dashboard. Keep admin credentials private.
2. In SQL Editor, run `supabase/migrations/001_birthday.sql` as the project owner. It creates the `birthday_admins` allow-list, draft/published content rows, media inventory, private Storage bucket, and policies. It also creates `publish_birthday(next jsonb)`, which strips unpublished gallery/story items and rejects unsafe image paths before updating the public snapshot.
3. Copy your own Auth user's UUID from the Supabase dashboard and allow-list it, as project owner, with:

   `insert into public.birthday_admins(user_id) values ('YOUR-AUTH-USER-UUID');`

   Do not add more administrators unless intended. `birthday_admins` permits an authenticated user to read only their own membership row; only a project owner manages allow-list membership.
4. Copy `.env.example` to `.env.local`, and add `VITE_SUPABASE_URL=https://YOUR-PROJECT.supabase.co` plus `VITE_SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_OR_PUBLISHABLE_KEY`. Leave `VITE_DEV_LOCAL_STUDIO=false`. Restart Vite after env changes.
5. `npm install` then `npm run dev`; visit `/admin`, sign in as the allow-listed administrator, make a draft, review its responsive Preview, Save, then explicitly Publish. Run `npm run build` before deploying `dist/`.
6. Test access intentionally: an anonymous visitor should read **only** the `published` snapshot and photos it references; anonymous draft reads and all anonymous mutations/uploads must fail. An authenticated non-admin should still be unable to access drafts/write/upload. An allow-listed admin should be able to save a draft and upload; only an explicit publish action should update the public snapshot. Verify object-name/path restrictions and failed uploads. Re-run these checks if policies change.

## Deploy to Vercel

This repository includes [`vercel.json`](./vercel.json), which runs the production build, publishes `dist/`, and rewrites direct `/admin` navigation to the Vite entry page. Vercel's static asset handling still serves files from `dist/` normally.

1. Import the repository into Vercel. Keep the detected framework as Vite, or use `npm run build` as the build command and `dist` as the output directory.
2. Add these **Production** environment variables in the Vercel project settings:
   - `VITE_SUPABASE_URL`: your Supabase project URL.
   - `VITE_SUPABASE_ANON_KEY`: the public anon/publishable key only.
   - `VITE_DEV_LOCAL_STUDIO`: `false`.
3. Add the same variables to **Preview** only if preview deployments should connect to the same Supabase project. Never add a service-role/secret key; every `VITE_` value is bundled into browser code.
4. Deploy, then verify `/`, `/admin`, and a browser refresh on `/admin`. The admin page must show the login/setup lock until a valid allow-listed Supabase user signs in.
5. In Supabase, add the deployed site URL to Authentication URL configuration if required by the selected auth flow. Use the final HTTPS domain for production and avoid enabling the unauthenticated local editor.
6. Run the production smoke test: anonymous public read, admin login, draft save, private photo upload, explicit publish, and anonymous visibility of only the published result.

Vercel does not host the Supabase database, Auth, or private Storage bucket. Execute the SQL migration and create the administrator in Supabase before expecting `/admin` to work online. A successful Vercel build alone does not prove that RLS, Auth, Storage, or publishing are configured correctly.

## What is public

`public/` files are served without authentication. Do not use it for private/unpublished photographs. Supabase uploads go to the **private** `birthday-photos` bucket as immutable, random-UUID-named originals and generated WebP thumbnails. Metadata stores paths—not image bytes—in Postgres. Only photos referenced in the published snapshot can be signed for anonymous read. The generated links last up to one hour, so an already-issued published image link can remain usable until it expires even if the snapshot is changed; treat selected published photographs as public while current. Unpublished photo paths are never placed in the public JSON snapshot or signed anonymously.

An attempted removal in Studio asks for confirmation first. Supabase admin membership is enforced again by table/storage RLS; hiding an item from the snapshot is not the same as permanently erasing an uploaded storage object. Deployment, project ownership, keys and live policy tests require your Supabase credentials; this source generator did not run against a real project.

## Browser-only sandbox fallback

For localhost development *only*, copy `.env.example` to `.env.local` and set `VITE_DEV_LOCAL_STUDIO=true`. This opens an explicitly **unauthenticated, unencrypted, browser-local** editor and saves drafts and images in IndexedDB/localStorage on that one browser. It is not access control, does not publish or sync, and disappears if browser storage is cleared. Leave it **false** on any network, preview URL, or production deployment. With no backend and the flag off, `/admin` displays a setup lock; it never treats an obscure URL as authentication.
