const gradePattern = /^(\d+)/;

export function gradeFromCurriculumClassName(name: string): number | null {
  const match = gradePattern.exec(name.trim());
  if (!match) return null;
  const value = Number(match[1]);
  return Number.isFinite(value) ? value : null;
}

export function compareCurriculumClassNames(a: string, b: string): number {
  const ga = gradeFromCurriculumClassName(a);
  const gb = gradeFromCurriculumClassName(b);
  if (ga != null && gb != null && ga !== gb) return ga - gb;
  if (ga != null && gb == null) return -1;
  if (ga == null && gb != null) return 1;
  return a.localeCompare(b, "tr", { numeric: true, sensitivity: "base" });
}

export function sortCurriculumClasses<T extends { name: string }>(rows: T[]): T[] {
  return [...rows].sort((left, right) => compareCurriculumClassNames(left.name, right.name));
}
