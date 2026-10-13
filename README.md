# Birthday Studio · private-in-spirit, personal by design

A responsive, multi-chapter birthday love letter for **November 7, 2026**, plus `/admin`, a small gallery and content editor. The sample words and six botanical photo placeholders are editable examples—not actual shared memories. Replace them with your own writing and photos before sharing.

## Start locally

1. Install Node.js 20+.
2. In this folder run `npm install`, then `npm run dev`. The setup script turns `index.html.template` into Vite's entry HTML automatically. `npm run build` runs strict TypeScript and creates `dist/`; `npm run preview` serves a local build.
3. Open the URL Vite prints. Public experience: `/`. Birthday Studio: `/admin`.

## Deploy to Vercel

The project is a Vite static application and includes [`vercel.json`](./vercel.json) for the production build, `dist` output, and direct `/admin` SPA navigation. Import the repository into Vercel and configure:

- `VITE_SUPABASE_URL` with your Supabase project URL.
- `VITE_SUPABASE_ANON_KEY` with the public anon/publishable key only.
- `VITE_DEV_LOCAL_STUDIO=false`.

Run the Supabase migration and administrator allow-list setup from [`README-backend.md`](./README-backend.md) before testing the online editor. Never deploy the local unauthenticated editor or a Supabase service-role/secret key. After deployment, verify `/`, `/admin`, a refreshed `/admin` URL, administrator login, and explicit publish behavior.

No starter project or personal images were attached, so this project was created from scratch. The Supabase client/auth/migration integration is described in `README-backend.md` once configured. **Without Supabase credentials, online sign-in, cross-device persistence, protected uploads, and publishing do not work.** A deliberately opt-in development editor can be enabled on *localhost only* with `VITE_DEV_LOCAL_STUDIO=true` in `.env.local`; it stores drafts/photos in this browser only. This editor has **no login and no security boundary**, clears if browser site data is removed, and must never be deployed. Set the flag to `false` for previews and production. In unconfigured or deployed builds `/admin` is a locked setup screen, not falsely represented as authenticated.

## Personalize, without touching components

`src/data/birthday.ts` holds the `Content` TypeScript types and the sole editable sample configuration: her name, your signature, timezone/target birthday, hero and introduction, photo captions/alt/date, story memories, little notes, letter paragraphs, wishes, music and final note. Entries explicitly marked as example/placeholders are meant to be replaced. A filled caption, placeholder date or “Your date here” are demonstrations; do not leave invented-looking memories in the final version.

- Add **public** photos to `public/images/gallery/`, then set the corresponding `gallery[].path`, `caption`, `alt`, `date` and `description`. Use WebP/JPEG under about 10 MB, width 1600–2400px. Public-folder files are accessible without authentication; never store unpublished/private images there. Missing image paths resolve to the site's own delicate drawn placeholder.
- Authenticated uploads should instead use Birthday Studio and the private Supabase Storage bucket. Add a local song as `public/audio/our-song.mp3` and set `music.enabled=true`, `music.path`, and `music.title`. Music playback always requires a tap.
- Change `birthdayDate` in ISO `YYYY-MM-DD` format and `timezone` as an IANA name (sample: `Asia/Jakarta`). At midnight on the local birthday the countdown becomes a celebration; from the following local day it shows a quiet afterglow.
- The component/layout code is in `src/components/Experience.tsx`, stylesheet in `src/styles.css`, and route/editor in `src/main.tsx`. Type definitions are in the config.

## Birthday Studio

An Overview, Photos, Our story, The letter, Wishes, Settings, and Preview are provided. Local mode includes browser-persistent drafts and images, multi-file selection, captions, dates, alt text, ordering, publishing toggles and the editorial content forms. Preview is rendered inside a phone or desktop frame and passes the draft over `postMessage`—it does not add unpublished values to the public endpoint. When connected, Supabase authentication + the admin allow-list and RLS determine the permitted operations; only authenticated administrators save/upload/publish. The public visitor endpoint serves the published snapshot only.

## Accessibility / animation

Native scrolling, high-contrast text and visible keyboard focus; arrow/Escape lightbox controls, focus trapping and background-scroll lock; tablet/mobile breakpoints including 320 px; touch-operable actions; reduced-motion mode that quiets transitions, particles and scroll effects. No auto-music and no remote stock/memory images. `npm test` includes IANA boundary checks. Real-image layout and Supabase behavior need a project-owner visual QA once assets/configuration are supplied.
