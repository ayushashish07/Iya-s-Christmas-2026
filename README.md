# A little Christmas wishlist

## Turn on live sharing

The page is prepared for shared online storage with Supabase. To activate it:

1. Create a Supabase project.
2. In Supabase Authentication settings, enable **Anonymous sign-ins**.
3. Open the SQL Editor and run the contents of `supabase-setup.sql`.
4. In `supabase-config.js`, replace the placeholder URL and key with your project URL and **publishable** (or legacy `anon`) key. Never put a `service_role` key in this file.
5. Upload `index.html`, `supabase-config.js`, and `snowman.mp3` to the GitHub Pages site. The page will derive the invite URL from its hosted address. If you open the local file instead, also set `siteUrl` in the config to the GitHub Pages URL.
6. Open the hosted site and click **Share list**. Send the copied invite link to her. The link gives access to that shared wishlist, so only send it to people you want to have access.

After she opens the invite link, edits and uploaded photos sync between both browsers. **Download backup** and **Import list** remain available as a manual backup option.

## Song file

Add the MP3 named `snowman.mp3` beside `index.html` before uploading. The single button plays and pauses it, then repeats it after a short pause with a gentle fade-in.

## Page features

Add her photo in the hero and fill the three memory cards with favorite pictures. The portrait has a Santa hat and a softly twinkling fairy-light strand, and enlarges as it scrolls into view; soft snowfall and small holiday illustrations animate across the page. The wishlist supports adding, editing, deleting, and adding product photos or shop links. Tap a heart or swipe a wish right to favorite it; swipe left to undo. Liked wishes get a heart pop animation.
