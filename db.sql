-- ============================================================
-- SELA APP - DATABASE SCHEMA
-- ============================================================

-- 1. PROFILES (Penyimpanan Data User & Avatar)
CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" uuid REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    "username" text UNIQUE,
    "full_name" text,
    "avatar_url" text,
    "class_name" text,
    "updated_at" timestamp with time zone DEFAULT now()
);

-- 2. GROUPS (Data Kelompok & Kode Join)
CREATE TABLE IF NOT EXISTS "public"."groups" (
    "id" uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    "name" text NOT NULL,
    "course_name" text,
    "class_name" text,
    "group_number" integer,
    "member_limit" integer DEFAULT 4,
    "invitation_code" text UNIQUE,
    "lecture_code" text,
    "created_by" uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    "created_at" timestamp with time zone DEFAULT now()
);

-- 3. GROUP MEMBERS (Relasi User ke Grup)
CREATE TABLE IF NOT EXISTS "public"."group_members" (
    "id" uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    "group_id" uuid REFERENCES "public"."groups"(id) ON DELETE CASCADE,
    "user_id" uuid REFERENCES "public"."profiles"(id) ON DELETE CASCADE,
    "role" text DEFAULT 'member',
    "joined_at" timestamp with time zone DEFAULT now(),
    UNIQUE("group_id", "user_id")
);

-- 4. TASKS (Data Tugas Individual & Group)
CREATE TABLE IF NOT EXISTS "public"."tasks" (
    "id" uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    "title" text NOT NULL,
    "description" text,
    "category" text,
    "subject" text,
    "start_date" timestamp with time zone DEFAULT now(),
    "due_date" timestamp with time zone,
    "is_group" boolean DEFAULT false,
    "group_id" uuid REFERENCES "public"."groups"(id) ON DELETE SET NULL,
    "created_by" uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    "status" text DEFAULT 'To Do',
    "priority" text DEFAULT 'Medium',
    "link" text,
    "file_path" text,
    "created_at" timestamp with time zone DEFAULT now()
);

-- 5. SUBTASKS
CREATE TABLE IF NOT EXISTS "public"."subtasks" (
    "id" uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    "task_id" uuid REFERENCES "public"."tasks"(id) ON DELETE CASCADE,
    "title" text NOT NULL,
    "created_at" timestamp with time zone DEFAULT now()
);

-- 6. USER SUBTASK PROGRESS
CREATE TABLE IF NOT EXISTS "public"."subtask_progress" (
    "id" uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    "subtask_id" uuid REFERENCES "public"."subtasks"(id) ON DELETE CASCADE,
    "user_id" uuid REFERENCES "public"."profiles"(id) ON DELETE CASCADE,
    "progress" integer DEFAULT 0,
    "updated_at" timestamp with time zone DEFAULT now(),
    UNIQUE("subtask_id", "user_id")
);

-- 7. TASK LINKS
CREATE TABLE IF NOT EXISTS "public"."task_links" (
    "id" uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    "task_id" uuid REFERENCES "public"."tasks"(id) ON DELETE CASCADE,
    "url" text NOT NULL,
    "label" text,
    "created_at" timestamp with time zone DEFAULT now()
);

-- ============================================================
-- AKTIFKAN RLS
-- ============================================================
ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."groups" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."group_members" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."tasks" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."subtasks" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."subtask_progress" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."task_links" ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- SECURITY DEFINER FUNCTION — KUNCI UNTUK MEMUTUS REKURSI
-- Fungsi ini berjalan dengan hak akses SUPERUSER (bukan user biasa)
-- sehingga policy bisa menggunakannya tanpa rekursi.
-- ============================================================

CREATE OR REPLACE FUNCTION public.is_group_member(p_group_id uuid, p_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.group_members
        WHERE group_id = p_group_id
          AND user_id = p_user_id
    );
$$;

-- Fungsi ini dipakai untuk mencari grup via invite code (bypass RLS)
-- sehingga user yang belum menjadi member pun bisa join.
CREATE OR REPLACE FUNCTION public.find_group_by_invite_code(p_code text)
RETURNS TABLE (
    id uuid,
    name text,
    course_name text,
    class_name text,
    group_number integer,
    member_limit integer,
    invitation_code text,
    lecture_code text,
    created_by uuid,
    created_at timestamp with time zone
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT id, name, course_name, class_name, group_number, member_limit,
           invitation_code, lecture_code, created_by, created_at
    FROM public.groups
    WHERE invitation_code = p_code
    LIMIT 1;
$$;

-- ============================================================
-- POLICIES
-- ============================================================
DO $$
BEGIN

    -- ---------- PROFILES ----------
    DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON profiles;
    CREATE POLICY "Public profiles are viewable by everyone"
        ON profiles FOR SELECT USING (true);

    DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
    CREATE POLICY "Users can update own profile"
        ON profiles FOR UPDATE USING (auth.uid() = id);

    DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
    CREATE POLICY "Users can insert own profile"
        ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

    -- ---------- GROUPS ----------
    -- Gunakan fungsi SECURITY DEFINER agar tidak rekursi!
    DROP POLICY IF EXISTS "Anyone can view groups" ON groups;
    DROP POLICY IF EXISTS "Users can view groups they are in" ON groups;
    CREATE POLICY "Users can view groups they are in"
        ON groups FOR SELECT USING (
            auth.uid() = created_by
            OR public.is_group_member(id, auth.uid())
        );

    DROP POLICY IF EXISTS "Users can create groups" ON groups;
    CREATE POLICY "Users can create groups"
        ON groups FOR INSERT WITH CHECK (auth.uid() = created_by);

    DROP POLICY IF EXISTS "Users can update own group" ON groups;
    CREATE POLICY "Users can update own group"
        ON groups FOR UPDATE USING (auth.uid() = created_by);

    -- ---------- GROUP MEMBERS ----------
    -- Gunakan fungsi SECURITY DEFINER agar tidak rekursi!
    DROP POLICY IF EXISTS "Anyone can view member list" ON group_members;
    DROP POLICY IF EXISTS "Members can view group members" ON group_members;
    CREATE POLICY "Members can view group members"
        ON group_members FOR SELECT USING (
            auth.uid() = user_id
            OR public.is_group_member(group_id, auth.uid())
        );

    DROP POLICY IF EXISTS "Users can join groups" ON group_members;
    CREATE POLICY "Users can join groups"
        ON group_members FOR INSERT WITH CHECK (auth.uid() = user_id);

    DROP POLICY IF EXISTS "Users can leave groups" ON group_members;
    CREATE POLICY "Users can leave groups"
        ON group_members FOR DELETE USING (auth.uid() = user_id);

    -- ---------- TASKS ----------
    DROP POLICY IF EXISTS "Users can view their tasks" ON tasks;
    CREATE POLICY "Users can view their tasks"
        ON tasks FOR SELECT USING (
            auth.uid() = created_by
            OR (
                is_group = true
                AND group_id IS NOT NULL
                AND public.is_group_member(group_id, auth.uid())
            )
        );

    DROP POLICY IF EXISTS "Users can create tasks" ON tasks;
    CREATE POLICY "Users can create tasks"
        ON tasks FOR INSERT WITH CHECK (auth.uid() = created_by);

    DROP POLICY IF EXISTS "Users can update their tasks" ON tasks;
    CREATE POLICY "Users can update their tasks"
        ON tasks FOR UPDATE USING (auth.uid() = created_by);

    DROP POLICY IF EXISTS "Users can delete their tasks" ON tasks;
    CREATE POLICY "Users can delete their tasks"
        ON tasks FOR DELETE USING (auth.uid() = created_by);

    -- ---------- SUBTASKS ----------
    DROP POLICY IF EXISTS "Anyone can view subtasks" ON subtasks;
    CREATE POLICY "Anyone can view subtasks"
        ON subtasks FOR SELECT USING (true);

    DROP POLICY IF EXISTS "Creators can manage subtasks" ON subtasks;
    CREATE POLICY "Creators can manage subtasks"
        ON subtasks FOR ALL USING (
            EXISTS (
                SELECT 1 FROM tasks
                WHERE tasks.id = subtasks.task_id
                  AND tasks.created_by = auth.uid()
            )
        );

    -- ---------- SUBTASK PROGRESS ----------
    DROP POLICY IF EXISTS "Users can view subtask progress" ON subtask_progress;
    CREATE POLICY "Users can view subtask progress"
        ON subtask_progress FOR SELECT USING (true);

    DROP POLICY IF EXISTS "Users can update their own subtask progress" ON subtask_progress;
    CREATE POLICY "Users can update their own subtask progress"
        ON subtask_progress FOR ALL USING (auth.uid() = user_id);

    -- ---------- TASK LINKS ----------
    DROP POLICY IF EXISTS "Anyone can view task links" ON task_links;
    CREATE POLICY "Anyone can view task links"
        ON task_links FOR SELECT USING (true);

    DROP POLICY IF EXISTS "Creators can manage task links" ON task_links;
    CREATE POLICY "Creators can manage task links"
        ON task_links FOR ALL USING (
            EXISTS (
                SELECT 1 FROM tasks
                WHERE tasks.id = task_links.task_id
                  AND tasks.created_by = auth.uid()
            )
        );

END $$;
