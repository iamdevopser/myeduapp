-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateEnum
CREATE TYPE "AppRole" AS ENUM ('teacher', 'student', 'secretary', 'parent', 'admin');

-- CreateEnum
CREATE TYPE "ContentType" AS ENUM ('text', 'pdf', 'ppt', 'word', 'image', 'video', 'audio', 'link', 'homework', 'question', 'exam');

-- CreateEnum
CREATE TYPE "QuestionType" AS ENUM ('text', 'image', 'mcq');

-- CreateEnum
CREATE TYPE "AnnouncementStatus" AS ENUM ('draft', 'published', 'unpublished');

-- CreateEnum
CREATE TYPE "AnnouncementTarget" AS ENUM ('all_school', 'grade', 'section');

-- CreateEnum
CREATE TYPE "AttendanceStatus" AS ENUM ('present', 'absent', 'excused');

-- CreateEnum
CREATE TYPE "BehaviorKind" AS ENUM ('positive', 'needs_improvement');

-- CreateEnum
CREATE TYPE "ParentRelation" AS ENUM ('anne', 'baba', 'diger');

-- CreateEnum
CREATE TYPE "NotificationStatus" AS ENUM ('unread', 'read');

-- CreateTable
CREATE TABLE "accounts" (
    "id" SERIAL NOT NULL,
    "username" TEXT NOT NULL,
    "email" TEXT,
    "fullName" TEXT NOT NULL DEFAULT '',
    "role" "AppRole" NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "domainType" TEXT,
    "domainId" INTEGER,
    "mustChangePassword" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "lastLoginAt" TIMESTAMP(3),

    CONSTRAINT "accounts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "account_preferences" (
    "accountId" INTEGER NOT NULL,
    "locale" TEXT NOT NULL DEFAULT 'tr',
    "themeMode" TEXT NOT NULL DEFAULT 'system',

    CONSTRAINT "account_preferences_pkey" PRIMARY KEY ("accountId")
);

-- CreateTable
CREATE TABLE "account_audit" (
    "id" SERIAL NOT NULL,
    "accountId" INTEGER,
    "action" TEXT NOT NULL,
    "detail" TEXT,
    "actorAccountId" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "account_audit_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "app_settings" (
    "key" TEXT NOT NULL,
    "value" TEXT NOT NULL,

    CONSTRAINT "app_settings_pkey" PRIMARY KEY ("key")
);

-- CreateTable
CREATE TABLE "curriculum_classes" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "curriculum_classes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "lessons" (
    "id" SERIAL NOT NULL,
    "curriculumClassId" INTEGER NOT NULL,
    "name" TEXT NOT NULL,
    "order" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "academicYear" TEXT NOT NULL DEFAULT '',
    "imageKey" TEXT,
    "teacherName" TEXT,

    CONSTRAINT "lessons_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "units" (
    "id" SERIAL NOT NULL,
    "lessonId" INTEGER NOT NULL,
    "name" TEXT NOT NULL,
    "number" INTEGER NOT NULL DEFAULT 1,
    "order" INTEGER NOT NULL,
    "imageKey" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "units_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "topics" (
    "id" SERIAL NOT NULL,
    "lessonId" INTEGER NOT NULL,
    "unitId" INTEGER,
    "name" TEXT NOT NULL,
    "order" INTEGER NOT NULL,
    "imageKey" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "topics_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "contents" (
    "id" SERIAL NOT NULL,
    "lessonId" INTEGER,
    "topicId" INTEGER,
    "name" TEXT NOT NULL,
    "type" "ContentType" NOT NULL,
    "storageKey" TEXT NOT NULL,
    "order" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "archived" BOOLEAN NOT NULL DEFAULT false,
    "isSchoolDocument" BOOLEAN NOT NULL DEFAULT false,
    "critical" BOOLEAN NOT NULL DEFAULT false,
    "description" TEXT,
    "category" TEXT,
    "scope" TEXT,

    CONSTRAINT "contents_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tags" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,

    CONSTRAINT "tags_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "content_tags" (
    "contentId" INTEGER NOT NULL,
    "tagId" INTEGER NOT NULL,

    CONSTRAINT "content_tags_pkey" PRIMARY KEY ("contentId","tagId")
);

-- CreateTable
CREATE TABLE "favorites" (
    "accountId" INTEGER NOT NULL,
    "contentId" INTEGER NOT NULL,

    CONSTRAINT "favorites_pkey" PRIMARY KEY ("accountId","contentId")
);

-- CreateTable
CREATE TABLE "content_reading_progress" (
    "accountId" INTEGER NOT NULL,
    "contentId" INTEGER NOT NULL,
    "lastPage" INTEGER NOT NULL DEFAULT 1,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "extraJson" TEXT,

    CONSTRAINT "content_reading_progress_pkey" PRIMARY KEY ("accountId","contentId")
);

-- CreateTable
CREATE TABLE "lesson_images" (
    "name" TEXT NOT NULL,
    "imageKey" TEXT,

    CONSTRAINT "lesson_images_pkey" PRIMARY KEY ("name")
);

-- CreateTable
CREATE TABLE "exams" (
    "id" SERIAL NOT NULL,
    "lessonId" INTEGER NOT NULL,
    "topicId" INTEGER,
    "name" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "exams_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "exam_questions" (
    "id" SERIAL NOT NULL,
    "examId" INTEGER NOT NULL,
    "prompt" TEXT NOT NULL,
    "type" "QuestionType" NOT NULL DEFAULT 'text',
    "options" JSONB,
    "correctOptionIndex" INTEGER,
    "audioKey" TEXT,
    "order" INTEGER NOT NULL,

    CONSTRAINT "exam_questions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "question_bank" (
    "id" SERIAL NOT NULL,
    "prompt" TEXT NOT NULL,
    "type" "QuestionType" NOT NULL,
    "options" JSONB,
    "correctOptionIndex" INTEGER,
    "imageKey" TEXT,
    "audioKey" TEXT,
    "tags" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "question_bank_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "lesson_notes" (
    "id" SERIAL NOT NULL,
    "lessonId" INTEGER NOT NULL,
    "topicId" INTEGER,
    "text" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "lesson_notes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "roster_classes" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "year" TEXT NOT NULL,
    "section" TEXT,

    CONSTRAINT "roster_classes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "students" (
    "id" SERIAL NOT NULL,
    "rosterClassId" INTEGER NOT NULL,
    "number" INTEGER NOT NULL,
    "fullName" TEXT NOT NULL,
    "email" TEXT,

    CONSTRAINT "students_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "student_categories" (
    "id" SERIAL NOT NULL,
    "rosterClassId" INTEGER NOT NULL,
    "name" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "order" INTEGER NOT NULL,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "system" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "student_categories_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "score_columns" (
    "id" SERIAL NOT NULL,
    "rosterClassId" INTEGER NOT NULL,
    "name" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "teacherName" TEXT,

    CONSTRAINT "score_columns_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "score_column_date_notes" (
    "columnId" INTEGER NOT NULL,
    "date" TEXT NOT NULL,
    "description" TEXT NOT NULL,

    CONSTRAINT "score_column_date_notes_pkey" PRIMARY KEY ("columnId","date")
);

-- CreateTable
CREATE TABLE "grade_cells" (
    "studentId" INTEGER NOT NULL,
    "columnId" INTEGER NOT NULL,
    "date" TEXT NOT NULL,
    "score" INTEGER,
    "done" BOOLEAN,
    "absent" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "grade_cells_pkey" PRIMARY KEY ("studentId","columnId","date")
);

-- CreateTable
CREATE TABLE "attendance_records" (
    "id" SERIAL NOT NULL,
    "studentId" INTEGER NOT NULL,
    "date" TEXT NOT NULL,
    "status" "AttendanceStatus" NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "attendance_records_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "parents" (
    "id" SERIAL NOT NULL,
    "fullName" TEXT NOT NULL,
    "phone" TEXT,
    "email" TEXT,
    "address" TEXT,
    "notes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "parents_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "student_parents" (
    "id" SERIAL NOT NULL,
    "studentId" INTEGER NOT NULL,
    "parentId" INTEGER NOT NULL,
    "relation" "ParentRelation" NOT NULL,
    "isPrimary" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "student_parents_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "behavior_definitions" (
    "id" SERIAL NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "kind" "BehaviorKind" NOT NULL,
    "order" INTEGER NOT NULL,

    CONSTRAINT "behavior_definitions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "behavior_records" (
    "id" SERIAL NOT NULL,
    "rosterClassId" INTEGER NOT NULL,
    "studentId" INTEGER NOT NULL,
    "behaviorId" INTEGER NOT NULL,
    "date" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "visibleToStudent" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "behavior_records_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "announcements" (
    "id" SERIAL NOT NULL,
    "title" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "status" "AnnouncementStatus" NOT NULL DEFAULT 'draft',
    "targetType" "AnnouncementTarget" NOT NULL DEFAULT 'all_school',
    "rosterClassId" INTEGER,
    "targetGradeLevel" INTEGER,
    "lessonId" INTEGER,
    "courseLabel" TEXT,
    "teacherName" TEXT,
    "coverImageKey" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "publishedAt" TIMESTAMP(3),
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "announcements_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "document_folders" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "order" INTEGER NOT NULL DEFAULT 0,
    "parentId" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "document_folders_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "document_folder_items" (
    "id" SERIAL NOT NULL,
    "folderId" INTEGER NOT NULL,
    "contentId" INTEGER NOT NULL,
    "order" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "document_folder_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "class_notebook_notes" (
    "id" SERIAL NOT NULL,
    "rosterClassId" INTEGER NOT NULL,
    "text" TEXT NOT NULL,
    "noteDate" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3),

    CONSTRAINT "class_notebook_notes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "teacher_activities" (
    "id" SERIAL NOT NULL,
    "accountId" INTEGER NOT NULL,
    "type" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "targetType" TEXT,
    "targetId" INTEGER,
    "extraData" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "teacher_activities_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "period_slots" (
    "period" INTEGER NOT NULL,
    "start" TEXT NOT NULL,
    "end" TEXT NOT NULL,

    CONSTRAINT "period_slots_pkey" PRIMARY KEY ("period")
);

-- CreateTable
CREATE TABLE "weekly_lessons" (
    "id" SERIAL NOT NULL,
    "day" INTEGER NOT NULL,
    "period" INTEGER NOT NULL DEFAULT 1,
    "start" TEXT NOT NULL,
    "end" TEXT NOT NULL,
    "lessonId" INTEGER,
    "rosterClassId" INTEGER,
    "topicText" TEXT NOT NULL DEFAULT '',
    "classText" TEXT NOT NULL DEFAULT '',

    CONSTRAINT "weekly_lessons_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "daily_plans" (
    "id" SERIAL NOT NULL,
    "date" TEXT NOT NULL,
    "lessonId" INTEGER,
    "rosterClassId" INTEGER,
    "topicText" TEXT NOT NULL DEFAULT '',
    "classText" TEXT NOT NULL DEFAULT '',
    "topic" TEXT,
    "goals" TEXT,
    "activities" TEXT,
    "materials" TEXT,
    "homework" TEXT,
    "notes" TEXT,

    CONSTRAINT "daily_plans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "annual_plans" (
    "id" SERIAL NOT NULL,
    "academicYear" TEXT NOT NULL,
    "lessonId" INTEGER,
    "rosterClassId" INTEGER,
    "topicText" TEXT NOT NULL DEFAULT '',
    "classText" TEXT NOT NULL DEFAULT '',
    "unitTopic" TEXT NOT NULL,
    "plannedTerm" TEXT,
    "hours" INTEGER,
    "goals" TEXT,
    "notes" TEXT,

    CONSTRAINT "annual_plans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "mentorship_classes" (
    "id" SERIAL NOT NULL,
    "rosterClassId" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "mentorship_classes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "mentorship_events" (
    "id" SERIAL NOT NULL,
    "rosterClassId" INTEGER NOT NULL,
    "type" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "date" TEXT NOT NULL,
    "time" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "wholeClass" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "mentorship_events_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "mentorship_event_students" (
    "eventId" INTEGER NOT NULL,
    "studentId" INTEGER NOT NULL,

    CONSTRAINT "mentorship_event_students_pkey" PRIMARY KEY ("eventId","studentId")
);

-- CreateTable
CREATE TABLE "mentorship_behavior_reports" (
    "id" SERIAL NOT NULL,
    "rosterClassId" INTEGER NOT NULL,
    "studentId" INTEGER NOT NULL,
    "date" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "behavior" TEXT,
    "description" TEXT,
    "level" TEXT,
    "teacherNote" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "mentorship_behavior_reports_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "mentorship_notes" (
    "id" SERIAL NOT NULL,
    "rosterClassId" INTEGER NOT NULL,
    "studentId" INTEGER NOT NULL,
    "text" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "mentorship_notes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notifications" (
    "id" SERIAL NOT NULL,
    "recipientRole" "AppRole" NOT NULL,
    "recipientId" INTEGER NOT NULL DEFAULT 0,
    "title" TEXT NOT NULL,
    "body" TEXT NOT NULL DEFAULT '',
    "type" TEXT NOT NULL,
    "referenceType" TEXT,
    "referenceId" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "readAt" TIMESTAMP(3),
    "status" "NotificationStatus" NOT NULL DEFAULT 'unread',
    "dedupKey" TEXT NOT NULL,

    CONSTRAINT "notifications_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "accounts_username_key" ON "accounts"("username");

-- CreateIndex
CREATE UNIQUE INDEX "accounts_email_key" ON "accounts"("email");

-- CreateIndex
CREATE INDEX "accounts_role_active_idx" ON "accounts"("role", "active");

-- CreateIndex
CREATE INDEX "accounts_domainType_domainId_idx" ON "accounts"("domainType", "domainId");

-- CreateIndex
CREATE INDEX "account_audit_accountId_idx" ON "account_audit"("accountId");

-- CreateIndex
CREATE INDEX "lessons_curriculumClassId_idx" ON "lessons"("curriculumClassId");

-- CreateIndex
CREATE INDEX "units_lessonId_idx" ON "units"("lessonId");

-- CreateIndex
CREATE INDEX "topics_lessonId_idx" ON "topics"("lessonId");

-- CreateIndex
CREATE INDEX "contents_lessonId_idx" ON "contents"("lessonId");

-- CreateIndex
CREATE INDEX "contents_isSchoolDocument_archived_idx" ON "contents"("isSchoolDocument", "archived");

-- CreateIndex
CREATE UNIQUE INDEX "tags_name_key" ON "tags"("name");

-- CreateIndex
CREATE INDEX "exams_lessonId_idx" ON "exams"("lessonId");

-- CreateIndex
CREATE INDEX "exam_questions_examId_idx" ON "exam_questions"("examId");

-- CreateIndex
CREATE INDEX "lesson_notes_lessonId_idx" ON "lesson_notes"("lessonId");

-- CreateIndex
CREATE UNIQUE INDEX "students_rosterClassId_number_key" ON "students"("rosterClassId", "number");

-- CreateIndex
CREATE INDEX "student_categories_rosterClassId_idx" ON "student_categories"("rosterClassId");

-- CreateIndex
CREATE INDEX "score_columns_rosterClassId_idx" ON "score_columns"("rosterClassId");

-- CreateIndex
CREATE INDEX "attendance_records_date_idx" ON "attendance_records"("date");

-- CreateIndex
CREATE UNIQUE INDEX "attendance_records_studentId_date_key" ON "attendance_records"("studentId", "date");

-- CreateIndex
CREATE INDEX "student_parents_parentId_idx" ON "student_parents"("parentId");

-- CreateIndex
CREATE UNIQUE INDEX "student_parents_studentId_parentId_key" ON "student_parents"("studentId", "parentId");

-- CreateIndex
CREATE UNIQUE INDEX "behavior_definitions_code_key" ON "behavior_definitions"("code");

-- CreateIndex
CREATE UNIQUE INDEX "behavior_records_studentId_behaviorId_date_key" ON "behavior_records"("studentId", "behaviorId", "date");

-- CreateIndex
CREATE INDEX "announcements_status_targetType_idx" ON "announcements"("status", "targetType");

-- CreateIndex
CREATE INDEX "document_folders_parentId_idx" ON "document_folders"("parentId");

-- CreateIndex
CREATE UNIQUE INDEX "document_folder_items_folderId_contentId_key" ON "document_folder_items"("folderId", "contentId");

-- CreateIndex
CREATE INDEX "class_notebook_notes_rosterClassId_noteDate_idx" ON "class_notebook_notes"("rosterClassId", "noteDate");

-- CreateIndex
CREATE INDEX "teacher_activities_accountId_createdAt_idx" ON "teacher_activities"("accountId", "createdAt");

-- CreateIndex
CREATE INDEX "weekly_lessons_day_period_idx" ON "weekly_lessons"("day", "period");

-- CreateIndex
CREATE INDEX "daily_plans_date_idx" ON "daily_plans"("date");

-- CreateIndex
CREATE INDEX "annual_plans_academicYear_idx" ON "annual_plans"("academicYear");

-- CreateIndex
CREATE UNIQUE INDEX "mentorship_classes_rosterClassId_key" ON "mentorship_classes"("rosterClassId");

-- CreateIndex
CREATE INDEX "mentorship_events_rosterClassId_date_idx" ON "mentorship_events"("rosterClassId", "date");

-- CreateIndex
CREATE INDEX "mentorship_behavior_reports_studentId_idx" ON "mentorship_behavior_reports"("studentId");

-- CreateIndex
CREATE INDEX "mentorship_notes_studentId_idx" ON "mentorship_notes"("studentId");

-- CreateIndex
CREATE UNIQUE INDEX "notifications_dedupKey_key" ON "notifications"("dedupKey");

-- CreateIndex
CREATE INDEX "notifications_recipientRole_recipientId_idx" ON "notifications"("recipientRole", "recipientId");

-- AddForeignKey
ALTER TABLE "account_preferences" ADD CONSTRAINT "account_preferences_accountId_fkey" FOREIGN KEY ("accountId") REFERENCES "accounts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "account_audit" ADD CONSTRAINT "account_audit_accountId_fkey" FOREIGN KEY ("accountId") REFERENCES "accounts"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "account_audit" ADD CONSTRAINT "account_audit_actorAccountId_fkey" FOREIGN KEY ("actorAccountId") REFERENCES "accounts"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "lessons" ADD CONSTRAINT "lessons_curriculumClassId_fkey" FOREIGN KEY ("curriculumClassId") REFERENCES "curriculum_classes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "units" ADD CONSTRAINT "units_lessonId_fkey" FOREIGN KEY ("lessonId") REFERENCES "lessons"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "topics" ADD CONSTRAINT "topics_lessonId_fkey" FOREIGN KEY ("lessonId") REFERENCES "lessons"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "topics" ADD CONSTRAINT "topics_unitId_fkey" FOREIGN KEY ("unitId") REFERENCES "units"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "contents" ADD CONSTRAINT "contents_lessonId_fkey" FOREIGN KEY ("lessonId") REFERENCES "lessons"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "contents" ADD CONSTRAINT "contents_topicId_fkey" FOREIGN KEY ("topicId") REFERENCES "topics"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "content_tags" ADD CONSTRAINT "content_tags_contentId_fkey" FOREIGN KEY ("contentId") REFERENCES "contents"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "content_tags" ADD CONSTRAINT "content_tags_tagId_fkey" FOREIGN KEY ("tagId") REFERENCES "tags"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "favorites" ADD CONSTRAINT "favorites_accountId_fkey" FOREIGN KEY ("accountId") REFERENCES "accounts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "favorites" ADD CONSTRAINT "favorites_contentId_fkey" FOREIGN KEY ("contentId") REFERENCES "contents"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "content_reading_progress" ADD CONSTRAINT "content_reading_progress_accountId_fkey" FOREIGN KEY ("accountId") REFERENCES "accounts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "content_reading_progress" ADD CONSTRAINT "content_reading_progress_contentId_fkey" FOREIGN KEY ("contentId") REFERENCES "contents"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "exams" ADD CONSTRAINT "exams_lessonId_fkey" FOREIGN KEY ("lessonId") REFERENCES "lessons"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "exams" ADD CONSTRAINT "exams_topicId_fkey" FOREIGN KEY ("topicId") REFERENCES "topics"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "exam_questions" ADD CONSTRAINT "exam_questions_examId_fkey" FOREIGN KEY ("examId") REFERENCES "exams"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "lesson_notes" ADD CONSTRAINT "lesson_notes_lessonId_fkey" FOREIGN KEY ("lessonId") REFERENCES "lessons"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "lesson_notes" ADD CONSTRAINT "lesson_notes_topicId_fkey" FOREIGN KEY ("topicId") REFERENCES "topics"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "students" ADD CONSTRAINT "students_rosterClassId_fkey" FOREIGN KEY ("rosterClassId") REFERENCES "roster_classes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "student_categories" ADD CONSTRAINT "student_categories_rosterClassId_fkey" FOREIGN KEY ("rosterClassId") REFERENCES "roster_classes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "score_columns" ADD CONSTRAINT "score_columns_rosterClassId_fkey" FOREIGN KEY ("rosterClassId") REFERENCES "roster_classes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "score_column_date_notes" ADD CONSTRAINT "score_column_date_notes_columnId_fkey" FOREIGN KEY ("columnId") REFERENCES "score_columns"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "grade_cells" ADD CONSTRAINT "grade_cells_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "grade_cells" ADD CONSTRAINT "grade_cells_columnId_fkey" FOREIGN KEY ("columnId") REFERENCES "score_columns"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "attendance_records" ADD CONSTRAINT "attendance_records_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "student_parents" ADD CONSTRAINT "student_parents_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "student_parents" ADD CONSTRAINT "student_parents_parentId_fkey" FOREIGN KEY ("parentId") REFERENCES "parents"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "behavior_records" ADD CONSTRAINT "behavior_records_rosterClassId_fkey" FOREIGN KEY ("rosterClassId") REFERENCES "roster_classes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "behavior_records" ADD CONSTRAINT "behavior_records_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "behavior_records" ADD CONSTRAINT "behavior_records_behaviorId_fkey" FOREIGN KEY ("behaviorId") REFERENCES "behavior_definitions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "announcements" ADD CONSTRAINT "announcements_rosterClassId_fkey" FOREIGN KEY ("rosterClassId") REFERENCES "roster_classes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "announcements" ADD CONSTRAINT "announcements_lessonId_fkey" FOREIGN KEY ("lessonId") REFERENCES "lessons"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "document_folders" ADD CONSTRAINT "document_folders_parentId_fkey" FOREIGN KEY ("parentId") REFERENCES "document_folders"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "document_folder_items" ADD CONSTRAINT "document_folder_items_folderId_fkey" FOREIGN KEY ("folderId") REFERENCES "document_folders"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "document_folder_items" ADD CONSTRAINT "document_folder_items_contentId_fkey" FOREIGN KEY ("contentId") REFERENCES "contents"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "class_notebook_notes" ADD CONSTRAINT "class_notebook_notes_rosterClassId_fkey" FOREIGN KEY ("rosterClassId") REFERENCES "roster_classes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "teacher_activities" ADD CONSTRAINT "teacher_activities_accountId_fkey" FOREIGN KEY ("accountId") REFERENCES "accounts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "weekly_lessons" ADD CONSTRAINT "weekly_lessons_lessonId_fkey" FOREIGN KEY ("lessonId") REFERENCES "lessons"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "weekly_lessons" ADD CONSTRAINT "weekly_lessons_rosterClassId_fkey" FOREIGN KEY ("rosterClassId") REFERENCES "roster_classes"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "daily_plans" ADD CONSTRAINT "daily_plans_lessonId_fkey" FOREIGN KEY ("lessonId") REFERENCES "lessons"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "daily_plans" ADD CONSTRAINT "daily_plans_rosterClassId_fkey" FOREIGN KEY ("rosterClassId") REFERENCES "roster_classes"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "annual_plans" ADD CONSTRAINT "annual_plans_lessonId_fkey" FOREIGN KEY ("lessonId") REFERENCES "lessons"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "annual_plans" ADD CONSTRAINT "annual_plans_rosterClassId_fkey" FOREIGN KEY ("rosterClassId") REFERENCES "roster_classes"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mentorship_classes" ADD CONSTRAINT "mentorship_classes_rosterClassId_fkey" FOREIGN KEY ("rosterClassId") REFERENCES "roster_classes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mentorship_events" ADD CONSTRAINT "mentorship_events_rosterClassId_fkey" FOREIGN KEY ("rosterClassId") REFERENCES "roster_classes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mentorship_event_students" ADD CONSTRAINT "mentorship_event_students_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "mentorship_events"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mentorship_event_students" ADD CONSTRAINT "mentorship_event_students_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mentorship_behavior_reports" ADD CONSTRAINT "mentorship_behavior_reports_rosterClassId_fkey" FOREIGN KEY ("rosterClassId") REFERENCES "roster_classes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mentorship_behavior_reports" ADD CONSTRAINT "mentorship_behavior_reports_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mentorship_notes" ADD CONSTRAINT "mentorship_notes_rosterClassId_fkey" FOREIGN KEY ("rosterClassId") REFERENCES "roster_classes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mentorship_notes" ADD CONSTRAINT "mentorship_notes_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;

