import dayjs from "dayjs";
import utc from "dayjs/plugin/utc";
import duration from "dayjs/plugin/duration";

dayjs.extend(utc);
dayjs.extend(duration);

/**
 * Formats the remaining time until a round expires.
 * @param insertedAt The ISO string of when the round was created (must be treated as UTC).
 * @param roundLengthSeconds Total duration of the round in seconds.
 * @returns A formatted string: "D:HH:MM:SS", "H:MM:SS", or "MM:SS".
 */
export const formatRemainingTime = (
  insertedAt: string,
  roundLengthSeconds: number = 3600
): string => {
  if (!insertedAt) return "00:00";

  // Ensure parsing as UTC
  const start = dayjs.utc(insertedAt);
  const expiry = start.add(roundLengthSeconds, "second");
  const now = dayjs.utc();

  const diffMs = expiry.diff(now);

  if (diffMs <= 0) {
    return "00:00";
  }

  const dur = dayjs.duration(diffMs);
  const days = Math.floor(dur.asDays());
  const hours = dur.hours();
  const minutes = dur.minutes();
  const seconds = dur.seconds();

  if (days > 0) {
    return `${days}:${hours.toString().padStart(2, "0")}:${minutes
      .toString()
      .padStart(2, "0")}:${seconds.toString().padStart(2, "0")}`;
  }

  if (hours > 0) {
    return `${hours}:${minutes.toString().padStart(2, "0")}:${seconds
      .toString()
      .padStart(2, "0")}`;
  }

  return `${minutes.toString().padStart(2, "0")}:${seconds
    .toString()
    .padStart(2, "0")}`;
};
