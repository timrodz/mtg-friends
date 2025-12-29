import { FORMAT_OPTIONS, STATUS_OPTIONS } from "./constants";

export const tournamentFormat = (value: string) =>
  FORMAT_OPTIONS.find((fo) => fo.value === value)?.label ?? value;

export const tournamentBadge = (value: string) =>
  STATUS_OPTIONS.find((so) => so.value === value)?.label ?? value;
