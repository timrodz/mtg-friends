import type { components, paths } from "./generated/schema";

// Helpers to tackle the verbose types
type Path<P extends keyof paths> = paths[P];
type Operation<P extends keyof paths, M extends keyof Path<P>> = Path<P>[M];
type Response<
  P extends keyof paths,
  M extends keyof Path<P>,
  S extends number
> =
  // @ts-ignore - The generated types structure is correct but TS struggles with deep indexing here
  Operation<P, M>["responses"][S]["content"]["application/json"];
type ResponseType<T> = { data: T };

// Schemas
type TournamentType = components["schemas"]["Tournament"];
type RoundType = components["schemas"]["Round"];
type ParticipantType = components["schemas"]["Participant"];
type PairingType = components["schemas"]["Pairing"];

export type LoginResponse = Response<"/api/login", "post", 201>;
export type TournamentResponse = ResponseType<
  TournamentType & {
    participants?: Array<ParticipantType>;
    rounds?: Array<RoundType>;
  }
>;
export type TournamentArrayResponse = ResponseType<
  Array<
    TournamentType & {
      participants?: Array<ParticipantType>;
      rounds?: Array<RoundType>;
    }
  >
>;
export type RoundResponse = ResponseType<
  RoundType & { pairings?: Array<PairingType> }
>;
export type ParticipantResponse = ResponseType<ParticipantType>;
export type PairingResponse = ResponseType<PairingType>;

export type GameFormat = TournamentType["format"];
export type GameSubformat = TournamentType["subformat"];
export type TournamentStatus = TournamentType["status"];
