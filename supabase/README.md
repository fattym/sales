# Supabase Setup

Run [`schema.sql`](./schema.sql) in the Supabase SQL editor after you create the project.

What it creates:
- `public.users`
- `public.schools`
- `public.tasks`
- trigger to copy new `auth.users` rows into `public.users`
- backfill for existing auth users into `public.users`
- `updated_at` triggers
- row-level security policies

App expectations:
- Auth uses Supabase email/password
- `users.role` is numeric
- `1` means admin
- `2` means sales manager
- `3` means BAS
- `4` means agent
- `5` means grounds person
- admin users can update user roles
- admins can create tasks assigned to a role
- users see tasks for their role and lower tiers, plus tasks assigned to them directly
- `users.region` stores the user's assigned region when Auth metadata includes it
- BAS accounts can see users in their own region
- `schools.focusAreas` is stored as `jsonb`

Recommended setup order:
1. Create the Supabase project.
2. Run `schema.sql`.
3. Make one user an admin by updating `public.users.role` to `1`.
4. Launch the app with your Supabase credentials, or rely on the defaults already in `lib/core/config/supabase_config.dart`.

If you already had users in Supabase Auth before running the schema, the backfill step links them into `public.users` automatically.

If you need to override the defaults:
```bash
flutter run \
  --dart-define=SUPABASE_PROJECT_REF=your-project-ref \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```
