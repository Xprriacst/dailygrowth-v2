create table if not exists public.web_push_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  endpoint text not null unique,
  keys jsonb not null,
  platform text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists web_push_subscriptions_user_endpoint_idx
  on public.web_push_subscriptions(user_id, endpoint);

create trigger set_timestamp_web_push_subscriptions
  before update on public.web_push_subscriptions
  for each row
  execute procedure trigger_set_timestamp();

alter table public.web_push_subscriptions enable row level security;

create policy "Users can manage their subscriptions"
  on public.web_push_subscriptions
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
