-- Dummy data for sample ROI testing (Role 5 + Admin)
-- Safe-ish rerun via fixed IDs + upserts where possible.

begin;

-- 1) Ensure demo users exist (role 5 grounds + role 4 agent)
insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  (
    '92000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'grounds.demo@dehus.com',
    crypt('password123', gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Grounds Demo User","role":5,"region":"Nairobi"}',
    now(),
    now()
  ),
  (
    '92000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'agent.demo@dehus.com',
    crypt('password123', gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Agent Demo User","role":4,"region":"Nakuru"}',
    now(),
    now()
  )
on conflict (id) do nothing;

insert into public.users (id, email, full_name, phone, role, region)
values
  ('92000000-0000-0000-0000-000000000001', 'grounds.demo@dehus.com', 'Grounds Demo User', '0711000001', 5, 'Nairobi'),
  ('92000000-0000-0000-0000-000000000002', 'agent.demo@dehus.com', 'Agent Demo User', '0711000002', 4, 'Nakuru')
on conflict (id) do update set
  email = excluded.email,
  full_name = excluded.full_name,
  phone = excluded.phone,
  role = excluded.role,
  region = excluded.region;

-- 2) Pick up to 4 schools for linking data
with s as (
  select id, row_number() over (order by created_at desc nulls last, id) rn
  from public.schools
  limit 4
)
insert into public.school_sample_distributions (
  id, school_id, agent_id, sample_name, sample_category, quantity,
  stamped_receipt_url, stamped_receipt_path, notes, distributed_at, "isSynced"
)
select
  ('93000000-0000-0000-0000-' || lpad(rn::text, 12, '0'))::uuid,
  s.id,
  case when s.rn % 2 = 0
    then '92000000-0000-0000-0000-000000000002'::uuid
    else '92000000-0000-0000-0000-000000000001'::uuid
  end,
  case when s.rn % 2 = 0 then 'Teacher Guide Kit' else 'Grade 1 Reader Pack' end,
  case when s.rn % 2 = 0 then 'Reference' else 'Primary' end,
  (s.rn % 3) + 1,
  'https://images.unsplash.com/photo-1455390582262-044cdead277a?w=1200',
  'sample_receipts/demo_' || s.rn || '.jpg',
  'Dummy ROI receipt seed',
  now() - ((s.rn::text || ' days')::interval),
  true
from s
on conflict (id) do update set
  school_id = excluded.school_id,
  agent_id = excluded.agent_id,
  sample_name = excluded.sample_name,
  sample_category = excluded.sample_category,
  quantity = excluded.quantity,
  stamped_receipt_url = excluded.stamped_receipt_url,
  stamped_receipt_path = excluded.stamped_receipt_path,
  notes = excluded.notes,
  distributed_at = excluded.distributed_at,
  "isSynced" = excluded."isSynced";

-- 3) Orders for revenue earned metric
insert into public.orders (
  id, school_id, school_name, school_phone, agent_id, order_number,
  payment_method, payment_reference, checkout_amount, status, notes, submitted_at, approved_at, "isSynced"
)
select
  ('94000000-0000-0000-0000-' || lpad(rn::text, 12, '0'))::uuid,
  s.id,
  coalesce(sc.name, 'School ' || s.rn),
  coalesce(sc.phone, '0700000000'),
  case when s.rn % 2 = 0
    then '92000000-0000-0000-0000-000000000002'::uuid
    else '92000000-0000-0000-0000-000000000001'::uuid
  end,
  'DEMO-ROI-' || s.rn,
  'mpesa',
  'MPESA-DEMO-' || s.rn,
  (50000 + (s.rn * 10000))::numeric,
  case when s.rn % 3 = 0 then 'pending' else 'approved' end,
  'Dummy ROI order',
  now() - ((s.rn::text || ' days')::interval),
  now() - (((s.rn + 1)::text || ' days')::interval),
  true
from (
  select id, row_number() over (order by created_at desc nulls last, id) rn
  from public.schools
  limit 4
) s
left join public.schools sc on sc.id = s.id
on conflict (id) do update set
  school_id = excluded.school_id,
  school_name = excluded.school_name,
  school_phone = excluded.school_phone,
  agent_id = excluded.agent_id,
  checkout_amount = excluded.checkout_amount,
  status = excluded.status,
  notes = excluded.notes,
  submitted_at = excluded.submitted_at,
  approved_at = excluded.approved_at,
  "isSynced" = excluded."isSynced";

-- 4) School sales for won value metric
insert into public.school_sales (
  id, school_id, agent_id, package_name, expected_value, notes,
  sale_status, stage_updated_at, probability, closed_at, "isSynced"
)
select
  ('95000000-0000-0000-0000-' || lpad(rn::text, 12, '0'))::uuid,
  s.id,
  case when s.rn % 2 = 0
    then '92000000-0000-0000-0000-000000000002'::uuid
    else '92000000-0000-0000-0000-000000000001'::uuid
  end,
  'ROI Demo Package',
  (90000 + (s.rn * 12000))::numeric,
  'Dummy ROI pipeline',
  case when s.rn % 2 = 0 then 'won' else 'negotiation' end,
  now() - ((s.rn::text || ' days')::interval),
  case when s.rn % 2 = 0 then 100 else 70 end,
  case when s.rn % 2 = 0 then now() - ((s.rn::text || ' days')::interval) else null end,
  true
from (
  select id, row_number() over (order by created_at desc nulls last, id) rn
  from public.schools
  limit 4
) s
on conflict (id) do update set
  school_id = excluded.school_id,
  agent_id = excluded.agent_id,
  package_name = excluded.package_name,
  expected_value = excluded.expected_value,
  notes = excluded.notes,
  sale_status = excluded.sale_status,
  stage_updated_at = excluded.stage_updated_at,
  probability = excluded.probability,
  closed_at = excluded.closed_at,
  "isSynced" = excluded."isSynced";

commit;
