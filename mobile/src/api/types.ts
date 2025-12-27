import type { components } from "./generated/schema";

type ResponseType<T> = { data: T };

type _TournamentType = components["schemas"]["Tournament"];
type _RoundType = components["schemas"]["Round"];
type _ParticipantType = components["schemas"]["Participant"];
type _PairingType = components["schemas"]["Pairing"];

// Requests
export type TournamentRequest =
  components["schemas"]["TournamentRequest"]["tournament"];
export type ParticipantRequest =
  components["schemas"]["ParticipantRequest"]["participant"];
export type PairingRequest = components["schemas"]["PairingRequest"]["pairing"];
export type RoundResultsRequest =
  components["schemas"]["RoundResultsRequest"]["results"];

// Responses
export type LoginResponse = components["schemas"]["LoginResponse"];
export type TournamentResponse = ResponseType<
  TournamentType & {
    participants?: Array<_ParticipantType>;
    rounds?: Array<_RoundType>;
  }
>;
export type TournamentArrayResponse = ResponseType<
  Array<
    TournamentType & {
      participants?: Array<_ParticipantType>;
      rounds?: Array<_RoundType>;
    }
  >
>;
export type RoundResponse = ResponseType<
  _RoundType & { pairings?: Array<_PairingType> }
>;
export type ParticipantResponse = ResponseType<_ParticipantType>;
export type PairingResponse = ResponseType<_PairingType>;

// Schemas
export type TournamentType = _TournamentType;
export type RoundType = _RoundType & { pairings?: Array<PairingType> };
export type ParticipantType = _ParticipantType;
export type PairingType = _PairingType & { participant?: ParticipantType };

export type GameFormat = TournamentType["format"];
export type GameSubformat = TournamentType["subformat"];
export type TournamentStatus = TournamentType["status"];
