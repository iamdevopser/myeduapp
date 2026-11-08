"use client";

import { useQuery } from "@tanstack/react-query";
import { FormEvent, useState } from "react";
import { Button, Empty, Field, Input, Modal, PageTitle, Panel, Select, Table, Td, Th } from "@/components/ui";
import { useT } from "@/i18n/use-t";
import { api } from "@/lib/api";
import { useSession } from "@/lib/session-store";
import { useSave } from "@/lib/use-save";

type Roster = { id: number; name: string; year: string; section: string | null; _count?: { students: number } };
type Student = { id: number; fullName: string; number: number; email: string | null; rosterClassId: number; rosterClass?: { name: string; section: string | null } };
type Parent = { id: number; fullName: string; email: string | null; phone: string | null; _count?: { studentLinks: number } };

export function StudentsView() {
  const t = useT();
  const role = useSession((state) => state.user?.role);
  const [classId, setClassId] = useState<number | "">("");
  const [open, setOpen] = useState<"class" | "student" | null>(null);
  const classes = useQuery({
    queryKey: ["roster-classes"],
    queryFn: () => api<{ data: Roster[] }>("/api/roster-classes"),
  });
  const students = useQuery({
    queryKey: ["students", classId],
    queryFn: () => api<{ data: Student[] }>(`/api/students${classId ? `?rosterClassId=${classId}` : ""}`),
  });
  const saveClass = useSave((body: object) => api("/api/roster-classes", { method: "POST", body: JSON.stringify(body) }), ["roster-classes"]);
  const saveStudent = useSave((body: object) => api("/api/students", { method: "POST", body: JSON.stringify(body) }), ["students"], "saved", [["roster-classes"]]);
  const removeStudent = useSave((id: number) => api(`/api/students/${id}`, { method: "DELETE" }), ["students"], "deleted", [["roster-classes"]]);

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    if (open === "class") {
      await saveClass.mutateAsync({
        name: String(form.get("name")),
        year: String(form.get("year")),
        section: String(form.get("section") ?? "") || null,
      });
    }
    if (open === "student") {
      await saveStudent.mutateAsync({
        rosterClassId: Number(form.get("rosterClassId")),
        number: Number(form.get("number")),
        fullName: String(form.get("fullName")),
        email: String(form.get("email") ?? "") || null,
        username: String(form.get("username")),
        password: String(form.get("password")),
      });
    }
    setOpen(null);
  }

  return (
    <div className="grid gap-4">
      <PageTitle title={t("students")} />
      <Panel
        title={t("classes")}
        action={
          role === "teacher" || role === "secretary" ? (
            <Button onClick={() => setOpen("class")}>{t("create")}</Button>
          ) : null
        }
      >
        <Field label={t("selectClass")}>
          <Select value={classId} onChange={(event) => setClassId(event.target.value ? Number(event.target.value) : "")}>
            <option value="">{t("classes")}</option>
            {(classes.data?.data ?? []).map((row) => (
              <option key={row.id} value={row.id}>
                {row.year} · {row.name}
                {row.section ? `-${row.section}` : ""} ({row._count?.students ?? 0})
              </option>
            ))}
          </Select>
        </Field>
      </Panel>
      <Panel
        title={t("students")}
        action={role === "teacher" || role === "secretary" ? <Button onClick={() => setOpen("student")}>{t("create")}</Button> : null}
      >
        <Table>
          <thead>
            <tr>
              <Th>{t("number")}</Th>
              <Th>{t("fullName")}</Th>
              <Th>{t("classes")}</Th>
              <Th>{t("actions")}</Th>
            </tr>
          </thead>
          <tbody>
            {(students.data?.data ?? []).map((student) => (
              <tr key={student.id}>
                <Td>{student.number}</Td>
                <Td>{student.fullName}</Td>
                <Td>
                  {student.rosterClass?.name}
                  {student.rosterClass?.section ? `-${student.rosterClass.section}` : ""}
                </Td>
                <Td>
                  {role === "teacher" ? (
                    <Button
                      variant="danger"
                      onClick={() => {
                        if (window.confirm(t("confirmDelete"))) removeStudent.mutate(student.id);
                      }}
                    >
                      {t("delete")}
                    </Button>
                  ) : null}
                </Td>
              </tr>
            ))}
          </tbody>
        </Table>
        {(students.data?.data.length ?? 0) === 0 ? <Empty text={t("empty")} /> : null}
      </Panel>
      <Modal open={open != null} title={t("create")} onClose={() => setOpen(null)}>
        <form className="grid gap-3" onSubmit={onSubmit}>
          {open === "class" ? (
            <>
              <Field label={t("name")}>
                <Input name="name" required />
              </Field>
              <Field label={t("year")}>
                <Input name="year" required placeholder="2026–27" />
              </Field>
              <Field label={t("section")}>
                <Input name="section" maxLength={8} />
              </Field>
            </>
          ) : (
            <>
              <Field label={t("classes")}>
                <Select name="rosterClassId" required defaultValue={classId || undefined}>
                  {(classes.data?.data ?? []).map((row) => (
                    <option key={row.id} value={row.id}>
                      {row.name}
                    </option>
                  ))}
                </Select>
              </Field>
              <Field label={t("number")}>
                <Input name="number" type="number" min={1} required />
              </Field>
              <Field label={t("fullName")}>
                <Input name="fullName" required />
              </Field>
              <Field label={t("email")}>
                <Input name="email" type="email" />
              </Field>
              <Field label={t("username")}>
                <Input name="username" required minLength={3} />
              </Field>
              <Field label={t("password")}>
                <Input name="password" type="password" required minLength={8} />
              </Field>
            </>
          )}
          <Button type="submit">{t("save")}</Button>
        </form>
      </Modal>
    </div>
  );
}

export function ParentsView() {
  const t = useT();
  const [open, setOpen] = useState<"parent" | "link" | null>(null);
  const parents = useQuery({
    queryKey: ["parents"],
    queryFn: () => api<{ data: Parent[] }>("/api/parents"),
  });
  const students = useQuery({
    queryKey: ["students", "all"],
    queryFn: () => api<{ data: Student[] }>("/api/students"),
  });
  const links = useQuery({
    queryKey: ["links"],
    queryFn: () =>
      api<{ data: { id: number; relation: string; parent: { fullName: string }; student: { fullName: string } }[] }>(
        "/api/student-parents",
      ),
  });
  const saveParent = useSave((body: object) => api("/api/parents", { method: "POST", body: JSON.stringify(body) }), ["parents"]);
  const saveLink = useSave((body: object) => api("/api/student-parents", { method: "POST", body: JSON.stringify(body) }), ["links"]);

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    if (open === "parent") {
      await saveParent.mutateAsync({
        fullName: String(form.get("fullName")),
        phone: String(form.get("phone") ?? "") || null,
        email: String(form.get("email") ?? "") || null,
        address: String(form.get("address") ?? "") || null,
        username: String(form.get("username")),
        password: String(form.get("password")),
      });
    } else {
      await saveLink.mutateAsync({
        studentId: Number(form.get("studentId")),
        parentId: Number(form.get("parentId")),
        relation: String(form.get("relation")),
        isPrimary: form.get("primary") === "on",
      });
    }
    setOpen(null);
  }

  return (
    <div className="grid gap-4">
      <PageTitle title={t("parents")} />
      <Panel title={t("parents")} action={<Button onClick={() => setOpen("parent")}>{t("create")}</Button>}>
        <Table>
          <thead>
            <tr>
              <Th>{t("fullName")}</Th>
              <Th>{t("phone")}</Th>
              <Th>{t("email")}</Th>
              <Th>{t("students")}</Th>
            </tr>
          </thead>
          <tbody>
            {(parents.data?.data ?? []).map((parent) => (
              <tr key={parent.id}>
                <Td>{parent.fullName}</Td>
                <Td>{parent.phone}</Td>
                <Td>{parent.email}</Td>
                <Td>{parent._count?.studentLinks ?? 0}</Td>
              </tr>
            ))}
          </tbody>
        </Table>
        {(parents.data?.data.length ?? 0) === 0 ? <Empty text={t("empty")} /> : null}
      </Panel>
      <Panel title={t("linkParent")} action={<Button onClick={() => setOpen("link")}>{t("create")}</Button>}>
        <ul className="grid gap-1 text-sm">
          {(links.data?.data ?? []).map((link) => (
            <li key={link.id}>
              {link.student.fullName} · {link.parent.fullName} · {link.relation}
            </li>
          ))}
        </ul>
        {(links.data?.data.length ?? 0) === 0 ? <Empty text={t("empty")} /> : null}
      </Panel>
      <Modal open={open != null} title={open === "link" ? t("linkParent") : t("create")} onClose={() => setOpen(null)}>
        <form className="grid gap-3" onSubmit={onSubmit}>
          {open === "parent" ? (
            <>
              <Field label={t("fullName")}><Input name="fullName" required /></Field>
              <Field label={t("phone")}><Input name="phone" /></Field>
              <Field label={t("email")}><Input name="email" type="email" /></Field>
              <Field label={t("address")}><Input name="address" /></Field>
              <Field label={t("username")}><Input name="username" required minLength={3} /></Field>
              <Field label={t("password")}><Input name="password" type="password" required minLength={8} /></Field>
            </>
          ) : (
            <>
              <Field label={t("students")}>
                <Select name="studentId" required>
                  {(students.data?.data ?? []).map((student) => (
                    <option key={student.id} value={student.id}>{student.fullName}</option>
                  ))}
                </Select>
              </Field>
              <Field label={t("parents")}>
                <Select name="parentId" required>
                  {(parents.data?.data ?? []).map((parent) => (
                    <option key={parent.id} value={parent.id}>{parent.fullName}</option>
                  ))}
                </Select>
              </Field>
              <Field label={t("relation")}>
                <Select name="relation" defaultValue="anne">
                  <option value="anne">{t("mother")}</option>
                  <option value="baba">{t("father")}</option>
                  <option value="diger">{t("other")}</option>
                </Select>
              </Field>
              <label className="flex items-center gap-2 text-sm">
                <input name="primary" type="checkbox" /> {t("primary")}
              </label>
            </>
          )}
          <Button type="submit">{t("save")}</Button>
        </form>
      </Modal>
    </div>
  );
}
