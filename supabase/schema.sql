-- MineZim Database Schema
-- Run this in your Supabase SQL editor after creating the project

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ============================================================
-- USERS / PROFILES
-- ============================================================
create table profiles (
  id uuid primary key references auth.users on delete cascade,
  full_name text not null,
  email text not null,
  phone text,
  province text,
  account_type text not null check (account_type in (
    'miner','supplier','buyer','employer','investor','equipment','services','explosives'
  )),
  lang text default 'en' check (lang in ('en','zh')),
  verified boolean default false,
  verification_status text default 'pending' check (verification_status in ('pending','under_review','approved','rejected')),
  created_at timestamptz default now()
);

alter table profiles enable row level security;

create policy "Users can view own profile" on profiles
  for select using (auth.uid() = id);

create policy "Users can update own profile" on profiles
  for update using (auth.uid() = id);

-- ============================================================
-- LISTINGS
-- ============================================================
create table listings (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references profiles(id) on delete cascade,
  category text not null check (category in (
    'chemicals','explosives','investments','mines','equipment','workforce','buyers','services'
  )),
  title text not null,
  title_zh text,
  description text,
  description_zh text,
  price numeric,
  currency text default 'USD',
  province text,
  compliance_status text default 'pending' check (compliance_status in ('pending','licensed','strictly_controlled','open')),
  verified boolean default false,
  active boolean default true,
  images text[],
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table listings enable row level security;

create policy "Anyone can view active verified listings" on listings
  for select using (active = true and verified = true);

create policy "Owners can manage their listings" on listings
  for all using (auth.uid() = user_id);

-- ============================================================
-- INVESTMENT OPPORTUNITIES
-- ============================================================
create table investments (
  id uuid primary key default uuid_generate_v4(),
  listing_id uuid references listings(id) on delete cascade,
  seeking_amount numeric,
  equity_offered numeric,
  min_investment numeric,
  mine_type text,
  mineral text,
  location text,
  title_deed_verified boolean default false,
  created_at timestamptz default now()
);

alter table investments enable row level security;

create policy "Anyone can view investments" on investments
  for select using (true);

-- ============================================================
-- DOCUMENT UPLOADS (for verification)
-- ============================================================
create table user_documents (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references profiles(id) on delete cascade,
  doc_type text not null,
  file_path text not null,
  status text default 'pending' check (status in ('pending','approved','rejected')),
  uploaded_at timestamptz default now()
);

alter table user_documents enable row level security;

create policy "Users can manage own documents" on user_documents
  for all using (auth.uid() = user_id);

-- ============================================================
-- CONTACT / INQUIRY
-- ============================================================
create table inquiries (
  id uuid primary key default uuid_generate_v4(),
  listing_id uuid references listings(id) on delete cascade,
  sender_id uuid references profiles(id) on delete cascade,
  message text not null,
  status text default 'unread' check (status in ('unread','read','replied')),
  created_at timestamptz default now()
);

alter table inquiries enable row level security;

create policy "Parties can view their inquiries" on inquiries
  for select using (
    auth.uid() = sender_id or
    auth.uid() = (select user_id from listings where id = listing_id)
  );

create policy "Authenticated users can send inquiries" on inquiries
  for insert with check (auth.uid() = sender_id);

-- ============================================================
-- SAMPLE DATA
-- ============================================================
-- insert sample listings (run after first user is created)
-- insert into listings (category, title, description, compliance_status, verified, active, province)
-- values ('chemicals','Sodium Cyanide NaCN 98%','MMCZ certified, 500kg lots available','strictly_controlled',true,true,'Midlands');
