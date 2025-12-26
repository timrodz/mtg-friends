/**
 * Formats the remaining time until a round expires.
 * @param insertedAt The ISO string of when the round was created (UTC).
 * @param roundLengthSeconds Total duration of the round in seconds.
 * @returns A formatted string: "D:HH:MM:SS", "H:MM:SS", or "MM:SS".
 */
export const formatRemainingTime = (
  insertedAt: string,
  roundLengthSeconds: number = 3600
): string => {
  if (!insertedAt) return "00:00";

  // Append 'Z' to ensure it's treated as UTC if missing
  const timestamp = insertedAt.endsWith("Z") ? insertedAt : insertedAt + "Z";
  const start = new Date(timestamp);
  const expiry = new Date(start.getTime() + roundLengthSeconds * 1000);
  const now = new Date();

  const diffMs = expiry.getTime() - now.getTime();
  const diffSeconds = Math.floor(diffMs / 1000);

  if (diffSeconds <= 0) {
    return "00:00";
  }

  const days = Math.floor(diffSeconds / (3600 * 24));
  const hours = Math.floor((diffSeconds % (3600 * 24)) / 3600);
  const minutes = Math.floor((diffSeconds % 3600) / 60);
  const seconds = diffSeconds % 60;

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
