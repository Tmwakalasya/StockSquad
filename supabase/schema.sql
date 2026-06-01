-- StockSquad — Phase 3, Slice 1: realtime squad chat
-- Paste this whole file into your Supabase project's SQL Editor and hit "Run".
--
-- What it sets up:
--   • a `messages` table (the chat history)
--   • Row Level Security so people can only post AS THEMSELVES
--   • realtime, so new messages stream live to everyone in the squad
--
-- Design note: each message carries the sender's name + emoji directly
-- (denormalized). That keeps realtime dead simple — an incoming message row
-- already has everything we need to draw the bubble, no extra lookups.

-- 1) The table -------------------------------------------------------------
create table if not exists public.messages (
    id            uuid        primary key default gen_random_uuid(),
    sender_id     uuid        not null references auth.users (id) on delete cascade,
    sender_name   text        not null,
    sender_avatar text        not null default '🦅',
    content       text        not null check (char_length(content) between 1 and 2000),
    created_at    timestamptz not null default now()
);

-- Fetch newest-last efficiently.
create index if not exists messages_created_at_idx on public.messages (created_at);

-- 2) Row Level Security ----------------------------------------------------
-- With RLS on, NOTHING is readable/writable until a policy explicitly allows it.
alter table public.messages enable row level security;

-- Anyone signed in (even anonymously) can read the whole chat.
create policy "Authenticated users can read all messages"
    on public.messages
    for select
    to authenticated
    using (true);

-- You can only INSERT a message whose sender_id is your own user id —
-- so nobody can post pretending to be someone else.
create policy "Users can send messages as themselves"
    on public.messages
    for insert
    to authenticated
    with check (auth.uid() = sender_id);

-- 3) Realtime --------------------------------------------------------------
-- Add the table to the realtime publication so inserts get broadcast live.
alter publication supabase_realtime add table public.messages;
