import { describe, it, expect } from "vitest";
import { filterVersions, formatTasksTable, formatVersionsTable } from "../../src/commands/tasks.js";

describe("formatTasksTable", () => {
  it("formats work packages as a table string", () => {
    const tasks = [
      { id: 1234, subject: "Fix login bug", status: "In Progress", priority: "High", assignee: "thuchuynh", lockVersion: 1, createdAt: "2026-03-10T10:00:00Z", updatedAt: "2026-03-12T10:00:00Z", startDate: "2026-03-10", dueDate: "2026-03-15" },
      { id: 1235, subject: "Add dashboard", status: "New", priority: "Normal", assignee: "Unassigned", lockVersion: 2, createdAt: "2026-03-09T10:00:00Z", updatedAt: "2026-03-11T10:00:00Z", startDate: "", dueDate: "" },
    ];
    const output = formatTasksTable(tasks);
    expect(output).toContain("1234");
    expect(output).toContain("Fix login bug");
    expect(output).toContain("In Progress");
    expect(output).toContain("High");
  });
});

describe("filterVersions", () => {
  const versions = [
    { id: 1899, name: "Sprint 26", href: "/api/v3/versions/1899" },
    { id: 1900, name: "Sprint 27", href: "/api/v3/versions/1900" },
    { id: 2101, name: "Release 2026.03", href: "/api/v3/versions/2101" },
  ];

  it("matches versions by name case-insensitively", () => {
    expect(filterVersions(versions, "sprint")).toEqual([
      { id: 1899, name: "Sprint 26", href: "/api/v3/versions/1899" },
      { id: 1900, name: "Sprint 27", href: "/api/v3/versions/1900" },
    ]);
  });

  it("matches versions by id text", () => {
    expect(filterVersions(versions, "2101")).toEqual([
      { id: 2101, name: "Release 2026.03", href: "/api/v3/versions/2101" },
    ]);
  });
});

describe("formatVersionsTable", () => {
  it("formats versions as an id and name table", () => {
    const output = formatVersionsTable([
      { id: 1899, name: "Sprint 26", href: "/api/v3/versions/1899" },
      { id: 2101, name: "Release 2026.03", href: "/api/v3/versions/2101" },
    ]);

    expect(output).toContain("ID");
    expect(output).toContain("Name");
    expect(output).toContain("1899");
    expect(output).toContain("Sprint 26");
    expect(output).toContain("2101");
    expect(output).toContain("Release 2026.03");
  });
});
